# Terraform AWS IAM Module Collection

Reusable, composable Terraform modules for production-ready AWS IAM and identity infrastructure. Each module can be imported independently into other repositories or projects.

## Overview

This collection implements the architecture described in [docs/aws-iam-strategy.md](docs/aws-iam-strategy.md). The modules follow these principles:

- No long-lived credentials: all authentication uses OIDC federation, IAM Identity Center, or cross-account role assumption.
- Least privilege: roles, policies, and SCPs are scoped to the minimum required access.
- Importable by source path: each module lives under `modules/<name>` and can be consumed via a Terraform module source URL.
- Consistent conventions: every module accepts a `tags` map, uses AWS provider `>= 5.0`, and exposes stable ARNs/IDs as outputs.

## Modules

| Module | Purpose | Source path example |
|---|---|---|
| [iam-account](modules/iam-account) | Account alias and password policy hardening | `git::https://github.com/rjakas/terraform-aws-modules//modules/iam-account?ref=v1.0.0` |
| [iam-oidc-provider](modules/iam-oidc-provider) | OIDC identity providers (e.g., GitHub Actions) | `git::https://github.com/rjakas/terraform-aws-modules//modules/iam-oidc-provider?ref=v1.0.0` |
| [iam-role](modules/iam-role) | Assumable roles with OIDC, cross-account, or MFA trust policies | `git::https://github.com/rjakas/terraform-aws-modules//modules/iam-role?ref=v1.0.0` |
| [organizations](modules/organizations) | AWS Organizations, OUs, accounts, and SCP attachments | `git::https://github.com/rjakas/terraform-aws-modules//modules/organizations?ref=v1.0.0` |
| [cloudtrail](modules/cloudtrail) | Organization-wide audit logging and log encryption | `git::https://github.com/rjakas/terraform-aws-modules//modules/cloudtrail?ref=v1.0.0` |
| [iam-identity-center](modules/iam-identity-center) | SSO permission sets, groups, and account assignments | `git::https://github.com/rjakas/terraform-aws-modules//modules/iam-identity-center?ref=v1.0.0` |
| [service-control-policies](modules/service-control-policies) | Reusable SCP definitions and guardrails | `git::https://github.com/rjakas/terraform-aws-modules//modules/service-control-policies?ref=v1.0.0` |

## Usage

```hcl
module "github_oidc" {
  source = "git::https://github.com/rjakas/terraform-aws-modules//modules/iam-oidc-provider?ref=v1.0.0"

  create_github_provider = true
  tags = {
    ManagedBy   = "Terraform"
    Environment = "management"
  }
}

module "deploy_role" {
  source = "git::https://github.com/rjakas/terraform-aws-modules//modules/iam-role?ref=v1.0.0"

  name                     = "GitHubActionsTerraformDeploy"
  github_oidc_provider_arn = module.github_oidc.arn
  oidc_subjects = [
    "repo:myorg/infrastructure:ref:refs/heads/main"
  ]
  oidc_conditions = [
    {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:environment"
      values   = ["production"]
    }
  ]
  max_session_duration = 3600
  tags                 = module.github_oidc.tags
}
```

See each module's `README.md` for complete inputs, outputs, and examples.

## Requirements

- Terraform `>= 1.5.0`
- AWS Provider `>= 5.0`
- For `iam-role`: `hashicorp/random` `>= 3.0` when cross-account trusts without external IDs are used

## Repository Layout

```
.
├── docs/
│   ├── aws-iam-strategy.md        # Architecture guidance
├── modules/
│   ├── iam-account/
│   ├── iam-oidc-provider/
│   ├── iam-role/
│   ├── organizations/
│   ├── cloudtrail/
│   ├── iam-identity-center/
│   └── service-control-policies/
└── README.md
```

## Validation

Run these commands from the repository root:

```bash
terraform fmt -recursive -check
for d in modules/*/; do
  (cd "$d" && terraform init -backend=false -input=false && terraform validate)
done
```

## Design References

- [docs/aws-iam-strategy.md](docs/aws-iam-strategy.md) — complete architecture and security guidance