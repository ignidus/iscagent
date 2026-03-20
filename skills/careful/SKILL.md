---
name: careful
version: 1.0.0
description: Destructive command safety guardrails. Warns before dangerous operations in production and shared environments.
author: iscmga
tags: [safety, guardrails, production, destructive, protection]
triggers:
  globs: []
  keywords: [careful, safe mode, production safety, guardrails, be careful, careful mode]
---

# Careful

Pre-execution safety guardrails that warn before dangerous operations. Prevents accidental destruction of infrastructure, data, and shared state. Inspired by gstack's careful/guard methodology.

## When to Activate

- Before any work in production environments
- "Be careful with these changes"
- "Enable careful mode"
- When working with shared infrastructure
- During incident response (prevent making things worse)
- Automatically when detecting production context (profile names, account IDs)

## Dangerous Command Patterns

### Infrastructure — ALWAYS WARN

| Pattern | Risk | Alternative |
|---------|------|-------------|
| `terraform destroy` | Destroys all managed resources | Target specific resources with `-target` |
| `terraform state rm` | Removes resource from state (orphans it) | Use `terraform state mv` for renames |
| `terraform force-unlock` | Breaks state lock | Verify lock holder first |
| `terraform apply -auto-approve` | No review of changes | Remove `-auto-approve`, review plan |
| `terraform import` (to wrong state) | Corrupts state | Verify state file and resource first |

### AWS — ALWAYS WARN

| Pattern | Risk | Alternative |
|---------|------|-------------|
| `aws s3 rm --recursive` | Deletes all objects in bucket | Use `--dryrun` first |
| `aws s3 rb --force` | Deletes bucket and all contents | Empty bucket first, review |
| `aws rds delete-db-instance` | Deletes database | Verify snapshot exists first |
| `aws ec2 terminate-instances` | Terminates instances permanently | Stop first, verify instance ID |
| `aws iam delete-role` | Removes IAM role | Check what depends on it first |
| `aws route53 change-resource-record-sets DELETE` | Removes DNS records | Verify record and impact |
| `aws ecs update-service --desired-count 0` | Stops all tasks | Verify it's the right service/cluster |
| `aws cloudformation delete-stack` | Deletes entire stack | Review stack resources first |
| `aws organizations remove-account` | Removes account from org | Verify account ID |

### Git — ALWAYS WARN

| Pattern | Risk | Alternative |
|---------|------|-------------|
| `git push --force` | Overwrites remote history | Use `--force-with-lease` |
| `git reset --hard` | Discards all uncommitted changes | `git stash` first |
| `git branch -D` | Deletes branch even if unmerged | `git branch -d` (safe delete) |
| `git checkout .` | Discards all working changes | `git stash` first |
| `git clean -fd` | Deletes untracked files | `git clean -fdn` (dry run) first |

### Database — ALWAYS WARN

| Pattern | Risk | Alternative |
|---------|------|-------------|
| `DROP TABLE` / `DROP DATABASE` | Permanent data loss | Backup first, use `IF EXISTS` |
| `TRUNCATE TABLE` | Deletes all rows | Verify table and environment |
| `DELETE FROM` without WHERE | Deletes all rows | Add WHERE clause |
| `ALTER TABLE DROP COLUMN` | Permanent data loss | Backup table first |

### System — ALWAYS WARN

| Pattern | Risk | Alternative |
|---------|------|-------------|
| `rm -rf /` or `rm -rf *` | Destroys filesystem | Be specific with paths |
| `kill -9` on production PIDs | Abrupt process termination | `kill -15` (graceful) first |
| `chmod -R 777` | Opens permissions wide | Use specific permissions |

## Safe Exceptions

These are always safe to delete/clean (build artifacts):
- `node_modules/`, `.next/`, `dist/`, `build/`
- `__pycache__/`, `.cache/`, `.turbo/`
- `coverage/`, `.terraform/` (NOT `.terraform.lock.hcl`)
- `*.pyc`, `*.pyo`, `*.o`

## Production Context Detection

Automatically engage careful mode when detecting:

- AWS profile names containing: `prod`, `production`, `org`, `management`
- Account IDs matching known production accounts
- Terraform workspaces named `prod` or `production`
- Branch names: `main`, `master`, `production`
- Environment variables: `ENV=production`, `NODE_ENV=production`

## Warning Format

When a dangerous command is detected:

```
WARNING: DESTRUCTIVE OPERATION DETECTED

Command: terraform destroy -target=aws_rds_instance.main
Risk: This will permanently delete the RDS instance and all its data.
Environment: production (account 049005703416)

Before proceeding:
1. Verify you have a recent snapshot/backup
2. Confirm this is the correct resource
3. Verify no other services depend on this resource

Proceed? [y/N]
```

## Guard Mode (Extended)

When maximum protection is needed, combine careful with directory scoping:

1. Restrict file edits to a specific directory
2. All destructive commands require confirmation
3. No commands execute outside the scoped directory

Useful for:
- Production incident response (only edit the affected service)
- Sensitive infrastructure changes (only edit the target module)
- Training/onboarding (prevent accidental damage)

## Anti-Patterns

- **Disabling guardrails**: Never bypass careful mode "because it's faster." The 5 seconds of confirmation prevents hours of recovery.
- **Warning fatigue**: If you find yourself auto-approving every warning, the scope is too broad. Narrow the protection to what matters.
- **False safety**: Careful mode doesn't replace proper testing and review. It's a last line of defense, not a substitute for process.

## Integration Points

### With `ship` skill
Ship should inherit careful's guardrails. If careful would warn, ship should too.

### With `investigate` skill
Always enable careful mode during incident investigation to prevent making things worse.

### With `review` skill
Review should flag the same destructive patterns that careful guards against.
