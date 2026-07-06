output "organization_id" {
  description = "AWS Organization ID."
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "AWS Organization ARN."
  value       = aws_organizations_organization.this.arn
}

output "root_id" {
  description = "Root OU ID."
  value       = aws_organizations_organization.this.roots[0].id
}

output "organizational_unit_ids" {
  description = "Map of OU names to IDs."
  value = {
    for key, ou in aws_organizations_organizational_unit.this : key => ou.id
  }
}

output "account_ids" {
  description = "Map of account names to IDs."
  value = {
    for key, account in aws_organizations_account.this : key => account.id
  }
}
