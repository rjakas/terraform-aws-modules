variable "identity_store_id" {
  description = "AWS Identity Center identity store ID."
  type        = string
}

variable "permission_sets" {
  description = "Permission set definitions."
  type = map(object({
    name                      = string
    description               = optional(string)
    session_duration          = optional(string)
    managed_policy_arns       = optional(list(string))
    inline_policy             = optional(string)
    customer_managed_policies = optional(list(string))
    tags                      = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for ps in var.permission_sets : ps.session_duration == null || can(regex(
        "^P(\\d+Y)?(\\d+M)?(\\d+W)?(\\d+D)?(T(\\d+H)?(\\d+M)?(\\d+(\\.\\d+)?S)?)?$",
        ps.session_duration
      ))
    ])
    error_message = "All session_duration values must be valid ISO 8601 durations, e.g. PT2H."
  }
}

variable "groups" {
  description = "Identity Center groups to create."
  type = map(object({
    display_name = string
    description  = optional(string)
  }))
  default = {}
}

variable "account_assignments" {
  description = "Matrix of group-to-permission-set-to-account assignments."
  type = list(object({
    group_id            = string
    permission_set_name = string
    account_ids         = list(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for assignment in var.account_assignments : length(assignment.account_ids) > 0
    ])
    error_message = "Each account assignment must include at least one account ID."
  }
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
