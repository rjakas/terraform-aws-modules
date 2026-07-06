# service-control-policies

Terraform module for defining reusable AWS Organizations Service Control Policies (SCPs) and exposing their IDs/ARNs for attachment to organizational units or accounts.

The module creates `aws_organizations_policy` resources only; attachments are intentionally left to the [`organizations`](../organizations/) module or to external composition so that both modules remain composable without cyclic dependencies.

## Purpose

Service Control Policies are the top-level guardrails in AWS Organizations. This module implements the foundational deny-list SCPs recommended for production environments:

- **Deny root user actions** — blocks root user API calls except for a configurable allow list.
- **Region lock** — denies actions outside an approved region list.
- **Protect security services** — prevents disabling CloudTrail, GuardDuty, AWS Config, Security Hub, and IAM Access Analyzer.
- **Require encryption** — denies creation of unencrypted EBS volumes, RDS instances, and unencrypted S3 uploads for supported services.

Custom policies can be supplied via the `policies` input, and built-in policies can be overridden by using the same map key.

## Usage

```hcl
module "scps" {
  source = "git::https://github.com/<org>/terraform-aws-modules//modules/service-control-policies?ref=v1.0.0"

  approved_regions = ["us-east-1", "us-west-2"]
  rollout_stage    = "monitoring"

  deny_root_except = [
    "account:CloseAccount",
    "iam:CreateVirtualMFADevice",
  ]

  tags = {
    ManagedBy   = "Terraform"
    Environment = "management"
    Purpose     = "service-control-policies"
  }
}
```

### Custom policy example

```hcl
module "scps" {
  source = "git::https://github.com/<org>/terraform-aws-modules//modules/service-control-policies?ref=v1.0.0"

  policies = {
    "restrict-instance-types" = {
      name        = "RestrictInstanceTypes"
      description = "Limit EC2 instance types to approved families."
      content = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid    = "RestrictInstanceTypes"
          Effect = "Deny"
          Action = "ec2:RunInstances"
          Resource = "arn:aws:ec2:*:*:instance/*"
          Condition = {
            StringNotLike = {
              "ec2:InstanceType" = ["t3.*", "m6.*", "c6.*"]
            }
          }
        }]
      })
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `policies` | Map of SCP definitions. `content` must be a valid JSON policy document. | `map(object({ name = string, description = optional(string), type = optional(string), content = string, tags = optional(map(string)) }))` | `{}` | no |
| `approved_regions` | Regions allowed by the region-lock SCP template. When empty, the region-lock SCP is not created. | `list(string)` | `[]` | no |
| `deny_root_except` | List of root actions to allow as exceptions in the deny-root SCP. | `list(string)` | `[]` | no |
| `protected_services` | Services protected by the security-services SCP template. | `list(string)` | `["cloudtrail", "guardduty", "config", "securityhub", "access-analyzer"]` | no |
| `required_encryption_services` | Services covered by the encryption SCP template. Only services with known SCP condition keys are rendered. | `list(string)` | `["s3", "ebs", "rds", "sns"]` | no |
| `rollout_stage` | Rollout stage applied as the `RolloutStage` tag (`monitoring`, `pilot`, or `enforced`). | `string` | `"monitoring"` | no |
| `tags` | Tags applied to all taggable resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `policy_ids` | Map of policy names to AWS Organizations policy IDs. |
| `policy_arns` | Map of policy names to AWS Organizations policy ARNs. |
