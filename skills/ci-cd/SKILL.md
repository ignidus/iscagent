---
name: ci-cd
version: 1.0.0
description: CI/CD pipeline management with GitHub Actions
author: iscmga
tags: [ci-cd, github-actions, deployment]
tools: [gh-cli]
---

# CI/CD Skill

## Trigger

Activate when working with GitHub Actions workflows, deployment pipelines, container builds, or release processes.

## Conventions

- Pipelines defined in `.github/workflows/`
- Terraform CI runs drift check against base branch (main)
- Exit code 1 = plan error (warning), exit code 2 = drift (blocking)
- Container images pushed to ECR
- Separate PRs for separate concerns

## GitHub CLI

Always unset GITHUB_TOKEN before using `gh` commands (stale env var causes 401):

```bash
unset GITHUB_TOKEN
gh pr create --title "..." --body "..."
```

## PR Workflow

1. Create feature branch from main
2. Make changes and commit with descriptive messages
3. Push and create PR with summary + test plan
4. Wait for CI checks to pass
5. Request review
