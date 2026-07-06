# organizations

Terraform module for establishing an AWS Organizations structure, creating member accounts, and attaching Service Control Policies (SCPs).

## Purpose

This module creates and manages:

- An AWS Organization with configurable service access principals and enabled policy types.
- Organizational Units (OUs) nested under the organization root or a parent OU.
- Member AWS accounts with consistent IAM cross-account roles.
- SCP attachments to OUs or accounts by reference to module-local keys.

## Usage

```hcl
module "organizations" {
  source = "git::https://github.com/<org>/terraform-aws-modules.git//modules/organizations?ref=v1.0.0"

  organizational_units = {
    security = { name = "Security" }
    workloads = { name = "Workloads" }
  }

  accounts = {
    log_archive = {
      name  = "log-archive"
      email = "aws+log-archive@company.com"
    }
  }

  attached_scps = {
    security = ["p-12345678"]
  }

  tags = {
    ManagedBy   = "Terraform"
    Environment = "management"
    Purpose     = "landing-zone"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_service_access_principals` | Services to enable in the organization. | `list(string)` | `["cloudtrail.amazonaws.com", "config.amazonaws.com", "sso.amazonaws.com"]` | no |
| `enabled_policy_types` | Policy types to enable. | `list(string)` | `["SERVICE_CONTROL_POLICIES"]` | no |
| `organizational_units` | OU tree definition. | `map(object({ name = string, parent_id = optional(string), tags = optional(map(string)) }))` | `{}` | no |
| `accounts` | Member accounts to create. | `map(object({ name = string, email = string, parent_id = optional(string), role_name = optional(string), tags = optional(map(string)) }))` | `{}` | no |
| `default_account_role_name` | Default cross-account role name created in new accounts. | `string` | `"OrganizationAccountAccessRole"` | no |
| `attached_scps` | Map of OU/account keys to lists of SCP policy IDs to attach. | `map(list(string))` | `{}` | no |
| `tags` | Common tags applied to all taggable resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `organization_id` | AWS Organization ID. |
| `organization_arn` | AWS Organization ARN. |
| `root_id` | Root OU ID. |
| `organizational_unit_ids` | Map of OU names to IDs. |
| `account_ids` | Map of account names to IDs. |
