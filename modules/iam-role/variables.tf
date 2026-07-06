variable "name" {
  description = "IAM role name."
  type        = string
}

variable "description" {
  description = "Role description."
  type        = string
  default     = ""
}

variable "path" {
  description = "IAM role path."
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 900 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 900 and 43200 seconds."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "managed_policy_arns" {
  description = "Managed policy ARNs to attach."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy names to JSON policy documents."
  type        = map(string)
  default     = {}
}

variable "assume_role_policy" {
  description = "Complete custom trust policy JSON. If provided, other trust inputs are ignored."
  type        = string
  default     = null
}

variable "trusted_oidc_providers" {
  description = "OIDC trust configurations."
  type = map(object({
    provider_arn = string
    conditions = list(object({
      test     = string
      variable = string
      values   = list(string)
    }))
  }))
  default = {}
}

variable "oidc_subjects" {
  description = "Shortcut for GitHub OIDC `sub` conditions."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for sub in var.oidc_subjects : can(regex("^repo:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+:ref:refs/heads/.+$", sub)) || can(regex("^repo:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+:pull_request$", sub))
    ])
    error_message = "Each oidc_subjects entry must match repo:<owner>/<repo>:ref:refs/heads/<branch> or repo:<owner>/<repo>:pull_request."
  }
}

variable "oidc_audience" {
  description = "OIDC audience condition."
  type        = string
  default     = "sts.amazonaws.com"
}

variable "oidc_conditions" {
  description = "Additional OIDC conditions (e.g. environment, workflow)."
  type = list(object({
    test     = string
    variable = string
    values   = list(string)
  }))
  default = []
}

variable "trusted_accounts" {
  description = "Cross-account AWS principal trusts with optional external ID."
  type = list(object({
    account_id  = string
    external_id = optional(string)
  }))
  default = []
}

variable "require_mfa" {
  description = "Add `aws:MultiFactorAuthPresent` condition for AWS principal trust."
  type        = bool
  default     = false
}

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider. Required when oidc_subjects or oidc_conditions are used."
  type        = string
  default     = null
}

variable "store_external_ids_in_secrets_manager" {
  description = "Store generated external IDs in AWS Secrets Manager."
  type        = bool
  default     = false
}
