# iam-role

Terraform module for creating assumable IAM roles with carefully scoped trust
policies for CI/CD (OIDC) and human/cross-account access.

## Usage

```hcl
module "github_actions_deploy_role" {
  source = "git::https://github.com/<org>/terraform-aws-modules//modules/iam-role?ref=v1.0.0"

  name = "GitHubActionsTerraformDeploy"

  github_oidc_provider_arn = module.iam_oidc_provider.arn
  oidc_subjects = [
    "repo:myorganization/infrastructure:ref:refs/heads/main"
  ]
  oidc_conditions = [
    {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:environment"
      values   = ["production"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
    Purpose     = "github-actions-cicd"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | IAM role name. | `string` | n/a | yes |
| description | Role description. | `string` | `""` | no |
| path | IAM role path. | `string` | `"/"` | no |
| max_session_duration | Maximum session duration in seconds. | `number` | `3600` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |
| managed_policy_arns | Managed policy ARNs to attach. | `list(string)` | `[]` | no |
| inline_policies | Map of inline policy names to JSON policy documents. | `map(string)` | `{}` | no |
| assume_role_policy | Complete custom trust policy JSON. If provided, other trust inputs are ignored. | `string` | `null` | no |
| trusted_oidc_providers | OIDC trust configurations. | `map(object({ provider_arn: string, conditions: list(object({ test: string, variable: string, values: list(string) })) }))` | `{}` | no |
| oidc_subjects | Shortcut for GitHub OIDC `sub` conditions. | `list(string)` | `[]` | no |
| oidc_audience | OIDC audience condition. | `string` | `"sts.amazonaws.com"` | no |
| oidc_conditions | Additional OIDC conditions (e.g. environment, workflow). | `list(object({ test: string, variable: string, values: list(string) }))` | `[]` | no |
| trusted_accounts | Cross-account AWS principal trusts with optional external ID. | `list(object({ account_id: string, external_id: optional(string) }))` | `[]` | no |
| require_mfa | Add `aws:MultiFactorAuthPresent` condition for AWS principal trust. | `bool` | `false` | no |
| github_oidc_provider_arn | ARN of the GitHub OIDC provider. Required when `oidc_subjects` or `oidc_conditions` are used. | `string` | `null` | no |
| store_external_ids_in_secrets_manager | Store generated external IDs in AWS Secrets Manager. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | IAM role ARN. |
| name | IAM role name. |
| assume_role_policy | Rendered trust policy JSON. |
| external_ids | Map of account IDs to generated external IDs. |
