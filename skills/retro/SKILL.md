---
name: retro
version: 1.0.0
description: Engineering retrospective and velocity analytics from git history. Generates weekly insights on team productivity, code quality, and contribution patterns.
author: iscmga
tags: [retrospective, analytics, velocity, git, metrics, team, productivity]
triggers:
  globs: []
  keywords: [retro, retrospective, velocity, team metrics, weekly report, what did we ship, productivity]
---

# Retro

Comprehensive engineering retrospective that analyzes git history to generate actionable insights on team velocity, code quality, and individual contributions. Inspired by gstack's retro methodology.

## When to Activate

- "Run a retro"
- "What did we ship this week?"
- "Show me team velocity"
- "Generate a weekly report"
- End of sprint / iteration
- Before planning meetings to understand capacity

## Core Principles

1. **Data-driven**: Every insight is anchored to a specific commit, PR, or metric.
2. **Constructive**: Praise is specific (cite the commit). Growth suggestions are actionable.
3. **Tweetable summary**: Lead with a one-line summary someone could share.
4. **Period-over-period**: Always compare to the previous period for trend detection.

## Workflow

### Step 1: Detection

```bash
# Current user
AUTHOR=$(git config user.name)

# Default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

# Date range (default: last 7 days)
SINCE="7 days ago"
```

### Step 2: Data Collection

Run these queries in parallel:

```bash
# Commit volume and authors
git log --since="$SINCE" --format="%H|%an|%ae|%aI|%s" --no-merges

# Lines changed by author
git log --since="$SINCE" --format="%an" --numstat --no-merges

# Files changed frequency (hotspots)
git log --since="$SINCE" --format="" --name-only --no-merges | sort | uniq -c | sort -rn | head -20

# PR activity (if using GitHub)
gh pr list --state merged --search "merged:>=$(date -v-7d +%Y-%m-%d)" --json number,title,author,mergedAt,additions,deletions

# Commit message patterns
git log --since="$SINCE" --format="%s" --no-merges

# Previous period for comparison
git log --since="14 days ago" --until="7 days ago" --format="%H|%an|%ae|%aI|%s" --no-merges
```

### Step 3: Compute Metrics

| Metric | How | Why |
|--------|-----|-----|
| **Commit count** | Count commits per period | Raw activity volume |
| **Unique contributors** | Count distinct authors | Team engagement |
| **Lines added/removed** | Sum numstat | Change volume |
| **Test-to-code ratio** | Files matching test patterns / total files changed | Quality signal |
| **PR count and size** | Count merged PRs, avg additions | Delivery cadence |
| **Hotspot files** | Most-changed files | Where attention is focused |
| **Commit patterns** | Group by prefix (feat:, fix:, chore:) | Work type distribution |

### Infrastructure-Specific Metrics

| Metric | How | Why |
|--------|-----|-----|
| **Terraform modules changed** | Count distinct modules in diff | Blast radius |
| **Resources created/modified/destroyed** | Parse plan outputs if available | Change impact |
| **Account spread** | Which AWS accounts were affected | Risk distribution |
| **Deployment frequency** | PRs merged to main | DORA metric |

### Step 4: Period Comparison

Compare current period to previous:

```
METRIC              THIS WEEK    LAST WEEK    DELTA
Commits             47           32           +47%
Contributors        4            3            +1
Lines added         2,340        1,890        +24%
Lines removed       890          420          +112%
PRs merged          6            4            +50%
Test files changed  8            3            +167%
```

### Step 5: Generate Narrative

Structure the output as:

```markdown
## Retro: <project-name> — Week of <date>

> <Tweetable one-liner summarizing the week>

### Highlights
- <Specific accomplishment with commit/PR reference>
- <Specific accomplishment with commit/PR reference>

### By the Numbers
| Metric | This Week | Last Week | Trend |
|--------|-----------|-----------|-------|
| ... | ... | ... | ... |

### Hotspots
Top 5 most-changed files — these are where the team's attention is focused:
1. `path/to/file` — changed N times (reason)
2. ...

### Work Type Distribution
- Features: N commits (X%)
- Fixes: N commits (X%)
- Infrastructure: N commits (X%)
- Docs/Chores: N commits (X%)

### Per-Contributor
| Author | Commits | Lines | Focus Area |
|--------|---------|-------|------------|
| ... | ... | ... | ... |

### Observations
- <Pattern or trend worth noting>
- <Potential concern or risk>

### Suggestions
- <Actionable improvement for next period>
```

### Step 6: Persist

Save the retro for historical tracking:

```bash
mkdir -p .retro/
# Save as JSON for programmatic access
# Save as markdown for human reading
```

## DORA Metrics (if data available)

| Metric | Source | Target |
|--------|--------|--------|
| **Deployment Frequency** | PRs merged to main per week | Daily to weekly |
| **Lead Time for Changes** | Branch creation to PR merge | < 1 day |
| **Mean Time to Recovery** | Incident open to resolved (JIRA) | < 1 hour |
| **Change Failure Rate** | Rollbacks / total deploys | < 15% |

## Anti-Patterns

- **Vanity metrics**: Lines of code doesn't equal productivity. Context matters.
- **Blame**: Retros identify patterns, not problems with individuals.
- **No action items**: Every retro should produce at least one concrete suggestion.
- **Stale retros**: Run them regularly. A monthly retro loses the weekly signal.
- **Missing comparison**: A number without context is meaningless. Always show the trend.

## Integration Points

### With `ship` skill
Ship produces the commits and PRs that retro analyzes.

### With `investigate` skill
Retro can surface recurring incident patterns that investigation should address.

### With JIRA (via MCP)
Pull ticket completion data to correlate with git metrics for a fuller picture.
