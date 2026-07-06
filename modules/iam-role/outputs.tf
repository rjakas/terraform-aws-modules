output "arn" {
  description = "IAM role ARN."
  value       = aws_iam_role.this.arn
}

output "name" {
  description = "IAM role name."
  value       = aws_iam_role.this.name
}

output "assume_role_policy" {
  description = "Rendered trust policy JSON."
  value       = aws_iam_role.this.assume_role_policy
}

output "external_ids" {
  description = "Map of account IDs to generated external IDs."
  value = {
    for acc in var.trusted_accounts : acc.account_id => (
      acc.external_id != null ? acc.external_id : random_id.external_id[acc.account_id].hex
    )
  }
  sensitive = true
}
