terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  # This official Coder image supplies Node.js and rootless Docker support for
  # the outer workspace. The repository's .devcontainer definition supplies
  # the actual Localmart development environment as a nested container.
  workspace_image = "codercom/enterprise-node:ubuntu"
}

variable "docker_socket" {
  default     = ""
  description = "Optional Docker socket URI. Leave empty to use DOCKER_HOST or the default socket."
  type        = string
}

data "coder_parameter" "repo_url" {
  type         = "string"
  name         = "repo_url"
  display_name = "Git repository"
  description  = "Repository containing Localmart's .devcontainer definition."
  default      = "https://github.com/project-local-mart/local-app.git"
  mutable      = true
}

data "coder_parameter" "local_repo_path" {
  type         = "string"
  name         = "local_repo_path"
  display_name = "Local repository path"
  description  = "Optional absolute host path to bind into the workspace instead of cloning Git. Useful for a local Coder deployment with uncommitted work."
  default      = ""
  mutable      = true
}

provider "docker" {
  host = var.docker_socket != "" ? var.docker_socket : null
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch            = data.coder_provisioner.me.arch
  os              = "linux"
  startup_script  = file("${path.module}/scripts/init-docker-in-docker.sh")
  shutdown_script = <<-EOT
    set -e
    sudo pkill dockerd || true
  EOT

  env = {
    LOCAL_REPO_PATH     = data.coder_parameter.local_repo_path.value
    REPO_URL            = data.coder_parameter.repo_url.value
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
  }

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "2_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }
}

module "devcontainers-cli" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/devcontainers-cli/coder"
  version  = "~> 1.0"
  agent_id = coder_agent.main.id
}

resource "coder_devcontainer" "repo" {
  count            = data.coder_workspace.me.start_count
  agent_id         = coder_agent.main.id
  workspace_folder = "/home/coder/local-app"

  depends_on = [
    module.devcontainers-cli,
  ]
}

resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace.me.id}-home"

  lifecycle {
    ignore_changes = all
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
}

resource "docker_volume" "docker" {
  name = "coder-${data.coder_workspace.me.id}-docker"

  lifecycle {
    ignore_changes = all
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
}

resource "docker_container" "workspace" {
  count      = data.coder_workspace.me.start_count
  image      = local.workspace_image
  privileged = true
  name       = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname   = data.coder_workspace.me.name
  command = [
    "sh",
    "-c",
    replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal"),
  ]
  env = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home.name
    read_only      = false
  }

  dynamic "volumes" {
    for_each = data.coder_parameter.local_repo_path.value == "" ? [] : [data.coder_parameter.local_repo_path.value]

    content {
      container_path = "/home/coder/local-app"
      host_path      = volumes.value
      read_only      = false
    }
  }

  volumes {
    container_path = "/var/lib/docker"
    volume_name    = docker_volume.docker.name
    read_only      = false
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}
