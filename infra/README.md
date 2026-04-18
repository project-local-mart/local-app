# Localmart Infrastructure

Terraform infrastructure for Localmart on AWS. Secrets managed by HashiCorp Vault.

## Directory structure

```
infra/
├── bootstrap/          # Run once by a human — creates S3 state bucket, DynamoDB lock table,
│                       # base IAM roles, CloudTrail, and GitHub OIDC provider. Uses local state.
└── terraform/
    ├── modules/        # Reusable modules (networking, vault, database, …)
    └── environments/   # Per-environment root configurations (dev, staging, prod)
        ├── dev/
        ├── staging/
        └── prod/
```

## Prerequisites

- AWS CLI configured with credentials that have `AdministratorAccess` (bootstrap only)
- Terraform >= 1.6.0
- A registered domain delegated to Route 53 (for ACM cert validation)

## First-time setup

### 1. Bootstrap (run once)

The bootstrap creates the remote state backend. It uses local state and is run exactly once.

```bash
cd infra/bootstrap

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set state_bucket_name, github_org, github_repo, etc.

terraform init
terraform plan
terraform apply
```

Note the outputs — you'll need `state_bucket_name` and `lock_table_name` for the environment backends.

### 2. Deploy an environment

```bash
cd infra/terraform/environments/dev

# Edit backend.tf with the bucket/table from bootstrap outputs
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

## Module dependency order

```
networking → dns-certs + ecs-cluster (parallel)
                    ↓
           vault + database (parallel, after networking)
                    ↓
                   iam (after vault + database)
```

Terraform resolves the graph automatically. All modules are called from a single
`terraform apply` in the environment root — no manual ordering needed.

## Vault initial setup

After the Vault ECS service is running, initialize and unseal:

```bash
# Port-forward to the Vault ALB (or use a bastion/SSM session)
vault operator init -key-shares=1 -key-threshold=1

# Save the unseal key and root token in a secure location (1Password, etc.)
# With KMS auto-unseal configured, the unseal key is only needed for disaster recovery.
```

See the Vault runbook in `docs/runbooks/vault-init.md` (to be written).

## Adding a new environment

1. Copy `environments/dev/` to `environments/{name}/`
2. Update `backend.tf` (change the state key)
3. Update `terraform.tfvars` with environment-specific values
4. Run `terraform init && terraform apply`

## Tagging

Every resource carries these mandatory tags:

| Tag           | Value                          |
|---------------|--------------------------------|
| `Project`     | `localmart`                    |
| `Environment` | `dev` / `staging` / `prod`     |
| `ManagedBy`   | `terraform`                    |
| `Module`      | module name (`networking`, …)  |
| `Owner`       | `platform`                     |
| `CostCenter`  | `engineering-{environment}`    |
