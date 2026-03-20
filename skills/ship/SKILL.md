---
name: ship
version: 1.0.0
description: Automated release pipeline — test, review, version, changelog, commit organization, and PR creation with minimal user intervention.
author: iscmga
tags: [release, ship, ci-cd, pr, changelog, versioning, automation]
triggers:
  globs: []
  keywords: [ship, release, create pr, push changes, version bump, changelog, ship it]
---

# Ship

Fully automated release workflow. Handles: testing, code review, versioning, changelog generation, commit organization, and PR creation. Only stops for genuine blockers. Inspired by gstack's ship methodology.

## When to Activate

- "Ship it"
- "Create a PR for these changes"
- "Release these changes"
- After completing a feature or fix and wanting to push
- When preparing infrastructure changes for merge

## Core Principles

1. **Automation-first**: Make 50+ decisions without asking. Only stop for genuine blockers.
2. **Fresh verification**: Never push with stale test results. Re-run before push.
3. **Bisectable commits**: Every commit should be independently understandable and revertable.
4. **Evidence trail**: The PR body documents what changed, why, and what was verified.

## Workflow

### Step 0: Pre-flight

```bash
# Current branch
BRANCH=$(git branch --show-current)

# Base branch
BASE=$(gh pr view --json baseRefName -q '.baseRefName' 2>/dev/null || git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

# Ensure we're not on the base branch
if [ "$BRANCH" = "$BASE" ]; then
  echo "ERROR: Cannot ship from $BASE. Create a feature branch first."
  exit 1
fi

# Check for uncommitted changes
git status --short
```

If there are uncommitted changes, stage and commit them before proceeding.

### Step 1: Run Tests

Run the project's test suite. Detect the test command from:
1. CLAUDE.md instructions
2. Makefile / package.json / Pipfile
3. Common patterns: `make test`, `npm test`, `pytest`, `go test ./...`

For Terraform repos:
```bash
terraform fmt -check -recursive
terraform validate
# If available: terraform plan (with appropriate profile)
```

If tests fail, stop. Fix the failures before shipping.

### Step 2: Review

Invoke the `review` skill on the current branch diff. Apply any AUTO-FIX items. If there are critical ASK items that block merge, stop and present them.

### Step 3: Organize Commits

Review the commit history on this branch. If commits are messy:

1. Group related changes into logical commits
2. Each commit should be a single concern (one fix, one feature, one refactor)
3. Write clear commit messages that explain WHY, not just WHAT

Good commit organization:
- Rename/move separate from behavior changes
- Test infrastructure separate from test implementations
- Configuration changes separate from code changes
- Mechanical refactors separate from new features

### Step 4: Version Decision

For projects that use versioning, auto-decide the bump:

| Change Type | Version Bump | Examples |
|-------------|-------------|---------|
| Bug fix, typo, docs | PATCH (0.0.X) | Fix typo in config, update README |
| New feature, enhancement | MINOR (0.X.0) | Add new module, new variable |
| Breaking change | MAJOR (X.0.0) | Remove output, rename module, change API |

For infrastructure repos without semver, skip this step.

### Step 5: Generate Changelog Entry

If the project maintains a CHANGELOG:

```markdown
## [version] - YYYY-MM-DD

### Added
- New VPC peering module for cross-account networking

### Changed
- Updated ECS task definition to use ARM64 instances

### Fixed
- Corrected security group rule that blocked health checks
```

Write for users, not contributors. Lead with what changed and why it matters.

### Step 6: Final Verification

Re-run tests after all changes (commit organization, auto-fixes, version bump):

```bash
# Whatever the project's test command is
make test  # or terraform validate, npm test, etc.
```

If tests fail now, something went wrong during organization. Fix before proceeding.

### Step 7: Push and Create PR

```bash
git push -u origin "$BRANCH"
```

Create the PR with a comprehensive body:

```bash
gh pr create --title "<concise title under 70 chars>" --body "$(cat <<'EOF'
## Summary
- <bullet points of what changed and why>

## Changes
- <file-level change descriptions>

## Testing
- [ ] Tests pass locally
- [ ] terraform validate passes
- [ ] terraform fmt check passes
- [ ] Manual verification: <what was checked>

## Review Notes
- <anything reviewers should pay attention to>
- <decisions that were made and why>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

### Step 8: Report

Present a summary:
```
SHIPPED: <branch> → <base>
PR: <url>
Commits: <count>
Tests: PASS
Review: <clean | N auto-fixes applied>
```

## Infrastructure-Specific Notes

### Terraform PRs
- Always include `terraform plan` output summary in PR body (if available)
- Note any resources being created, modified, or destroyed
- Flag any cost-impacting changes
- Reference JIRA tickets if applicable

### Multi-account Changes
- Note which AWS accounts are affected
- Verify the correct profile was used for planning
- Include account IDs in the PR description

## Anti-Patterns

- **Shipping without tests**: Always run the test suite, even if "nothing changed that affects tests."
- **Monster PRs**: If the diff is >500 lines, consider splitting into multiple PRs.
- **Stale plans**: Don't reference terraform plan output from hours ago. Re-run before shipping.
- **Force-pushing**: Never force-push to shared branches. Create new commits.

## Integration Points

### With `review` skill
Ship invokes review as Step 2. If review finds critical issues, ship stops.

### With `careful` skill
Ship should never bypass careful guardrails. If careful would warn about a command, ship should too.

### With `retro` skill
After shipping, retro can analyze the session's velocity and quality.
