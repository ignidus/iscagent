# iscagent

A skills library and repo augmentation pipeline for AI coding agents. Works with **Claude Code**, **Cursor**, and any agent that reads markdown instructions.

## What It Does

**25 reusable skills** that teach agents how to work — from coding standards and TDD to security reviews and API design.

**A repo augmentation pipeline** that scans any codebase, builds a knowledge graph, recommends relevant skills, and generates an agent-native CLI so agents (and humans) can interact with the repo programmatically.

## Quick Start

### Install skills into Claude Code

```bash
git clone https://github.com/ignidus/iscagent.git
cd iscagent
./export/install-skills.sh
```

This installs all 25 skills to `~/.claude/skills/` — available in every Claude Code session.

Install specific skills only:

```bash
./export/install-skills.sh --skills "repo-augmentation,security-review,tdd-workflow"
```

Install into a specific repo:

```bash
./export/install-skills.sh --target /path/to/your-project
```

Other options:

```bash
./export/install-skills.sh --list       # list available skills
./export/install-skills.sh --dry-run    # preview without writing
```

### Install skills into Cursor

Copy skill files as `.mdc` rules:

```bash
mkdir -p /path/to/your-project/.cursor/rules
for skill in skills/*/SKILL.md; do
  name=$(basename $(dirname "$skill"))
  printf -- '---\ndescription: %s\nalwaysApply: false\n---\n' "$name" > "/path/to/your-project/.cursor/rules/${name}.mdc"
  cat "$skill" >> "/path/to/your-project/.cursor/rules/${name}.mdc"
done
```

See [export/cursor.md](export/cursor.md) for details on glob triggers and always-apply rules.

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

### Usage

With skills installed, open Claude Code in any repo and say:

```
"Augment this repo"
```

Or step by step:

```
"Understand this codebase"          # produces .understand/knowledge-graph.json
"Recommend skills for this repo"    # searches catalog, installs matches
"Generate a CLI for this repo"      # produces tools/<cli-name>/
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
2. **[awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)** — 549+ community and vendor skills (searched second)

Add entries to `skills/skill-recommender/custom-registry.yaml` to cover gaps in the external catalog.

## Skills

### Core Workflow
| Skill | What it does |
|-------|-------------|
| `coding-standards` | Code style, organization, naming conventions |
| `tdd-workflow` | Test-driven development process |
| `verification-loop` | Iterative verify-fix cycle for correctness |
| `search-first` | Research existing solutions before writing new code |
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

## Adding Your Own Skills

Create a directory under `skills/` with a `SKILL.md`:

```bash
mkdir -p skills/my-skill
```

```markdown
---
name: my-skill
version: 1.0.0
description: What this skill does
tags: [relevant, tags]
triggers:
  globs: ["**/*.py"]
  keywords: [keyword1, keyword2]
---

# My Skill

## When to Activate
Conditions that trigger this skill.

## Workflow
Step-by-step process the agent should follow.
```

Register it in `agent.yaml`:

```yaml
skills:
  - my-skill
```

Skills follow the [Agent Skills](https://agentskills.io) standard.

## Project Structure

```
iscagent/
  agent.yaml              # Skill registry and model preferences
  skills/                 # 25 reusable skill modules
    coding-standards/
    tdd-workflow/
    security-review/
    codebase-understanding/
    cli-generation/
    repo-augmentation/
    skill-recommender/
      SKILL.md
      custom-registry.yaml
    ...
  export/                 # Installation and export tools
    install-skills.sh     # Install skills to Claude Code or target repos
    claude-code.md        # Claude Code export guide
    cursor.md             # Cursor export guide
  examples/               # Example configurations
    minimal/              # Starter config
  spec/                   # iscagent specification
    SPECIFICATION.md
```

## Export Guides

- **[Claude Code](export/claude-code.md)** — Install to `~/.claude/skills/` or `.claude/skills/`
- **[Cursor](export/cursor.md)** — Export as `.cursor/rules/*.mdc` with frontmatter (globs, description, alwaysApply)

## Credits

- Structure inspired by [gitagent](https://github.com/open-gitagent/gitagent)
- Skills sourced from [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- Repo augmentation methodology extracted from [Understand-Anything](https://github.com/Lum1104/Understand-Anything) and [CLI-Anything](https://github.com/HKUDS/CLI-Anything)
- Skill recommender catalog powered by [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)

## License

MIT
