locals {
  oidc_provider_statements = [
    for k, v in var.trusted_oidc_providers : {
      Effect = "Allow"
      Principal = {
        Federated = v.provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        for test_key, conditions in {
          for cond in v.conditions : cond.test => cond...
          } : test_key => {
          for cond in conditions : cond.variable => cond.values
        }
      }
    }
  ]

  github_oidc_conditions = merge(
    length(var.oidc_subjects) > 0 ? {
      StringLike = {
        "token.actions.githubusercontent.com:sub" = var.oidc_subjects
      }
    } : {},
    {
      StringEquals = {
        "token.actions.githubusercontent.com:aud" = var.oidc_audience
      }
    },
    length(var.oidc_conditions) > 0 ? {
      for test_key, conditions in {
        for cond in var.oidc_conditions : cond.test => cond...
        } : test_key => {
        for cond in conditions : cond.variable => cond.values
      }
    } : {}
  )

  github_oidc_statement = (
    var.github_oidc_provider_arn != null &&
    (length(var.oidc_subjects) > 0 || length(var.oidc_conditions) > 0)
    ) ? [{
      Effect = "Allow"
      Principal = {
        Federated = var.github_oidc_provider_arn
      }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = local.github_oidc_conditions
  }] : []

  account_statements = [
    for acc in var.trusted_accounts : {
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${acc.account_id}:root"
      }
      Action = "sts:AssumeRole"
      Condition = merge(
        {
          StringEquals = {
            "sts:ExternalId" = acc.external_id != null ? acc.external_id : random_id.external_id[acc.account_id].hex
          }
        },
        var.require_mfa ? {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        } : {}
      )
    }
  ]

  statements = concat(
    local.oidc_provider_statements,
    local.github_oidc_statement,
    local.account_statements
  )

  assume_role_policy = var.assume_role_policy != null ? var.assume_role_policy : jsonencode({
    Version   = "2012-10-17"
    Statement = local.statements
  })
}

resource "random_id" "external_id" {
  for_each = {
    for acc in var.trusted_accounts : acc.account_id => acc
    if acc.external_id == null
  }

  byte_length = 32
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  path                 = var.path
  assume_role_policy   = local.assume_role_policy
  max_session_duration = var.max_session_duration
  tags                 = var.tags

  lifecycle {
    precondition {
      condition     = (length(var.oidc_subjects) == 0 && length(var.oidc_conditions) == 0) || var.github_oidc_provider_arn != null
      error_message = "github_oidc_provider_arn is required when oidc_subjects or oidc_conditions are used."
    }
  }
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

resource "aws_secretsmanager_secret" "external_id" {
  for_each = var.store_external_ids_in_secrets_manager ? random_id.external_id : {}

  name        = "iam-role-external-id/${var.name}/${each.key}"
  description = "External ID for IAM role ${var.name} trusted account ${each.key}"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "external_id" {
  for_each = var.store_external_ids_in_secrets_manager ? random_id.external_id : {}

  secret_id     = aws_secretsmanager_secret.external_id[each.key].id
  secret_string = each.value.hex
}
