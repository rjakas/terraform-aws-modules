variable "account_alias" {
  description = "Human-readable alias for the AWS account."
  type        = string

  validation {
    condition     = length(var.account_alias) >= 3 && length(var.account_alias) <= 63
    error_message = "The account alias must be between 3 and 63 characters long."
  }

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{1,61}[a-z0-9])?$", var.account_alias))
    error_message = "The account alias must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }
}

variable "password_minimum_password_length" {
  description = "Minimum password length."
  type        = number
  default     = 24
}

variable "password_require_uppercase" {
  description = "Require uppercase characters."
  type        = bool
  default     = true
}

variable "password_require_lowercase" {
  description = "Require lowercase characters."
  type        = bool
  default     = true
}

variable "password_require_numbers" {
  description = "Require numeric characters."
  type        = bool
  default     = true
}

variable "password_require_symbols" {
  description = "Require symbol characters."
  type        = bool
  default     = true
}

variable "password_allow_users_to_change_password" {
  description = "Allow IAM users to change their own password."
  type        = bool
  default     = true
}

variable "password_max_password_age" {
  description = "Maximum password age in days."
  type        = number
  default     = 90
}

variable "password_password_reuse_prevention" {
  description = "Number of previous passwords to prevent reuse."
  type        = number
  default     = 3
}

variable "password_hard_expiry" {
  description = "Prevents IAM users from setting a new password after expiration."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
