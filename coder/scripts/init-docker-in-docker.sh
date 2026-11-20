#!/bin/sh
set -eu

if [ ! -f "$HOME/.localmart_workspace_initialized" ]; then
  cp -rT /etc/skel "$HOME"
  touch "$HOME/.localmart_workspace_initialized"
fi

start_docker() {
  if docker info >/dev/null 2>&1; then
    return
  fi

  # The image's SysV wrapper attempts to raise the file-descriptor hard limit,
  # which Docker Desktop's ARM64 VM rejects. Starting dockerd directly avoids
  # that wrapper while preserving the same daemon configuration.
  sudo nohup dockerd --host=unix:///var/run/docker.sock >/tmp/dockerd.log 2>&1 &

  attempts=0
  until docker info >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 60 ]; then
      cat /tmp/dockerd.log >&2
      echo "Docker did not become ready within 60 seconds." >&2
      return 1
    fi
    sleep 1
  done
}

ensure_nat_rule() {
  if ! sudo iptables -t nat -C "$@" 2>/dev/null; then
    sudo iptables -t nat -A "$@"
  fi
}

# Coder rewrites a loopback access URL to host.docker.internal for the outer
# workspace. Nested Dev Containers resolve that name to the outer daemon's host
# gateway, so forward the Coder port from that gateway to Docker Desktop.
if [ "${CODER_AGENT_URL#*host.docker.internal}" != "$CODER_AGENT_URL" ]; then
  echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null
  ensure_nat_rule POSTROUTING -j MASQUERADE

  host_ip=$(getent ahostsv4 host.docker.internal | awk 'NR == 1 { print $1 }')
  if [ -z "$host_ip" ]; then
    echo "Could not resolve an IPv4 address for host.docker.internal." >&2
    exit 1
  fi

  port="${CODER_AGENT_URL##*:}"
  port="${port%%/*}"

  case "$port" in
    *[!0-9]*|'')
      ensure_nat_rule PREROUTING -p tcp --dport 80 -j DNAT --to-destination "$host_ip:80"
      ensure_nat_rule PREROUTING -p tcp --dport 443 -j DNAT --to-destination "$host_ip:443"
      ;;
    *)
      ensure_nat_rule PREROUTING -p tcp --dport "$port" -j DNAT --to-destination "$host_ip:$port"
      ;;
  esac
fi

start_docker

# Clone during the agent startup script so the repository and Docker daemon
# are both ready before the coder_devcontainer resource begins its work.
repo_dir="$HOME/local-app"
if [ -n "$LOCAL_REPO_PATH" ]; then
  if [ ! -f "$repo_dir/.devcontainer/devcontainer.json" ]; then
    echo "The bound local repository does not contain .devcontainer/devcontainer.json." >&2
    exit 1
  fi
elif [ ! -d "$repo_dir/.git" ]; then
  if [ -e "$repo_dir" ]; then
    echo "$repo_dir exists but is not a Git repository; refusing to replace it." >&2
    exit 1
  fi
  git clone -- "$REPO_URL" "$repo_dir"
fi
