# iscagent Specification v0.2.0

## Overview

iscagent is a skills library and repo augmentation framework for AI coding agents. It provides reusable skill modules that teach agents methodologies, patterns, and workflows — plus a pipeline for understanding codebases and generating agent-native CLIs.

Skills are git-native: versioned, diffable, branchable, and reviewable through standard pull request workflows.

Compatible with Claude Code, Cursor, and any agent that reads markdown instructions.

## Required Files

| File | Purpose |
|------|---------|
| `agent.yaml` | Skill registry, model preferences, metadata |

## Optional Directories

| Directory | Purpose |
|-----------|---------|
| `skills/` | Reusable capability modules (SKILL.md + supporting files) |
| `tools/` | MCP-compatible tool schemas |
| `knowledge/` | Reference documents for agent consultation |
| `memory/` | Persistent cross-session state |
| `export/` | Installation scripts and export guides per target tool |

## agent.yaml Schema

```yaml
spec_version: "0.2.0"           # Required
name: my-agent                   # Required — kebab-case identifier
version: 1.0.0                   # Required — semver
description: What this does      # Required
author: team-or-individual       # Optional
license: MIT                     # Optional

model:                           # Optional
  preferred: claude-opus-4-6
  fallback:
    - claude-sonnet-4-6
  constraints:
    temperature: 0.3
    max_tokens: 8192

targets:                         # Optional — tool compatibility
  - claude-code
  - cursor

skills:                          # Required — list of skill directory names
  - coding-standards
  - tdd-workflow
  - repo-augmentation

tools:                           # Optional — list of tool definition names
  - aws-api

runtime:                         # Optional
  max_turns: 50
  timeout: 300

tags:                            # Optional
  - web-development
```

## Skills Directory

Each skill is a subdirectory of `skills/` containing at minimum a `SKILL.md`:

```
skills/
  my-skill/
    SKILL.md          # Skill definition (frontmatter + instructions)
    scripts/           # Optional executable scripts
    examples/          # Optional few-shot examples
    references/        # Optional reference docs
    *.yaml             # Optional supporting config (e.g., custom-registry.yaml)
```

### SKILL.md Frontmatter

```yaml
---
name: my-skill
version: 1.0.0
description: One-line description of what this skill does
author: author-name
tags: [relevant, tags]
tools: [tools-it-needs]
triggers:
  globs: ["**/*.tf", "**/*.tfvars"]
  keywords: [terraform, infrastructure, module]
---
```

### Frontmatter Fields

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `name` | string | Yes | Unique skill identifier (kebab-case) |
| `version` | string | Yes | Semver version |
| `description` | string | Yes | One-line description |
| `author` | string | No | Skill author |
| `tags` | string[] | No | Categorization tags |
| `tools` | string[] | No | External tools the skill needs |
| `triggers.globs` | string[] | No | File patterns that activate this skill |
| `triggers.keywords` | string[] | No | Keywords that suggest relevance |

### Triggers

The `triggers` field makes skills self-describing and discoverable:

- **`triggers.globs`** — File patterns. Maps to Cursor's `.mdc` `globs` frontmatter. Used for file-type-specific activation.
- **`triggers.keywords`** — Task keywords. Used by Claude Code for intelligent skill suggestion and matching against knowledge graphs.

### SKILL.md Body

The body contains the instructions the agent follows. Recommended sections:

```markdown
# Skill Name

## When to Activate
Conditions that trigger this skill.

## Workflow
Step-by-step process the agent should follow.

## Anti-Patterns
Common mistakes to avoid.

## Integration Points
How this skill connects to other skills.
```

## Export Targets

### Claude Code

Skills install to:
- `~/.claude/skills/<skill>/SKILL.md` — user-level (all sessions)
- `.claude/skills/<skill>/SKILL.md` — project-level (one repo)

Use `export/install-skills.sh` for installation.

### Cursor

Skills export as `.cursor/rules/<skill>.mdc` files with frontmatter:

```yaml
---
description: "Skill description for intelligent application"
globs: ["**/*.ts"]      # from triggers.globs
alwaysApply: false
---
```

Cursor rule types:
- **Always Apply** (`alwaysApply: true`) — every session
- **Apply Intelligently** (`alwaysApply: false` + `description`) — agent decides
- **Apply to Specific Files** (`globs`) — file pattern matching
- **Apply Manually** — only when @-mentioned

See `export/cursor.md` for installation instructions.

### AGENTS.md (Framework-agnostic)

For tools that support it, skills can be concatenated into an `AGENTS.md` file at the project root. Subdirectory `AGENTS.md` files provide scoped instructions.

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

All changes go through git:
- Semantic versioning in agent.yaml
- Git tags for releases (v1.0.0)
- PR reviews for skill changes

## Validation

A valid iscagent configuration requires:
1. `agent.yaml` exists with required fields (name, version, description)
2. All skills listed in `agent.yaml` exist in `skills/`
3. Each referenced skill has a `SKILL.md` with valid frontmatter (name, version, description)
4. All referenced tools exist in `tools/`
5. MEMORY.md, if present, is under 200 lines
