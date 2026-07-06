variable "name" {
  description = "CloudTrail name."
  type        = string
}

variable "is_organization_trail" {
  description = "Create an organization trail."
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "Log events from all regions."
  type        = bool
  default     = true
}

variable "include_global_service_events" {
  description = "Log global service events."
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Enable digest file validation."
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Destination S3 bucket name. Module creates bucket if create_s3_bucket = true."
  type        = string
}

variable "create_s3_bucket" {
  description = "Whether to create the S3 bucket."
  type        = bool
  default     = true
}

variable "s3_key_prefix" {
  description = "S3 key prefix for logs."
  type        = string
  default     = "cloudtrail"
}

variable "kms_key_id" {
  description = "KMS key ARN for log encryption. Creates one if null and create_kms_key = true."
  type        = string
  default     = null
}

variable "create_kms_key" {
  description = "Whether to create a KMS key."
  type        = bool
  default     = true
}

variable "cloud_watch_logs_group_arn" {
  description = "Optional CloudWatch Logs group ARN."
  type        = string
  default     = null
}

variable "cloud_watch_logs_role_arn" {
  description = "IAM role ARN for CloudWatch Logs delivery."
  type        = string
  default     = null
}

variable "event_selectors" {
  description = "Data event selectors."
  type        = list(any)
  default     = []
}

variable "insight_selectors" {
  description = "Insight event selectors."
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
