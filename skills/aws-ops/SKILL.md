---
name: aws-ops
version: 1.0.0
description: AWS operations across multi-account organization
author: iscmga
tags: [aws, operations, cloud]
tools: [aws-cli, cost-explorer]
---

# AWS Operations Skill

## Trigger

Activate when working with AWS services, cost analysis, security audits, account management, or operational tasks.

## AWS Organization

- Primary payer/org account: 277412802209 (profile: org)
- SSO start URL: https://isceng.awsapps.com/start/#
- Infrastructure repo: ~/Desktop/Work/infrastructure/

## Account Map

| Profile | Account ID | Notes |
|---------|-----------|-------|
| org | 277412802209 | Org payer |
| prod | 049005703416 | Shield Advanced |
| dev | 694679581764 | Development |
| network | 168118765682 | Networking |
| data | 427236400873 | Data platform |
| security | 394571833146 | Security tooling |
| audit | 637423386987 | FMS admin |
| sandbox | 272518307028 | Experimentation |

## Workflow

1. Authenticate: `aws sso login --profile <profile>`
2. Unset stale env vars before profile switch
3. Verify identity: `aws sts get-caller-identity --profile <profile>`
4. Execute operations
5. Document changes

## Cost Analysis

Always consider cost implications. Use cost-explorer and billing MCP servers when available. Flag any resources that appear over-provisioned or unused.

## Security Posture

- Run Prowler scans for compliance checks
- Review Security Hub findings
- Validate GuardDuty is enabled across all accounts
- Check IAM policies follow least privilege
