data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_organizations_organization" "current" {
  count = var.is_organization_trail ? 1 : 0
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  organization_id = var.is_organization_trail ? data.aws_organizations_organization.current[0].id : null

  create_kms_key = var.create_kms_key && var.kms_key_id == null
  kms_key_arn    = local.create_kms_key ? aws_kms_key.this[0].arn : var.kms_key_id

  create_cloudwatch_log_group = var.cloud_watch_logs_group_arn == null
  cloudwatch_log_group_arn    = local.create_cloudwatch_log_group ? "${aws_cloudwatch_log_group.this[0].arn}:*" : var.cloud_watch_logs_group_arn
}

# ---------------------------------------------------------------------------
# KMS key for log encryption
# ---------------------------------------------------------------------------
resource "aws_kms_key" "this" {
  count = local.create_kms_key ? 1 : 0

  description             = "KMS key for CloudTrail log encryption - ${var.name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy[0].json
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  count = local.create_kms_key ? 1 : 0

  name          = "alias/cloudtrail-${var.name}"
  target_key_id = aws_kms_key.this[0].id
}

data "aws_iam_policy_document" "kms_key_policy" {
  count = local.create_kms_key ? 1 : 0

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow CloudTrail to encrypt logs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:${local.partition}:cloudtrail:*:${local.account_id}:trail/${var.name}"]
    }
  }

  statement {
    sid    = "Allow CloudTrail to describe key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------
# S3 bucket for log delivery
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = var.s3_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_policy" "this" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.bucket_policy[0].json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "bucket_policy" {
  count = var.create_s3_bucket ? 1 : 0

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this[0].arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[0].arn}/${var.s3_key_prefix}/AWSLogs/${local.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  dynamic "statement" {
    for_each = var.is_organization_trail ? [1] : []

    content {
      sid    = "AWSCloudTrailWriteOrganization"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this[0].arn}/${var.s3_key_prefix}/AWSLogs/${local.organization_id}/*"]
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    }
  }
}

# ---------------------------------------------------------------------------
# CloudWatch log group for real-time log streaming
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  count = local.create_cloudwatch_log_group ? 1 : 0

  name              = "/aws/cloudtrail/${var.name}"
  retention_in_days = 365
  kms_key_id        = local.kms_key_arn
  tags              = var.tags
}

# ---------------------------------------------------------------------------
# CloudTrail
# ---------------------------------------------------------------------------
resource "aws_cloudtrail" "this" {
  name                          = var.name
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = var.s3_key_prefix
  is_organization_trail         = var.is_organization_trail
  is_multi_region_trail         = var.is_multi_region_trail
  include_global_service_events = var.include_global_service_events
  enable_log_file_validation    = var.enable_log_file_validation
  kms_key_id                    = local.kms_key_arn
  cloud_watch_logs_group_arn    = local.cloudwatch_log_group_arn
  cloud_watch_logs_role_arn     = var.cloud_watch_logs_role_arn
  tags                          = var.tags

  dynamic "event_selector" {
    for_each = var.event_selectors

    content {
      read_write_type                  = lookup(event_selector.value, "read_write_type", "All")
      include_management_events        = lookup(event_selector.value, "include_management_events", true)
      exclude_management_event_sources = lookup(event_selector.value, "exclude_management_event_sources", null)

      dynamic "data_resource" {
        for_each = lookup(event_selector.value, "data_resource", [])

        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }

    }
  }

  dynamic "insight_selector" {
    for_each = var.insight_selectors

    content {
      insight_type = insight_selector.value.insight_type
    }
  }

  depends_on = [
    aws_s3_bucket_policy.this,
  ]
}
