output "arn" {
  description = "ARN of the OIDC provider."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "url" {
  description = "URL of the OIDC provider."
  value       = aws_iam_openid_connect_provider.this.url
}
