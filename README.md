# iscagent

Portable AI agent definitions for **Cursor** and **Claude Code**.

Inspired by [gitagent](https://github.com/open-gitagent/gitagent), with skills sourced from [everything-claude-code](https://github.com/affaan-m/everything-claude-code). Clone a repo, get an agent.

## Why

AI coding assistants are powerful but their configuration is scattered across tool-specific formats:
- Claude Code uses `.claude/CLAUDE.md` and settings.json
- Cursor uses `.cursor/rules/*.mdc` files

iscagent provides a **single source of truth** for agent identity, rules, and skills that exports to both formats. Changes are versioned in git, reviewed via PRs, and shared across the team.

## How to Use

### 1. Fork or clone this repo

```bash
git clone https://github.com/ignidus/iscagent.git
cd iscagent
```

### 2. Customize for your project

- Edit `SOUL.md` to define your agent's identity and expertise
- Edit `RULES.md` to set your team's constraints and boundaries
- Edit `agent.yaml` to pick which skills apply to your project

### 3. Pick the skills you need

The repo ships with 25 skills. Remove what you don't need, keep what you do:

```yaml
# agent.yaml — only list skills relevant to your project
skills:
  - coding-standards
  - tdd-workflow
  - security-review
  - api-design
  - docker-patterns
```

### 4. Add your own skills

Create a new directory under `skills/` with a `SKILL.md`:

```bash
mkdir -p skills/my-custom-skill
```

```markdown
---
name: my-custom-skill
version: 1.0.0
description: What this skill does
tags: [relevant, tags]
---

# My Custom Skill

## Trigger
When to activate (file types, task types, keywords).

## Workflow
Step-by-step process the agent should follow.

## Conventions
Team-specific patterns, naming standards, etc.
```

### 5. Export to your tool

#### Claude Code

Assemble skills into `.claude/CLAUDE.md` for your target project:

```bash
# Concatenate soul + rules + selected skills
cat SOUL.md > /path/to/your-project/.claude/CLAUDE.md
echo -e "\n---\n" >> /path/to/your-project/.claude/CLAUDE.md
cat RULES.md >> /path/to/your-project/.claude/CLAUDE.md
for skill in skills/coding-standards skills/tdd-workflow skills/security-review; do
  echo -e "\n---\n" >> /path/to/your-project/.claude/CLAUDE.md
  cat "$skill/SKILL.md" >> /path/to/your-project/.claude/CLAUDE.md
done
```

See [export/claude-code.md](export/claude-code.md) for full details.

#### Cursor

Generate `.cursor/rules/*.mdc` files with frontmatter:

```bash
mkdir -p /path/to/your-project/.cursor/rules

# Soul — always active
printf -- '---\ndescription: Agent identity and values\nalwaysApply: true\n---\n' > /path/to/your-project/.cursor/rules/soul.mdc
cat SOUL.md >> /path/to/your-project/.cursor/rules/soul.mdc

# Rules — always active
printf -- '---\ndescription: Hard constraints and boundaries\nalwaysApply: true\n---\n' > /path/to/your-project/.cursor/rules/rules.mdc
cat RULES.md >> /path/to/your-project/.cursor/rules/rules.mdc

# Skills — triggered by file type
printf -- '---\ndescription: TDD workflow\nglobs: ["**/*.test.*", "**/*.spec.*"]\nalwaysApply: false\n---\n' > /path/to/your-project/.cursor/rules/tdd-workflow.mdc
cat skills/tdd-workflow/SKILL.md >> /path/to/your-project/.cursor/rules/tdd-workflow.mdc
```

See [export/cursor.md](export/cursor.md) for full details.

#### Install skills directly

Install all iscagent skills to your user-level Claude Code skills directory:

```bash
./export/install-skills.sh
```

Or install specific skills to a target repo:

```bash
./export/install-skills.sh --skills "repo-augmentation,skill-recommender" --target /path/to/repo
```

Other options:

```bash
./export/install-skills.sh --list       # list available skills
./export/install-skills.sh --dry-run    # preview without writing
```

## Repo Augmentation

The augmentation pipeline makes any repo agent-native in three stages:

```
STAGE 1: UNDERSTAND              STAGE 1.5: EQUIP              STAGE 2: GENERATE
(codebase-understanding)         (skill-recommender)            (cli-generation)

 Scan files                       Read knowledge graph           Analyze knowledge graph
 Analyze structure  ────>         Match signals to catalog       Design CLI commands
 Map architecture                 Recommend skills               Implement CLI
 Generate tour                    Fetch & install matched        Test & document

 .understand/                     .claude/skills/                tools/<cli-name>/
   knowledge-graph.json             (relevant skills)              (agent-native CLI)
```

To augment a repo, install the skills and then tell Claude Code:

```
"Augment this repo"
```

Or step by step:

```
"Understand this codebase"          # produces knowledge graph
"Recommend skills for this repo"    # searches catalog, installs matches
"Generate a CLI for this repo"      # produces CLI in tools/
```

### Batch augmentation

```bash
for repo in ~/repos/project-a ~/repos/project-b; do
  ./export/install-skills.sh --target "$repo"
  claude -p "augment this repo" --cwd "$repo"
done
```

### Custom skill registry

The skill recommender searches two sources:
1. **`custom-registry.yaml`** — hand-curated skills with precise match signals (searched first)
2. **[awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)** — 549+ community catalog (searched second)

Add entries to `skills/skill-recommender/custom-registry.yaml` to cover gaps in the external catalog.

## Included Skills

### Core Workflow
| Skill | What it does |
|-------|-------------|
| `coding-standards` | Code style, organization, naming conventions |
| `tdd-workflow` | Test-driven development process |
| `verification-loop` | Iterative verify-fix cycle for correctness |
| `search-first` | Research existing code before writing new code |
| `strategic-compact` | Context window management for long sessions |
| `eval-harness` | Evaluate and benchmark agent outputs |
| `project-guidelines-example` | Template for project-specific rules |

### Security
| Skill | What it does |
|-------|-------------|
| `security-review` | OWASP, cloud infrastructure, vulnerability analysis |
| `security-scan` | Automated security scanning integration |

### Development Patterns
| Skill | What it does |
|-------|-------------|
| `api-design` | REST/GraphQL API design patterns |
| `backend-patterns` | Server-side architecture patterns |
| `frontend-patterns` | UI component and state patterns |
| `database-migrations` | Schema migration workflows |
| `docker-patterns` | Containerization best practices |
| `deployment-patterns` | CI/CD and release strategies |
| `postgres-patterns` | PostgreSQL query and schema patterns |

### AI & Agent Tooling
| Skill | What it does |
|-------|-------------|
| `deep-research` | Multi-source research workflows |
| `mcp-server-patterns` | Model Context Protocol server patterns |

### Repo Augmentation
| Skill | What it does |
|-------|-------------|
| `codebase-understanding` | Build a knowledge graph from any codebase — scan, analyze, map architecture, generate guided tours |
| `cli-generation` | Generate stateful, agent-native CLIs with dual output (human + JSON), backend bridging, session management |
| `repo-augmentation` | End-to-end pipeline: understand a codebase → equip with skills → generate a CLI |
| `skill-recommender` | Analyze a knowledge graph and recommend relevant skills from a custom registry + the [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) catalog |

### Multi-Agent Coordination
| Skill | What it does |
|-------|-------------|
| `agent-coordination` | Memory-based agent communication protocol — how agents hand off work through shared files |
| `agent-teams` | Team composition templates per task type (bug fix, feature, refactor, security audit, infra change) |
| `model-routing` | Decision framework for selecting the right model (Haiku/Sonnet/Opus) per task complexity |

## Project Structure

```
iscagent/
  agent.yaml              # Agent manifest (required)
  SOUL.md                 # Identity & personality (required)
  RULES.md                # Hard constraints
  skills/                 # Reusable capability modules (25 skills)
    coding-standards/
    tdd-workflow/
    security-review/
    codebase-understanding/   # Knowledge graph from any codebase
    cli-generation/           # Agent-native CLI generation
    repo-augmentation/        # End-to-end augmentation pipeline
    skill-recommender/        # Catalog-aware skill recommendation
      SKILL.md
      custom-registry.yaml    # Custom skill registry
    ...
  export/                 # Export tools per target
    claude-code.md
    cursor.md
    install-skills.sh     # Install skills to Claude Code
  examples/               # Example agent definitions
    minimal/              # Two-file hello world
    infrastructure/       # Full infra agent
  spec/                   # iscagent specification
    SPECIFICATION.md
```

## Required Files

| File | Purpose |
|------|---------|
| `agent.yaml` | Name, version, model preferences, target runtimes, skill list |
| `SOUL.md` | Who the agent is — identity, values, expertise, communication style |

## Optional Files

| File/Dir | Purpose |
|----------|---------|
| `RULES.md` | Must-always, must-never, output constraints, scope boundaries |
| `skills/` | Reusable capability modules with trigger conditions |
| `tools/` | MCP-compatible tool schemas |
| `knowledge/` | Reference documents for agent context |
| `memory/` | Persistent cross-session state |

## Creating Your Own Skills

Skills follow the [Agent Skills](https://agentskills.io) standard. Each skill is a directory with at minimum a `SKILL.md` file:

```
skills/
  my-skill/
    SKILL.md          # Skill definition (frontmatter + instructions)
    scripts/           # Optional helper scripts
    examples/          # Optional few-shot examples
    references/        # Optional reference docs
```

The `SKILL.md` frontmatter declares metadata:

```yaml
---
name: my-skill
version: 1.0.0
description: One-line description
author: your-name
tags: [relevant, tags]
tools: [tools-it-needs]
---
```

The body contains the instructions the agent follows when the skill is active.

## Patterns

- **Agent Versioning** — semver in agent.yaml, git tags for releases
- **Branch Deployment** — dev/staging/main promotion for agent changes
- **Shared Context** — root-level skills/tools shared across sub-agents
- **PR Reviews for Identity** — SOUL.md and RULES.md changes require review
- **Memory Persistence** — cross-session learning in memory/MEMORY.md
- **Skill Composition** — combine multiple skills for different project types

## Specification

Full spec at [spec/SPECIFICATION.md](spec/SPECIFICATION.md).

## Credits

- Structure inspired by [gitagent](https://github.com/open-gitagent/gitagent)
- Skills sourced from [everything-claude-code](https://github.com/affaan-m/everything-claude-code)

## License

MIT
