output "policy_ids" {
  description = "Map of policy names to AWS Organizations policy IDs."
  value       = { for name, policy in aws_organizations_policy.this : name => policy.id }
}

output "policy_arns" {
  description = "Map of policy names to AWS Organizations policy ARNs."
  value       = { for name, policy in aws_organizations_policy.this : name => policy.arn }
}
