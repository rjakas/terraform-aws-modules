# Production Ready AWS IAM and Identity Infrastructure Guidance

## Metadata
- `created-at-date:` `06-07-2026`
- `created-by`: `Renaldas Jakas`
- `version`: `1.0`
- `last-updated-date`: `06-07-2026`
- `last-updated-by`: `Renaldas Jakas`

## Introduction
GitHub-hosted runners combined with **OIDC authentication are the recommended and more secure approach** for most use cases; they eliminate all long-lived credentials entirely.
EC2 self-hosted runners are **not required for security** and in fact shift significant operational burden to you unless you specifically need VPC-private resource access, GPU builds, or compliance requirements that mandate data residency.

The authentication flow works via **OpenID Connect (OIDC) federation**: GitHub's OIDC provider issues a short-lived signed JWT token for each workflow run, AWS validates this token against a pre-configured IAM OIDC identity provider, and exchanges it for temporary STS credentials scoped to a specific IAM role; no access keys are ever stored or transmitted.

Core Terraform modules for enabling production ready AWS IAM:
- `iam-account` (root lockdown and password policy)
- `iam-oidc-provider` (GitHub federation)
- `iam-role` (assume-role policies for CI/CD and human access)
- `organizations` (multi-account structure and SCPs)
- `cloudtrail` (audit logging)

These modules compose into environment-specific configurations that enforce least privilege from the start.

Reference: [(Github)](https://github.com/aws-actions/configure-aws-credentials) 

