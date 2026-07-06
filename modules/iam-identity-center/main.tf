data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]

  # Map permission set name to resource for name-based lookups in assignments.
  permission_set_by_name = {
    for ps in aws_ssoadmin_permission_set.this : ps.name => ps
  }

  # Flatten assignments so each group_id + permission_set_name + account_id
  # combination becomes a single resource.
  flattened_assignments = flatten([
    for assignment in var.account_assignments : [
      for account_id in assignment.account_ids : {
        key                 = "${assignment.group_id}-${assignment.permission_set_name}-${account_id}"
        group_id            = assignment.group_id
        permission_set_name = assignment.permission_set_name
        account_id          = account_id
      }
    ]
  ])
}

resource "aws_identitystore_group" "this" {
  for_each = var.groups

  identity_store_id = var.identity_store_id
  display_name      = each.value.display_name
  description       = each.value.description
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = var.permission_sets

  instance_arn     = local.instance_arn
  name             = each.value.name
  description      = each.value.description
  session_duration = each.value.session_duration

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = {
    for pair in flatten([
      for ps_key, ps in var.permission_sets : [
        for arn in try(ps.managed_policy_arns, []) : {
          key        = "${ps_key}-${basename(arn)}"
          ps_key     = ps_key
          policy_arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.ps_key].arn
  managed_policy_arn = each.value.policy_arn
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "this" {
  for_each = {
    for pair in flatten([
      for ps_key, ps in var.permission_sets : [
        for policy_name in try(ps.customer_managed_policies, []) : {
          key         = "${ps_key}-${policy_name}"
          ps_key      = ps_key
          policy_name = policy_name
          policy_path = "/"
        }
      ]
    ]) : pair.key => pair
  }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.ps_key].arn

  customer_managed_policy_reference {
    name = each.value.policy_name
    path = each.value.policy_path
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  for_each = {
    for ps_key, ps in var.permission_sets : ps_key => ps.inline_policy
    if ps.inline_policy != null
  }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  inline_policy      = each.value
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = {
    for assignment in local.flattened_assignments : assignment.key => assignment
  }

  instance_arn       = local.instance_arn
  permission_set_arn = local.permission_set_by_name[each.value.permission_set_name].arn

  principal_id   = each.value.group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}
