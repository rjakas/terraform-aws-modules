variable "url" {
  description = "OIDC provider URL, e.g. `https://token.actions.githubusercontent.com`."
  type        = string
  default     = ""

  validation {
    condition     = var.create_github_provider || length(var.url) > 0
    error_message = "A valid OIDC provider URL is required unless create_github_provider is set to true."
  }

  validation {
    condition     = !var.create_github_provider || var.url == "" || var.url == "https://token.actions.githubusercontent.com"
    error_message = "When create_github_provider is true, url must be empty or set to https://token.actions.githubusercontent.com."
  }
}

variable "client_id_list" {
  description = "Client IDs (audiences) for the provider."
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "thumbprint_list" {
  description = "Certificate thumbprints. Required for non-GitHub providers when AWS cannot auto-discover the thumbprint."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for thumbprint in var.thumbprint_list :
      length(thumbprint) == 40 && can(regex("^[0-9a-fA-F]{40}$", thumbprint))
    ])
    error_message = "Each thumbprint must be a 40-character hexadecimal string."
  }
}

variable "create_github_provider" {
  description = "Convenience flag to create the GitHub OIDC provider with the known URL and audience."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
