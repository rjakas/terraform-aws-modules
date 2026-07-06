variable "policies" {
  description = "Map of SCP definitions. `content` is a JSON policy document. Optional `tags` are merged with the common tags."
  type = map(object({
    name        = string
    description = optional(string)
    type        = optional(string)
    content     = string
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.policies : can(jsondecode(v.content))])
    error_message = "Each policy content value must be valid JSON."
  }
}

variable "approved_regions" {
  description = "Regions allowed by the region-lock SCP template. When empty, the region-lock SCP is not created."
  type        = list(string)
  default     = []
}

variable "deny_root_except" {
  description = "List of root actions to allow as exceptions in the deny-root SCP."
  type        = list(string)
  default     = []
}

variable "protected_services" {
  description = "Services protected by the security-services SCP template."
  type        = list(string)
  default     = ["cloudtrail", "guardduty", "config", "securityhub", "access-analyzer"]
}

variable "required_encryption_services" {
  description = "Services covered by the encryption SCP template."
  type        = list(string)
  default     = ["s3", "ebs", "rds", "sns"]
}

variable "rollout_stage" {
  description = "Rollout stage applied as the `RolloutStage` tag and used to track SCP lifecycle."
  type        = string
  default     = "monitoring"

  validation {
    condition     = contains(["monitoring", "pilot", "enforced"], var.rollout_stage)
    error_message = "rollout_stage must be one of: monitoring, pilot, enforced."
  }
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
