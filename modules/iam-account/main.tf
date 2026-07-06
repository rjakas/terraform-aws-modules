data "aws_iam_account_alias" "current" {}

resource "aws_iam_account_alias" "this" {
  account_alias = var.account_alias
}

resource "aws_iam_account_password_policy" "this" {
  minimum_password_length        = var.password_minimum_password_length
  require_uppercase_characters   = var.password_require_uppercase
  require_lowercase_characters   = var.password_require_lowercase
  require_numbers                = var.password_require_numbers
  require_symbols                = var.password_require_symbols
  allow_users_to_change_password = var.password_allow_users_to_change_password
  max_password_age               = var.password_max_password_age
  password_reuse_prevention      = var.password_password_reuse_prevention
  hard_expiry                    = var.password_hard_expiry
}
