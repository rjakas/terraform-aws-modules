output "permission_set_arns" {
  description = "Map of permission set names to ARNs."
  value = {
    for ps in aws_ssoadmin_permission_set.this : ps.name => ps.arn
  }
}

output "permission_set_ids" {
  description = "Map of permission set names to IDs."
  value = {
    for ps in aws_ssoadmin_permission_set.this : ps.name => ps.permission_set_id
  }
}

output "group_ids" {
  description = "Map of group display names to identity store IDs."
  value = {
    for group in aws_identitystore_group.this : group.display_name => group.group_id
  }
}
