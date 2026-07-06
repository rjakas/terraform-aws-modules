locals {
  base_tags = merge(var.tags, { RolloutStage = var.rollout_stage })

  # Built-in policy: deny root user actions.
  deny_root_statements = concat(
    [{
      Sid      = "DenyRootUser"
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
      Condition = {
        Bool = {
          "aws:PrincipalIsRoot" = "true"
        }
      }
    }],
    length(var.deny_root_except) > 0 ? [{
      Sid      = "AllowRootExceptions"
      Effect   = "Allow"
      Action   = var.deny_root_except
      Resource = "*"
    }] : []
  )

  deny_root_policy = {
    "deny-root" = {
      name        = "DenyRootUserActions"
      description = "Deny all actions performed by the root user except configured break-glass actions."
      type        = "SERVICE_CONTROL_POLICY"
      content = jsonencode({
        Version   = "2012-10-17"
        Statement = local.deny_root_statements
      })
      tags = {}
    }
  }

  # Built-in policy: restrict usage to approved regions.
  region_lock_policy = length(var.approved_regions) > 0 ? {
    "deny-unapproved-regions" = {
      name        = "DenyUnapprovedRegions"
      description = "Deny all actions in AWS regions that are not explicitly approved."
      type        = "SERVICE_CONTROL_POLICY"
      content = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid      = "DenyUnapprovedRegions"
          Effect   = "Deny"
          Action   = "*"
          Resource = "*"
          Condition = {
            StringNotEquals = {
              "aws:RequestedRegion" = var.approved_regions
            }
          }
        }]
      })
      tags = {}
    }
  } : {}

  # Built-in policy: protect security services from being disabled.
  protected_service_actions = {
    cloudtrail        = ["cloudtrail:DeleteTrail", "cloudtrail:StopLogging"]
    guardduty         = ["guardduty:DeleteDetector", "guardduty:DisassociateFromMasterAccount", "guardduty:StopMonitoringMembers"]
    config            = ["config:DeleteConfigurationRecorder", "config:DeleteDeliveryChannel", "config:StopConfigurationRecorder"]
    securityhub       = ["securityhub:DisableSecurityHub", "securityhub:DeleteHub"]
    "access-analyzer" = ["access-analyzer:DeleteAnalyzer"]
  }

  protect_actions = toset(flatten([
    for service in var.protected_services : lookup(local.protected_service_actions, service, [])
  ]))

  protect_security_services_policy = length(local.protect_actions) > 0 ? {
    "protect-security-services" = {
      name        = "ProtectSecurityServices"
      description = "Prevent disabling or deleting core security and logging services."
      type        = "SERVICE_CONTROL_POLICY"
      content = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid      = "ProtectSecurityServices"
          Effect   = "Deny"
          Action   = sort(local.protect_actions)
          Resource = "*"
        }]
      })
      tags = {}
    }
  } : {}

  # Built-in policy: require encryption for resource creation.
  encryption_service_config = {
    s3 = {
      actions = ["s3:PutObject"]
      condition = {
        Null = {
          "s3:x-amz-server-side-encryption" = "true"
        }
      }
    }
    ebs = {
      actions = ["ec2:CreateVolume"]
      condition = {
        StringEquals = {
          "ec2:Encrypted" = "false"
        }
      }
    }
    rds = {
      actions = ["rds:CreateDBInstance"]
      condition = {
        StringEquals = {
          "rds:StorageEncrypted" = "false"
        }
      }
    }
  }

  encryption_statements = [
    for service in var.required_encryption_services : {
      Sid       = "RequireEncryption${title(service)}"
      Effect    = "Deny"
      Action    = local.encryption_service_config[service].actions
      Resource  = "*"
      Condition = local.encryption_service_config[service].condition
    }
    if contains(keys(local.encryption_service_config), service)
  ]

  require_encryption_policy = length(local.encryption_statements) > 0 ? {
    "require-encryption" = {
      name        = "RequireEncryption"
      description = "Deny creation of unencrypted resources for supported services."
      type        = "SERVICE_CONTROL_POLICY"
      content = jsonencode({
        Version   = "2012-10-17"
        Statement = local.encryption_statements
      })
      tags = {}
    }
  } : {}

  # Merge built-in policies with user-supplied policies. User policies override
  # built-in policies when they share the same map key.
  all_policies = merge(
    local.deny_root_policy,
    local.region_lock_policy,
    local.protect_security_services_policy,
    local.require_encryption_policy,
    var.policies
  )
}

resource "aws_organizations_policy" "this" {
  for_each = local.all_policies

  name        = each.value.name
  description = try(each.value.description, null)
  type        = try(each.value.type, "SERVICE_CONTROL_POLICY")
  content     = each.value.content

  tags = merge(local.base_tags, try(each.value.tags, {}))
}
