# iam-identity-center

Terraform module for configuring AWS IAM Identity Center (formerly AWS SSO).

This module replaces long-lived IAM users with centralized single sign-on. It creates Identity Center groups, permission sets, and group-to-permission-set-to-account assignments, enabling a matrix-style access model where groups receive different privileges in different accounts.

## Usage

```hcl
module "iam_identity_center" {
  source = "git::https://github.com/<org>/terraform-aws-modules//modules/iam-identity-center?ref=v1.0.0"

  identity_store_id = "d-1234567890"

  groups = {
    platform_engineers = {
      display_name = "PlatformEngineers"
      description  = "Platform engineering team"
    }
    security_auditors = {
      display_name = "SecurityAuditors"
      description  = "Security audit team"
    }
  }

  permission_sets = {
    admin = {
      name                = "AdministratorAccess"
      description         = "Full admin access"
      session_duration    = "PT2H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    read_only = {
      name                = "ReadOnlyAccess"
      description         = "Read-only access"
      session_duration    = "PT4H"
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  account_assignments = [
    {
      group_id            = module.iam_identity_center.group_ids["PlatformEngineers"]
      permission_set_name = "AdministratorAccess"
      account_ids         = ["123456789012"]
    },
    {
      group_id            = module.iam_identity_center.group_ids["SecurityAuditors"]
      permission_set_name = "ReadOnlyAccess"
      account_ids         = ["123456789012", "210987654321"]
    }
  ]

  tags = {
    ManagedBy   = "Terraform"
    Environment = "management"
    Purpose     = "iam-identity-center"
  }
}
```

> **Note:** IAM Identity Center must already be enabled in the AWS account. The module reads the existing SSO instance via the `aws_ssoadmin_instances` data source.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `identity_store_id` | AWS Identity Center identity store ID. | `string` | n/a | yes |
| `permission_sets` | Permission set definitions. | `map(object({...}))` | `{}` | no |
| `groups` | Identity Center groups to create. | `map(object({...}))` | `{}` | no |
| `account_assignments` | Matrix of group-to-permission-set-to-account assignments. | `list(object({...}))` | `[]` | no |
| `tags` | Tags applied to all taggable resources. | `map(string)` | `{}` | no |

### `permission_sets` object

| Name | Description | Type |
|---|---|---|
| `name` | Name of the permission set. | `string` |
| `description` | Description of the permission set. | `optional(string)` |
| `session_duration` | ISO 8601 session duration, e.g. `PT2H`. | `optional(string)` |
| `managed_policy_arns` | ARNs of AWS managed policies to attach. | `optional(list(string))` |
| `inline_policy` | JSON inline policy document. | `optional(string)` |
| `customer_managed_policies` | Names of customer managed IAM policies to attach. | `optional(list(string))` |
| `tags` | Additional tags for the permission set. | `optional(map(string))` |

### `groups` object

| Name | Description | Type |
|---|---|---|
| `display_name` | Display name of the Identity Center group. | `string` |
| `description` | Description of the group. | `optional(string)` |

### `account_assignments` object

| Name | Description | Type |
|---|---|---|
| `group_id` | Identity store group ID. | `string` |
| `permission_set_name` | Name of an existing permission set. | `string` |
| `account_ids` | List of AWS account IDs to assign. | `list(string)` |

## Outputs

| Name | Description |
|---|---|
| `permission_set_arns` | Map of permission set names to ARNs. |
| `permission_set_ids` | Map of permission set names to IDs. |
| `group_ids` | Map of group display names to identity store IDs. |
