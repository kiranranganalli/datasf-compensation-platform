# Infrastructure (Terraform)

This folder defines all Snowflake security objects (roles, grants, masking
policies, row access policies) as code. dbt models live in `../dbt/` and are
deployed by a separate pipeline. **Strict separation of concerns:**

| Layer | Tool | What it owns |
|---|---|---|
| Compute & security | Terraform | Warehouses, databases, roles, grants, masking, RLS |
| Data models | dbt | Tables, views, transformations, tests, docs |

Why split them? Different change cadences, different reviewers, different
blast radius. A typo in a dbt model breaks a dashboard; a typo in Terraform
breaks who-can-see-PII.

## Usage

```bash
# Init (one-time per environment)
terraform init -backend-config="key=compensation-platform/dev.tfstate"

# Plan
terraform plan -var-file=environments/dev.tfvars

# Apply (after PR review)
terraform apply -var-file=environments/dev.tfvars
```

## Layout
infrastructure/
├── providers.tf              # Snowflake provider
├── backend.tf                # Remote state (S3 + DynamoDB lock)
├── variables.tf              # Top-level inputs
├── main.tf                   # Wires modules together
├── environments/             # Per-env tfvars (dev, staging, prod)
└── modules/
├── roles/                # 3 roles + grants
└── security_policies/    # Masking + RLS
## Drift detection

A nightly GitHub Action runs `terraform plan -detailed-exitcode`. Exit code 2
means drift was detected (someone changed something in the Snowflake UI
instead of via code) → posts to #data-eng-alerts in Slack.

See `../.github/workflows/terraform_drift.yml`.
