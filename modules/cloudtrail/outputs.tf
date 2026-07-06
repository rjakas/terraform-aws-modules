output "trail_arn" {
  description = "CloudTrail ARN."
  value       = aws_cloudtrail.this.arn
}

output "trail_name" {
  description = "CloudTrail name."
  value       = aws_cloudtrail.this.name
}

output "s3_bucket_arn" {
  description = "ARN of the log bucket."
  value       = var.create_s3_bucket ? aws_s3_bucket.this[0].arn : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key."
  value       = local.kms_key_arn
}
