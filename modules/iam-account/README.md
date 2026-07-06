# iam-account

Terraform module that applies once per AWS account immediately after account creation. It configures the account alias, account password policy, and account-level hardening settings.

## Usage

```hcl
module "iam_account" {
  source = "git::https://github.com/<org>/terraform-aws-modules//modules/iam-account?ref=v1.0.0"

  account_alias = "mycompany-management"

  tags = {
    ManagedBy   = "Terraform"
    Environment = "management"
    Purpose     = "account-hardening"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `account_alias` | Human-readable alias for the AWS account. | `string` | n/a | yes |
| `password_minimum_password_length` | Minimum password length. | `number` | `24` | no |
| `password_require_uppercase` | Require uppercase characters. | `bool` | `true` | no |
| `password_require_lowercase` | Require lowercase characters. | `bool` | `true` | no |
| `password_require_numbers` | Require numeric characters. | `bool` | `true` | no |
| `password_require_symbols` | Require symbol characters. | `bool` | `true` | no |
| `password_allow_users_to_change_password` | Allow IAM users to change their own password. | `bool` | `true` | no |
| `password_max_password_age` | Maximum password age in days. | `number` | `90` | no |
| `password_password_reuse_prevention` | Number of previous passwords to prevent reuse. | `number` | `3` | no |
| `password_hard_expiry` | Prevents IAM users from setting a new password after expiration. | `bool` | `false` | no |
| `tags` | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `account_alias` | The configured AWS account alias. |
| `password_policy_id` | ID of the account password policy. |
