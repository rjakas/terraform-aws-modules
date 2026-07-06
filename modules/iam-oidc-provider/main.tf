locals {
  provider_url        = var.create_github_provider ? "https://token.actions.githubusercontent.com" : var.url
  provider_client_ids = var.create_github_provider ? ["sts.amazonaws.com"] : var.client_id_list
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = local.provider_url
  client_id_list  = local.provider_client_ids
  thumbprint_list = var.thumbprint_list

  tags = var.tags
}
