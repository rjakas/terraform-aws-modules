output "account_alias" {
  description = "The configured AWS account alias."
  value       = aws_iam_account_alias.this.account_alias
}

output "password_policy_id" {
  description = "ID of the account password policy."
  value       = aws_iam_account_password_policy.this.id
}
