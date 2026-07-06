# cloudtrail

Terraform module for configuring AWS CloudTrail with centralized S3 delivery,
KMS encryption, and optional CloudWatch Logs streaming.

This module creates an organization or account-level CloudTrail trail, the
destination S3 bucket and bucket policy, a customer-managed KMS key for log
encryption, and a CloudWatch Logs log group when one is not supplied.

## Usage

```hcl
module "cloudtrail" {
  source = "git::https://github.com/<org>/terraform-aws-modules//modules/cloudtrail?ref=v1.0.0"

  name                  = "organization-trail"
  is_organization_trail = true
  s3_bucket_name        = "mycompany-cloudtrail-logs"
  tags = {
    ManagedBy   = "Terraform"
    Environment = "management"
    Purpose     = "audit-logging"
  }

  depends_on = [module.organizations]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| name | CloudTrail name. | `string` | n/a | yes |
| is_organization_trail | Create an organization trail. | `bool` | `true` | no |
| is_multi_region_trail | Log events from all regions. | `bool` | `true` | no |
| include_global_service_events | Log global service events. | `bool` | `true` | no |
| enable_log_file_validation | Enable digest file validation. | `bool` | `true` | no |
| s3_bucket_name | Destination S3 bucket name. Module creates bucket if `create_s3_bucket = true`. | `string` | n/a | yes |
| create_s3_bucket | Whether to create the S3 bucket. | `bool` | `true` | no |
| s3_key_prefix | S3 key prefix for logs. | `string` | `"cloudtrail"` | no |
| kms_key_id | KMS key ARN for log encryption. Creates one if `null` and `create_kms_key = true`. | `string` | `null` | no |
| create_kms_key | Whether to create a KMS key. | `bool` | `true` | no |
| cloud_watch_logs_group_arn | Optional CloudWatch Logs group ARN. | `string` | `null` | no |
| cloud_watch_logs_role_arn | IAM role ARN for CloudWatch Logs delivery. | `string` | `null` | no |
| event_selectors | Data event selectors. | `list(any)` | `[]` | no |
| insight_selectors | Insight event selectors. | `list(any)` | `[]` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| trail_arn | CloudTrail ARN. |
| trail_name | CloudTrail name. |
| s3_bucket_arn | ARN of the log bucket. |
| kms_key_arn | ARN of the KMS key. |
