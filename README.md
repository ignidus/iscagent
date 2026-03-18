# iscagent

Portable AI agent definitions for **Cursor** and **Claude Code**.

Inspired by [gitagent](https://github.com/open-gitagent/gitagent) — adapted to target the two AI coding tools the team uses daily. Clone a repo, get an agent.

## Why

AI coding assistants are powerful but their configuration is scattered across tool-specific formats:
- Claude Code uses `.claude/CLAUDE.md` and settings.json
- Cursor uses `.cursor/rules/*.mdc` files

iscagent provides a **single source of truth** for agent identity, rules, and skills that exports to both formats. Changes are versioned in git, reviewed via PRs, and shared across the team.

## Quick Start

```
iscagent/
  agent.yaml          # Agent manifest (required)
  SOUL.md             # Identity & personality (required)
  RULES.md            # Hard constraints
  skills/
    terraform/SKILL.md
    aws-ops/SKILL.md
    ci-cd/SKILL.md
```

### Required Files

| File | Purpose |
|------|---------|
| `agent.yaml` | Name, version, model preferences, target runtimes |
| `SOUL.md` | Who the agent is — identity, values, expertise, style |

### Optional Files

| File/Dir | Purpose |
|----------|---------|
| `RULES.md` | Must-always, must-never, output constraints |
| `skills/` | Reusable capability modules with trigger conditions |
| `tools/` | MCP-compatible tool schemas |
| `knowledge/` | Reference documents for agent context |
| `memory/` | Persistent cross-session state |

## Export Targets

### Claude Code

Generates `.claude/CLAUDE.md` by merging SOUL + RULES + skills into a single project instructions file. Skills can also export as `.claude/commands/` slash commands.

See [export/claude-code.md](export/claude-code.md) for details.

### Cursor

Generates `.cursor/rules/*.mdc` files with appropriate frontmatter:
- `soul.mdc` — always active, identity and values
- `rules.mdc` — always active, hard constraints
- `{skill}.mdc` — activated by file glob patterns

See [export/cursor.md](export/cursor.md) for details.

## agent.yaml

```yaml
spec_version: "0.1.0"
name: infra-agent
version: 1.0.0
description: Infrastructure management agent
author: iscmga

model:
  preferred: claude-opus-4-6
  fallback: [claude-sonnet-4-6]
  constraints:
    temperature: 0.2

targets:
  - claude-code
  - cursor

skills:
  - terraform
  - aws-ops

tags:
  - infrastructure
  - devops
```

## SOUL.md

Defines who the agent is:

```markdown
# Soul

## Core Identity
What the agent does.

## Communication Style
How it talks (direct, concise, technical).

## Values & Principles
What it prioritizes (security, cost, simplicity).

## Domain Expertise
What it knows deeply.

## Collaboration Style
How it works with humans.
```

## RULES.md

Defines hard boundaries:

```markdown
# Rules

## Must Always
- Read before edit
- Confirm before destroy

## Must Never
- Commit secrets
- Force push to main

## Output Constraints
- Use file_path:line_number references
- One sentence where possible

## Scope Boundaries
- Only workspace and configured accounts
```

## Skills

Each skill is a directory under `skills/` with a `SKILL.md`:

```yaml
---
name: terraform
version: 1.0.0
description: Terraform infrastructure management
tags: [terraform, iac, aws]
tools: [terraform-cli]
---

# Terraform Skill

## Trigger
When to activate this skill.

## Workflow
Step-by-step process.

## Conventions
Team-specific patterns and standards.
```

## Examples

| Example | Description |
|---------|-------------|
| [minimal](examples/minimal/) | Two-file hello world (agent.yaml + SOUL.md) |
| [infrastructure](examples/infrastructure/) | Full infra agent with skills and rules |

## Patterns

Borrowed from gitagent, applicable to iscagent:

- **Agent Versioning** — semver in agent.yaml, git tags for releases
- **Branch Deployment** — dev/staging/main promotion for agent changes
- **Shared Context** — root-level skills/tools shared across sub-agents
- **PR Reviews for Identity** — SOUL.md and RULES.md changes require review
- **Memory Persistence** — cross-session learning in memory/MEMORY.md

## Specification

Full spec at [spec/SPECIFICATION.md](spec/SPECIFICATION.md).

## License

MIT
