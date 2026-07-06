resource "aws_organizations_organization" "this" {
  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types
  feature_set                   = "ALL"
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = var.organizational_units

  name      = each.value.name
  parent_id = coalesce(each.value.parent_id, aws_organizations_organization.this.roots[0].id)

  tags = merge(var.tags, coalesce(each.value.tags, {}))
}

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name      = each.value.name
  email     = each.value.email
  parent_id = coalesce(each.value.parent_id, aws_organizations_organization.this.roots[0].id)
  role_name = coalesce(each.value.role_name, var.default_account_role_name)

  tags = merge(var.tags, coalesce(each.value.tags, {}))

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  organizational_unit_target_ids = {
    for key, ou in aws_organizations_organizational_unit.this : key => ou.id
  }

  account_target_ids = {
    for key, account in aws_organizations_account.this : key => account.id
  }

  all_target_ids = merge(
    local.organizational_unit_target_ids,
    local.account_target_ids,
  )

  scp_attachments = flatten([
    for target_key, policy_ids in var.attached_scps : [
      for idx, policy_id in policy_ids : {
        key       = "${target_key}-${idx}"
        target_id = lookup(local.all_target_ids, target_key, target_key)
        policy_id = policy_id
      }
    ]
  ])
}

resource "aws_organizations_policy_attachment" "this" {
  for_each = { for att in local.scp_attachments : att.key => att }

  target_id = each.value.target_id
  policy_id = each.value.policy_id
}
