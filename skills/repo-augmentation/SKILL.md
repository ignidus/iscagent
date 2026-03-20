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

## Pipeline

```
PHASE 1: UNDERSTAND          PHASE 2: DOCUMENT           PHASE 3: EQUIP              PHASE 4: CONFIGURE
─────────────────            ────────────────             ──────────────              ──────────────────
Scan the codebase            Generate docs/               Install skills              Configure BOTH:
Build knowledge graph        Architecture overview         Select based on             Claude Code + Cursor
Map architecture             Onboarding guide              codebase signals            Project-specific
Generate guided tour         Agent reference               Engineering workflow        instructions

.understand/                 docs/                        .claude/skills/             CLAUDE.md
  knowledge-graph.json         README.md                  .cursor/rules/              .cursor/rules/
                               architecture.md              (both targets)              project.mdc
                               onboarding.md
                               AGENTS.md
                               modules/

PHASE 5: VALIDATE            PHASE 6: COMMIT
──────────────────           ───────────────
Verify all artifacts         Create feature branch
Test dev commands            Commit all artifacts
Check completeness           feature/iscagent-augmentation
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

### Install to BOTH Targets

Always install skills for both Claude Code and Cursor so developers can use either tool:

**Claude Code** — one directory per skill:
```
<repo>/.claude/skills/<skill-name>/SKILL.md
```

**Cursor** — one `.mdc` file per skill with frontmatter:
```
<repo>/.cursor/rules/<skill-name>.mdc
```

For each Cursor rule file, wrap the SKILL.md content with frontmatter:
```yaml
---
description: "<skill description from SKILL.md frontmatter>"
globs: <from skill triggers.globs, or omit if empty>
alwaysApply: false
---
<SKILL.md body contents>
```

### How to Install

Copy skill files from the iscagent source. If iscagent is cloned locally:
```bash
# Claude Code
mkdir -p <repo>/.claude/skills/<skill-name>
cp <iscagent>/skills/<skill-name>/SKILL.md <repo>/.claude/skills/<skill-name>/SKILL.md

# Cursor
mkdir -p <repo>/.cursor/rules
printf -- '---\ndescription: %s\nalwaysApply: false\n---\n' "<description>" > <repo>/.cursor/rules/<skill-name>.mdc
cat <iscagent>/skills/<skill-name>/SKILL.md >> <repo>/.cursor/rules/<skill-name>.mdc
```

If not available locally, write the skill content directly based on the skill definitions in this repository.

## Phase 4: Configure Project Instructions

Generate project-specific instruction files for **both** Claude Code and Cursor. Developers use both tools — the repo should be ready for either.

### 4a: Generate `CLAUDE.md`

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

### 4b: Generate `.cursor/rules/project.mdc`

Create the Cursor equivalent with the same content wrapped in frontmatter:

```yaml
---
description: "Project-specific rules for <project name>"
alwaysApply: true
---
```

The body content is the same as the CLAUDE.md above. Both files must stay in sync — they describe the same project.

## Phase 5: Validate

Run a validation pass on everything generated:

- [ ] `.understand/knowledge-graph.json` exists and is valid JSON
- [ ] `docs/README.md` exists and has content
- [ ] `docs/AGENTS.md` exists and lists all files from the knowledge graph
- [ ] `.claude/skills/` has SKILL.md files for each installed skill
- [ ] `.cursor/rules/` has `.mdc` files for each installed skill
- [ ] `CLAUDE.md` exists with project-specific config
- [ ] `.cursor/rules/project.mdc` exists with project-specific config
- [ ] Development commands in the config files are accurate (test at least one)
- [ ] No broken internal links in docs

## Phase 6: Commit to Feature Branch

Create a feature branch, stage all artifacts, and commit automatically:

```bash
# Create feature branch from current branch
git checkout -b feature/iscagent-augmentation

# Stage all augmentation artifacts
git add .understand/
git add docs/
git add .claude/skills/
git add .cursor/rules/
git add CLAUDE.md

# Commit
git commit -m "feat: augment repo for AI-assisted development

Adds:
- .understand/knowledge-graph.json (codebase understanding)
- docs/ (architecture, onboarding, agent reference)
- .claude/skills/ (N skills for Claude Code)
- .cursor/rules/ (N rules for Cursor)
- CLAUDE.md (project configuration for Claude Code)
- .cursor/rules/project.mdc (project configuration for Cursor)

Generated by iscagent repo-augmentation v2.0"
```

After committing, report what was done:

```
AUGMENTATION COMPLETE

Branch: feature/iscagent-augmentation
Commit: <hash>

Artifacts:
  .understand/knowledge-graph.json    — Codebase understanding
  docs/                               — N documentation files
  .claude/skills/                     — N skills (Claude Code)
  .cursor/rules/                      — N rules (Cursor)
  CLAUDE.md                           — Project config (Claude Code)
  .cursor/rules/project.mdc           — Project config (Cursor)

Next steps:
  git push -u origin feature/iscagent-augmentation
  # Then create a PR for review
```

## Full Example

```
User: "Augment this repo"

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

Phase 3 — EQUIP (12 skills × 2 targets)
  Always: coding-standards, review, ship, careful, verification-loop, security-review
  Detected: tdd-workflow (phpunit found), database-migrations (migrations/ dir),
            api-design (routes/ dir), frontend-patterns (Vue components),
            backend-patterns (Laravel), postgres-patterns (Eloquent)
  Installed to: .claude/skills/ (12 skills) + .cursor/rules/ (12 rules)

Phase 4 — CONFIGURE
  CLAUDE.md ✓ (test: php artisan test, lint: ./vendor/bin/pint, dev: php artisan serve)
  .cursor/rules/project.mdc ✓

Phase 5 — VALIDATE
  All checks pass ✓

Phase 6 — COMMIT
  Branch: feature/iscagent-augmentation
  Commit: abc1234 "feat: augment repo for AI-assisted development"
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
- **Only configuring one tool**: Always generate for both Claude Code and Cursor. Developers switch between tools — the repo should be ready for either.

## Integration Points

### With all engineering workflow skills
This skill installs and configures `review`, `ship`, `investigate`, `careful`, `retro`, and `plan-review`. The CLAUDE.md it generates tells the agent when and how to use each one.

### With `codebase-understanding` skill
Phase 1 invokes this skill to build the knowledge graph.

### With `docs-generation` skill
Phase 2 invokes this skill to generate documentation.

### With `project-guidelines-example` skill
Use as a reference for what a good CLAUDE.md looks like. The generated config should be at least as detailed.
