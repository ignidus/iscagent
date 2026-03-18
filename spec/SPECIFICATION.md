# iscagent Specification v0.1.0

## Overview

iscagent is a portable AI agent definition format targeting **Cursor** and **Claude Code** as runtime environments. It follows the gitagent philosophy — "clone a repo, get an agent" — but scopes the specification to the two tools the team actually uses.

Agent definitions are git-native: versioned, diffable, branchable, and reviewable through standard pull request workflows.

## Required Files

| File | Purpose |
|------|---------|
| `agent.yaml` | Agent manifest (name, version, model, targets, tags) |
| `SOUL.md` | Identity document (personality, values, expertise, style) |

## Optional Files

| File | Purpose |
|------|---------|
| `RULES.md` | Hard constraints and safety boundaries |
| `AGENTS.md` | Framework-agnostic fallback instructions |

## Optional Directories

| Directory | Purpose |
|-----------|---------|
| `skills/` | Reusable capability modules |
| `tools/` | MCP-compatible tool schemas |
| `knowledge/` | Reference documents for agent consultation |
| `memory/` | Persistent cross-session state |
| `hooks/` | Event handlers (bootstrap, teardown) |
| `config/` | Environment-specific overrides |

## agent.yaml Schema

```yaml
spec_version: "0.1.0"           # Required
name: my-agent                   # Required — kebab-case identifier
version: 1.0.0                   # Required — semver
description: What the agent does # Required
author: team-or-individual       # Optional
license: MIT                     # Optional

model:                           # Optional
  preferred: claude-opus-4-6
  fallback:
    - claude-sonnet-4-6
  constraints:
    temperature: 0.3
    max_tokens: 8192

targets:                         # Required — at least one
  - claude-code
  - cursor

skills:                          # Optional — list of skill directory names
  - terraform
  - aws-ops

tools:                           # Optional — list of tool definition names
  - aws-api

runtime:                         # Optional
  max_turns: 50
  timeout: 300

tags:                            # Optional
  - infrastructure
```

## SOUL.md Structure

```markdown
# Soul

## Core Identity
Who the agent is and what it does.

## Communication Style
How it communicates (tone, verbosity, format).

## Values & Principles
What it prioritizes (security, cost, simplicity).

## Domain Expertise
What it knows deeply.

## Collaboration Style
How it works with humans (confirmations, PR style, etc).
```

## RULES.md Structure

```markdown
# Rules

## Must Always
Mandatory behaviors.

## Must Never
Prohibited actions.

## Output Constraints
Formatting and response rules.

## Scope Boundaries
What the agent should not touch.
```

## Skills Directory

Each skill is a subdirectory of `skills/` containing:

```
skills/
  terraform/
    SKILL.md          # Skill definition (frontmatter + instructions)
    scripts/           # Optional executable scripts
    examples/          # Optional few-shot examples
```

### SKILL.md Frontmatter

```yaml
---
name: terraform
version: 1.0.0
description: Terraform infrastructure management
author: iscmga
tags: [terraform, iac, aws]
tools: [terraform-cli]
triggers:
  globs: ["**/*.tf", "**/*.tfvars"]
  keywords: [terraform, infrastructure, module, state]
---
```

### Triggers

The `triggers` field makes skills self-describing and discoverable. It tells both humans and tooling when a skill should activate.

| Field | Type | Purpose |
|-------|------|---------|
| `triggers.globs` | string[] | File patterns that activate this skill (used by Cursor's `.mdc` frontmatter) |
| `triggers.keywords` | string[] | Task keywords that suggest this skill is relevant |

When exporting to Cursor, `triggers.globs` maps directly to the `globs` field in `.mdc` frontmatter. When exporting to Claude Code, `triggers.keywords` can be included in CLAUDE.md as activation hints.

## Tools Directory

MCP-compatible tool definitions:

```
tools/
  aws-api/
    tool.yaml         # Tool schema
    README.md          # Usage documentation
```

## Export Targets

### Claude Code

Exports to:
- `.claude/CLAUDE.md` — merged from SOUL.md + RULES.md + skill instructions
- `.claude/settings.json` — permissions derived from tools and rules
- `.claude/commands/` — skills exported as slash commands

### Cursor

Exports to:
- `.cursor/rules/` — rule files derived from SOUL.md + RULES.md
- `.cursor/rules/soul.mdc` — identity and behavior
- `.cursor/rules/rules.mdc` — constraints and boundaries
- `.cursor/rules/{skill}.mdc` — one file per skill

## Memory

```
memory/
  MEMORY.md           # Persistent notes (max 200 lines, auto-loaded)
  archive/            # Overflow storage linked from MEMORY.md
```

Memory files persist across conversations. Agents should:
- Check memory before starting work
- Update memory with confirmed patterns and decisions
- Keep MEMORY.md concise; use archive files for details

## Versioning

All changes to agent definitions go through git:
- Semantic versioning in agent.yaml
- Git tags for releases (v1.0.0)
- Branch-based promotion (dev → staging → main)
- PR reviews for identity/rule changes

## Validation

An agent definition is valid when:
1. `agent.yaml` exists and has required fields
2. `SOUL.md` exists and is non-empty
3. At least one target is specified
4. All referenced skills exist in `skills/`
5. All referenced tools exist in `tools/`
6. MEMORY.md is under 200 lines
