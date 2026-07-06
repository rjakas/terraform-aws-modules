# iam-oidc-provider

Terraform module that creates an IAM OIDC identity provider for federated authentication.

The primary use case is GitHub Actions (`https://token.actions.githubusercontent.com`), enabling keyless CI/CD by allowing GitHub's OIDC provider to issue short-lived JWT tokens that AWS can exchange for temporary STS credentials.

## Usage

```hcl
module "github_oidc" {
  source = "git::https://github.com/<org>/terraform-aws-modules//modules/iam-oidc-provider?ref=v1.0.0"

  create_github_provider = true

  tags = {
    ManagedBy   = "Terraform"
    Environment = "management"
    Purpose     = "github-actions-oidc"
  }
}
```

For a custom OIDC provider, provide the URL and thumbprints explicitly:

```hcl
module "custom_oidc" {
  source = "git::https://github.com/<org>/terraform-aws-modules//modules/iam-oidc-provider?ref=v1.0.0"

  url             = "https://example.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"]

  tags = {
    ManagedBy   = "Terraform"
    Environment = "management"
    Purpose     = "custom-oidc"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client_id_list"></a> [client_id_list](#input_client_id_list) | Client IDs (audiences) for the provider. | `list(string)` | <pre>[<br>  "sts.amazonaws.com"<br>]</pre> | no |
| <a name="input_create_github_provider"></a> [create_github_provider](#input_create_github_provider) | Convenience flag to create the GitHub OIDC provider with the known URL and audience. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input_tags) | Tags applied to all taggable resources. | `map(string)` | `{}` | no |
| <a name="input_thumbprint_list"></a> [thumbprint_list](#input_thumbprint_list) | Certificate thumbprints. Required for non-GitHub providers when AWS cannot auto-discover the thumbprint. | `list(string)` | `[]` | no |
| <a name="input_url"></a> [url](#input_url) | OIDC provider URL, e.g. `https://token.actions.githubusercontent.com`. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output_arn) | ARN of the OIDC provider. |
| <a name="output_url"></a> [url](#output_url) | URL of the OIDC provider. |
<!-- END_TF_DOCS -->
