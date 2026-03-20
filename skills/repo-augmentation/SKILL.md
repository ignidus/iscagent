---
name: repo-augmentation
version: 2.0.0
description: End-to-end pipeline to augment any repository for AI-assisted development. Installs opinionated engineering workflows, generates documentation, and configures Claude Code or Cursor.
author: iscmga
tags: [repo-augmentation, onboarding, agent-native, automation, pipeline, claude-code, cursor]
triggers:
  globs: []
  keywords: [augment repo, augment repository, make repo agent-native, repo augmentation, set up repo, onboard repo]
---

# Repo Augmentation

Take any repository and make it fully agent-ready. This skill orchestrates the entire process: understand the codebase, generate documentation, install opinionated engineering workflows, and configure the target tool (Claude Code or Cursor).

When you're done, an agent opening the repo will have everything it needs — project context, architectural understanding, coding standards, review workflows, release pipelines, safety guardrails, and investigation playbooks — all configured and ready to use.

## When to Activate

- "Augment this repo"
- "Set up this repo for Claude Code"
- "Make this repo agent-native"
- "Onboard this codebase"
- When preparing any repo for AI-assisted development

## Target Tool Detection

Determine the target tool by checking what exists:

| Signal | Target |
|--------|--------|
| `.claude/` directory exists or user says "Claude" | Claude Code |
| `.cursor/` directory exists or user says "Cursor" | Cursor |
| Both exist | Ask user which to configure |
| Neither exists | Default to Claude Code |

## Pipeline

```
PHASE 1: UNDERSTAND          PHASE 2: DOCUMENT           PHASE 3: EQUIP              PHASE 4: CONFIGURE
─────────────────            ────────────────             ──────────────              ──────────────────
Scan the codebase            Generate docs/               Install skills              Write CLAUDE.md or
Build knowledge graph        Architecture overview         Select based on             Cursor rules
Map architecture             Onboarding guide              codebase signals            Project-specific
Generate guided tour         Agent reference               Engineering workflow        instructions

.understand/                 docs/                        .claude/skills/ OR          CLAUDE.md OR
  knowledge-graph.json         README.md                    .cursor/rules/              .cursor/rules/
                               architecture.md                                          project.mdc
                               onboarding.md
                               AGENTS.md
                               modules/
```

## Phase 1: Understand the Codebase

Follow the `codebase-understanding` skill exactly.

1. **Scan** all source files — detect languages, frameworks, entry points
2. **Analyze** in batches — extract functions, classes, imports, write summaries
3. **Assemble** into a unified knowledge graph with referential integrity
4. **Map architecture** into 3-7 layers (API, Service, Data, Config, etc.)
5. **Generate tour** — 10-15 steps from entry points outward

**Output:** `.understand/knowledge-graph.json`

**Skip if:** the knowledge graph already exists and `metadata.gitCommitHash` matches `HEAD`.

## Phase 2: Generate Documentation

Follow the `docs-generation` skill exactly.

Using the knowledge graph, generate:

- `docs/README.md` — project overview, tech stack, table of contents
- `docs/architecture.md` — layers, dependency flow, design decisions
- `docs/modules/<layer>.md` — one per architectural layer
- `docs/onboarding.md` — guided tour as narrative prose
- `docs/AGENTS.md` — structured reference optimized for LLM consumption

Optionally, follow `knowledge-graph-visualizer` to add Mermaid diagrams to `docs/diagrams/`.

**Skip if:** `docs/README.md` exists and its commit hash matches `HEAD`.

## Phase 3: Install Skills

Select and install skills based on what the codebase actually needs. Read the knowledge graph signals and match:

### Always Install (every repo benefits)
- `coding-standards` — code style and conventions
- `review` — structured PR review
- `ship` — release pipeline
- `careful` — destructive command guardrails
- `verification-loop` — iterative verify-fix cycle
- `security-review` — security analysis

### Install If Detected

| Signal | Skills to Install |
|--------|-------------------|
| Test files exist (`test/`, `spec/`, `__tests__/`) | `tdd-workflow` |
| Database layer (SQL, ORM, migrations) | `database-migrations`, `postgres-patterns` |
| API layer (routes, controllers, endpoints) | `api-design` |
| Frontend layer (React, Vue, Angular, templates) | `frontend-patterns` |
| Backend layer (Express, Django, Laravel, Go) | `backend-patterns` |
| Docker/container files | `docker-patterns` |
| CI/CD config (`.github/workflows/`, Jenkinsfile) | `deployment-patterns` |
| Infrastructure code (Terraform, CloudFormation) | `careful` (with infra-specific patterns), `plan-review` |
| Complex architecture (>100 files, >5 layers) | `investigate`, `plan-review`, `retro` |
| MCP server code | `mcp-server-patterns` |

### Install Location

**Claude Code:**
```
<repo>/.claude/skills/<skill-name>/SKILL.md
```

**Cursor:**
```
<repo>/.cursor/rules/<skill-name>.mdc
```

For Cursor, wrap each SKILL.md with frontmatter:
```yaml
---
description: "<skill description>"
globs: <from skill triggers.globs, or omit>
alwaysApply: false
---
<SKILL.md contents>
```

### How to Install

Copy skill files from the iscagent source. If iscagent is cloned locally:
```bash
cp -r <iscagent>/skills/<skill-name>/SKILL.md <repo>/.claude/skills/<skill-name>/SKILL.md
```

If not available locally, write the skill content directly based on the skill definitions in this repository.

## Phase 4: Configure Project Instructions

Generate a project-specific instruction file that tells the agent everything it needs to know about THIS repo.

### For Claude Code: Generate `CLAUDE.md`

Create `<repo>/CLAUDE.md` at the project root:

```markdown
# <Project Name>

## Overview
<2-3 sentences from knowledge graph metadata — what this project does, primary language, framework>

## Tech Stack
- **Languages:** <from metadata.languages>
- **Frameworks:** <from metadata.frameworks>
- **Database:** <from metadata.database>
- **Infrastructure:** <detected from file patterns>

## Architecture
<Brief layer summary from knowledge graph — e.g. "4-layer architecture: API → Service → Data → Config">

## Development Commands
<Detect from Makefile, package.json, composer.json, Pipfile, go.mod, etc.>

| Command | What it does |
|---------|-------------|
| `<test command>` | Run tests |
| `<lint command>` | Run linter |
| `<build command>` | Build the project |
| `<dev command>` | Start development server |

## Coding Standards
- <Inferred from existing code patterns: indentation, naming conventions, file organization>
- <Framework-specific conventions detected>

## Engineering Workflow
- **Before making changes:** Run `plan-review` for changes touching >3 files
- **During development:** Follow `coding-standards` and `tdd-workflow`
- **Before committing:** Run `review` on your changes
- **To release:** Use `ship` for automated test → review → PR pipeline
- **For incidents:** Use `investigate` for systematic root-cause analysis
- **Safety:** `careful` mode is active — destructive commands require confirmation
- **Retrospectives:** Run `retro` for weekly velocity and quality insights

## Project-Specific Rules
<Any patterns detected that are specific to this codebase:>
- <Import conventions>
- <Test file naming patterns>
- <Environment configuration approach>
- <Deployment targets>
```

### For Cursor: Generate `.cursor/rules/project.mdc`

```yaml
---
description: "Project-specific rules for <project name>"
alwaysApply: true
---
<Same content as CLAUDE.md above, adapted for Cursor context>
```

## Phase 5: Validate

Run a validation pass on everything generated:

- [ ] `.understand/knowledge-graph.json` exists and is valid JSON
- [ ] `docs/README.md` exists and has content
- [ ] `docs/AGENTS.md` exists and lists all files from the knowledge graph
- [ ] Skills are installed in the correct location for the target tool
- [ ] Each installed skill has a valid SKILL.md with frontmatter
- [ ] `CLAUDE.md` or `.cursor/rules/project.mdc` exists with project-specific config
- [ ] Development commands in the config file are accurate (test at least one)
- [ ] No broken internal links in docs

## Phase 6: Commit

Stage all artifacts and present to the user:

```
Artifacts generated:
  .understand/knowledge-graph.json    — Codebase understanding
  docs/                               — Human + agent documentation (N files)
  .claude/skills/ OR .cursor/rules/   — N skills installed
  CLAUDE.md OR .cursor/rules/project.mdc — Project configuration

Ready to commit. Suggested message:
  "feat: augment repo for AI-assisted development"
```

Wait for user confirmation before committing.

## Full Example

```
User: "Augment this repo for Claude Code"

Phase 1 — UNDERSTAND
  Scanning 142 files...
  Languages: PHP, JavaScript
  Frameworks: Laravel, Vue.js, Tailwind
  Database: MySQL (via Eloquent ORM)
  Architecture: 5 layers — API, Service, Data, UI, Config
  Knowledge graph: .understand/knowledge-graph.json ✓

Phase 2 — DOCUMENT
  docs/README.md ✓
  docs/architecture.md ✓
  docs/modules/api.md ✓
  docs/modules/service.md ✓
  docs/modules/data.md ✓
  docs/modules/ui.md ✓
  docs/modules/config.md ✓
  docs/onboarding.md ✓
  docs/AGENTS.md ✓

Phase 3 — EQUIP (12 skills)
  Always: coding-standards, review, ship, careful, verification-loop, security-review
  Detected: tdd-workflow (phpunit found), database-migrations (migrations/ dir),
            api-design (routes/ dir), frontend-patterns (Vue components),
            backend-patterns (Laravel), postgres-patterns (Eloquent)

Phase 4 — CONFIGURE
  CLAUDE.md ✓ (test: php artisan test, lint: ./vendor/bin/pint, dev: php artisan serve)

Phase 5 — VALIDATE
  All checks pass ✓

Ready to commit.
```

## Execution Strategy

| Repo Size | Approach |
|-----------|----------|
| Small (<50 files) | Run all phases sequentially in main context |
| Medium (50-200 files) | Use subagent for Phase 1 (understand), main for rest |
| Large (200+ files) | Parallel subagents for scanning + analysis, main for assembly + config |

## Anti-Patterns

- **Installing every skill**: Only install what the codebase signals require. A Go CLI tool doesn't need `frontend-patterns`.
- **Generic CLAUDE.md**: The config file must be specific to THIS repo — actual commands, actual conventions, actual architecture.
- **Skipping validation**: Always verify that installed skills have valid SKILL.md files and that development commands actually work.
- **Augmenting without understanding**: Don't install skills or write config without first building the knowledge graph. You'll miss what the repo actually needs.
- **One config for both tools**: Claude Code and Cursor have different formats. Generate the right one for the target tool.

## Integration Points

### With all engineering workflow skills
This skill installs and configures `review`, `ship`, `investigate`, `careful`, `retro`, and `plan-review`. The CLAUDE.md it generates tells the agent when and how to use each one.

### With `codebase-understanding` skill
Phase 1 invokes this skill to build the knowledge graph.

### With `docs-generation` skill
Phase 2 invokes this skill to generate documentation.

### With `project-guidelines-example` skill
Use as a reference for what a good CLAUDE.md looks like. The generated config should be at least as detailed.
