variable "aws_service_access_principals" {
  description = "Services to enable in the organization."
  type        = list(string)
  default     = ["cloudtrail.amazonaws.com", "config.amazonaws.com", "sso.amazonaws.com"]
}

variable "enabled_policy_types" {
  description = "Policy types to enable."
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICIES"]
}

variable "organizational_units" {
  description = "OU tree definition."
  type = map(object({
    name      = string
    parent_id = optional(string)
    tags      = optional(map(string))
  }))
  default = {}
}

variable "accounts" {
  description = "Member accounts to create."
  type = map(object({
    name      = string
    email     = string
    parent_id = optional(string)
    role_name = optional(string)
    tags      = optional(map(string))
  }))
  default = {}

  validation {
    condition     = length(toset([for a in var.accounts : a.name])) == length([for a in var.accounts : a.name])
    error_message = "Account names must be unique within the organization."
  }

  validation {
    condition = alltrue([
      for a in var.accounts : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", a.email))
    ])
    error_message = "Each account email must be a valid email address."
  }
}

variable "default_account_role_name" {
  description = "Default cross-account role name created in new accounts."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "attached_scps" {
  description = "Map of OU/account keys to lists of SCP policy IDs to attach."
  type        = map(list(string))
  default     = {}
}

variable "tags" {
  description = "Common tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
