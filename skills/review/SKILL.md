---
name: review
version: 1.0.0
description: Structured code and infrastructure PR review with evidence-based findings, auto-fix classification, and scope drift detection.
author: iscmga
tags: [code-review, pr-review, infrastructure, terraform, security, quality]
triggers:
  globs: ["**/*.tf", "**/*.ts", "**/*.py", "**/*.go", "**/*.yaml"]
  keywords: [review, code review, pr review, pull request, review changes, review PR]
---

# Review

Structured pre-merge review workflow that catches issues tests miss. Focuses on evidence-based findings — every claim needs a line number, test reference, or concrete proof. Inspired by gstack's review methodology.

## When to Activate

- Before merging a pull request
- "Review this PR"
- "Review my changes"
- When a branch has changes ready for review
- As part of the `ship` skill pipeline

## Core Principles

1. **Evidence-based**: Every finding must cite a specific line, file, or test. No vague claims.
2. **Auto-fix vs Ask**: Obvious issues get fixed automatically. Ambiguous ones get flagged for discussion.
3. **Scope awareness**: Detect when changes drift beyond the stated intent.
4. **Two-pass approach**: Critical issues first, then informational.

## Workflow

### Step 0: Validate Branch

```bash
# Detect base branch
BASE=$(gh pr view --json baseRefName -q '.baseRefName' 2>/dev/null || git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

# Get the diff
git diff "$BASE"...HEAD --stat
git diff "$BASE"...HEAD
```

If there are no changes, stop. Nothing to review.

### Step 1: Scope Check

Read the PR description or most recent commit messages. Then compare to the actual diff:

1. What does the author say they changed?
2. What did they actually change?
3. Is there scope drift? (files changed that don't relate to the stated purpose)

If scope drift is detected, report it:
```
SCOPE DRIFT: The following changes appear unrelated to the stated purpose:
- path/to/file.tf — adds unrelated tagging changes
- path/to/other.py — reformats code not related to the feature
```

### Step 2: Critical Review (Pass 1)

Check for issues that MUST be fixed before merge. For infrastructure repos, focus on:

**Security**
- Hardcoded secrets, API keys, passwords
- Overly permissive IAM policies (wildcards in actions/resources)
- Security groups open to 0.0.0.0/0 on non-standard ports
- Missing encryption (at rest or in transit)
- Public access enabled on S3 buckets, RDS instances, etc.

**Correctness**
- Terraform resource references that don't exist
- Circular dependencies
- Missing required arguments
- Wrong resource types or data source lookups
- Race conditions in scripts or automation

**Data Safety**
- Destructive changes without protection (lifecycle prevent_destroy)
- State manipulation without backup
- Database migrations that drop columns/tables without confirmation
- Force-replacement of stateful resources (RDS, EFS, etc.)

**Blast Radius**
- Changes that affect production without staged rollout
- Missing count/for_each guards on bulk resource creation
- Wildcard resource targeting in scripts

### Step 3: Informational Review (Pass 2)

Lower-priority findings that improve quality:

- Missing tags or inconsistent tagging
- Deprecated resource arguments or provider features
- Hardcoded values that should be variables
- Missing descriptions on variables and outputs
- Duplicate code that could be a module
- Missing documentation updates

### Step 4: Classify Findings

For each finding, classify as:

| Classification | Action | When |
|---------------|--------|------|
| **AUTO-FIX** | Apply the fix directly | Obvious, low-risk fixes (typos, missing tags, formatting) |
| **ASK** | Present to user for decision | Ambiguous, architectural, or potentially breaking changes |
| **INFO** | Note for awareness | Style, conventions, nice-to-haves |

### Step 5: Apply Auto-Fixes

For each AUTO-FIX item:
1. Make the change
2. Document what was changed and why
3. Stage the file

Never auto-fix:
- Architectural decisions
- Resource deletions or replacements
- Security policy changes
- Anything that changes behavior

### Step 6: Present Report

```markdown
## Review Summary

**Branch:** feature/xyz → main
**Files changed:** N
**Scope:** [CLEAN | DRIFT DETECTED]

### Critical (must fix)
| # | File:Line | Issue | Classification |
|---|-----------|-------|----------------|
| 1 | main.tf:42 | IAM policy uses wildcard action | ASK |
| 2 | variables.tf:15 | Missing type constraint | AUTO-FIX (applied) |

### Informational
| # | File:Line | Issue |
|---|-----------|-------|
| 1 | modules/vpc/main.tf:88 | Consider adding description to output |

### Auto-fixes Applied
- variables.tf:15 — added type = string constraint
- tags.tf:3 — added missing Environment tag

### Verdict: [APPROVE | REQUEST CHANGES | NEEDS DISCUSSION]
```

## Infrastructure-Specific Checks

### Terraform
- `terraform validate` passes
- `terraform fmt -check` passes
- No `-target` usage in CI/CD
- State locking is configured
- Backend configuration is correct
- Provider versions are pinned

### AWS
- Resources use appropriate instance types for the environment
- Cross-account access is explicitly documented
- VPC CIDR ranges don't overlap with existing networks
- DNS records point to the right targets
- Cost-impacting changes are flagged (instance size, storage, NAT gateways)

### CI/CD
- Pipeline changes don't skip security checks
- Deployment steps have rollback mechanisms
- Environment-specific configurations are correct

## Anti-Patterns

- **Rubber-stamping**: Every review should have at least one concrete observation, even if it's "this looks correct because X".
- **Assumption-based findings**: "This might cause issues" without evidence. Either demonstrate the issue or don't report it.
- **Scope creep in review**: Don't suggest unrelated improvements. Stay focused on the changes in the diff.
- **Blocking on style**: Style preferences are INFO, not blockers. Use AUTO-FIX for formatting.

## Integration Points

### With `ship` skill
Review is a required step in the ship pipeline. Ship invokes review before creating a PR.

### With `careful` skill
Review should flag the same destructive patterns that careful guards against.

### With `security-review` skill
For security-focused changes, invoke the full security-review skill instead of the security subset here.
