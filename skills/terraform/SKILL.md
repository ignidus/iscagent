---
name: terraform
version: 1.0.0
description: Terraform infrastructure management for AWS multi-account org
author: iscmga
tags: [terraform, iac, aws]
tools: [terraform-cli, aws-api]
---

# Terraform Skill

## Trigger

Activate when working with .tf files, Terraform modules, HCL, infrastructure provisioning, or state management.

## Workflow

1. Read existing Terraform code before modifying
2. Validate syntax with `terraform validate`
3. Run `terraform plan` and review output
4. Only `terraform apply` after user confirmation
5. Commit with descriptive message explaining the infrastructure change

## Conventions

- Use the AWSCC provider when available, fall back to AWS provider
- Module sources use git SSH URLs with version tags
- State is managed remotely in S3 with DynamoDB locking
- Follow established tagging standards (module.dev-iscx-tags.tags)
- ECS task definitions loaded from `ecs-tasks/*.json` files
- Container definitions use `file()` function

## Common Patterns

- Terraform drift: ECS services use `max()` for task_definition revision
- State locks from same user can be force-unlocked safely
- CI drift check runs against base branch (main), not PR branch

## AWS Profiles

Always use SSO profiles. Unset stale environment variables before switching:

```bash
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_CREDENTIAL_EXPIRATION
export AWS_PROFILE=dev
```
