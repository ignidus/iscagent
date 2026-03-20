# iscagent

Opinionated engineering workflow skills for AI coding agents. Load iscagent into Claude Code or Cursor, point it at any repository, and it will augment that repo with structured workflows, documentation, and project-specific configuration — ready for AI-assisted development.

## How It Works

1. **Install iscagent skills** into Claude Code or Cursor
2. **Tell Claude to augment a repo** — it reads the codebase, generates docs, installs the right skills, and writes project-specific config
3. **The repo is now agent-ready** — any agent opening it gets architecture context, coding standards, review workflows, release pipelines, safety guardrails, and investigation playbooks

```
YOU                          CLAUDE + ISCAGENT                    TARGET REPO
───                          ─────────────────                    ───────────
"Augment this repo"  ──>     Phase 1: Understand codebase   ──>  .understand/knowledge-graph.json
                             Phase 2: Generate docs          ──>  docs/ (architecture, onboarding, agent ref)
                             Phase 3: Install skills         ──>  .claude/skills/ + .cursor/rules/
                             Phase 4: Write project config   ──>  CLAUDE.md + .cursor/rules/project.mdc
                             Phase 5: Validate               ──>  verify all artifacts
                             Phase 6: Commit                 ──>  feature/iscagent-augmentation branch
```

The output is a repo where Claude (or Cursor) knows:
- What the project does and how it's architected
- What commands to run (test, lint, build, dev server)
- How to review PRs, ship releases, investigate incidents
- What operations are dangerous and need confirmation
- What coding standards and patterns to follow

## Quick Start

### Install into Claude Code

```bash
git clone https://github.com/ignidus/iscagent.git
cd iscagent
./export/install-skills.sh
```

Installs all 32 skills to `~/.claude/skills/` — available in every Claude Code session.

Then open any repo in Claude Code and say:

```
"Augment this repo"
```

### Install into Cursor

```bash
mkdir -p /path/to/your-project/.cursor/rules
for skill in skills/*/SKILL.md; do
  name=$(basename $(dirname "$skill"))
  printf -- '---\ndescription: %s\nalwaysApply: false\n---\n' "$name" > "/path/to/your-project/.cursor/rules/${name}.mdc"
  cat "$skill" >> "/path/to/your-project/.cursor/rules/${name}.mdc"
done
```

### Install specific skills only

```bash
./export/install-skills.sh --skills "review,ship,investigate,careful"
./export/install-skills.sh --target /path/to/your-project
./export/install-skills.sh --list       # list available skills
./export/install-skills.sh --dry-run    # preview without writing
```

## What Gets Installed

### Engineering Workflow (the core value)

These skills give Claude an opinionated, structured process for every phase of development:

| Skill | What it does | When Claude uses it |
|-------|-------------|---------------------|
| `review` | Evidence-based PR review with auto-fix classification and scope drift detection | Before merging any changes |
| `ship` | Automated release pipeline — test, review, version, changelog, PR | When shipping changes |
| `investigate` | Systematic root-cause debugging — no fixes without understanding first | When something breaks |
| `careful` | Safety guardrails — warns before terraform destroy, aws delete, git force-push | Always active in production contexts |
| `retro` | Git-based velocity analytics, DORA metrics, trend comparison | End of sprint / week |
| `plan-review` | Architecture review — failure modes, scope, test strategy | Before complex changes |

### Core Workflow

| Skill | What it does |
|-------|-------------|
| `coding-standards` | Code style, organization, naming conventions |
| `tdd-workflow` | Test-driven development process |
| `verification-loop` | Iterative verify-fix cycle for correctness |
| `search-first` | Research existing solutions before writing new code |
| `strategic-compact` | Context window management for long sessions |
| `eval-harness` | Evaluate and benchmark agent outputs |
| `project-guidelines-example` | Template for project-specific CLAUDE.md |

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

### Repo Augmentation (the orchestration layer)

| Skill | What it does |
|-------|-------------|
| `repo-augmentation` | Master orchestrator — runs the full augmentation pipeline |
| `codebase-understanding` | Build a knowledge graph from any codebase |
| `docs-generation` | Transform knowledge graph into docs/ folder |
| `knowledge-graph-visualizer` | Generate Mermaid architecture diagrams |
| `cli-generation` | Generate agent-native CLIs for complex codebases |

### Multi-Agent Coordination

| Skill | What it does |
|-------|-------------|
| `agent-coordination` | Memory-based agent communication protocol |
| `agent-teams` | Team composition templates per task type |
| `model-routing` | Decision framework for Haiku/Sonnet/Opus per task |

## What Augmentation Produces

When Claude augments a repo, it generates:

```
target-repo/
  .understand/
    knowledge-graph.json          # Structured codebase understanding
  docs/
    README.md                     # Project overview + table of contents
    architecture.md               # Layers, patterns, tech stack
    onboarding.md                 # Guided tour for new developers
    AGENTS.md                     # Agent-optimized quick reference
    modules/<layer>.md            # Per-layer deep dives
  .claude/skills/                 # Skills for Claude Code
    coding-standards/SKILL.md
    review/SKILL.md
    ship/SKILL.md
    careful/SKILL.md
    ...
  .cursor/rules/                  # Skills for Cursor
    coding-standards.mdc
    review.mdc
    ship.mdc
    careful.mdc
    project.mdc                   # Project-specific Cursor config
    ...
  CLAUDE.md                       # Project-specific Claude Code config
                                  # Commands, architecture, workflow instructions
```

Both `CLAUDE.md` and `.cursor/rules/project.mdc` are generated so developers can use either tool. They contain:
- Project overview and tech stack
- Architecture summary (from knowledge graph)
- Development commands (detected from Makefile, package.json, etc.)
- Coding standards (inferred from existing code)
- Engineering workflow instructions (when to use each skill)
- Project-specific rules and patterns

## Adding Your Own Skills

```bash
mkdir -p skills/my-skill
```

Create `skills/my-skill/SKILL.md`:

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

Register in `agent.yaml`:

```yaml
skills:
  - my-skill
```

## Project Structure

```
iscagent/
  agent.yaml              # Skill registry and model preferences
  skills/                 # 32 skill modules
    repo-augmentation/    # Master orchestrator
    review/               # PR review workflow
    ship/                 # Release pipeline
    investigate/          # Root-cause debugging
    careful/              # Safety guardrails
    retro/                # Retrospective analytics
    plan-review/          # Architecture review
    codebase-understanding/
    docs-generation/
    ...
  export/                 # Installation tools
    install-skills.sh     # Install skills to Claude Code or target repos
    augment.sh            # CLI-driven augmentation pipeline
    claude-code.md        # Claude Code export guide
    cursor.md             # Cursor export guide
  examples/
    minimal/              # Starter config
  spec/
    SPECIFICATION.md      # iscagent format specification
```

## Credits

- Engineering workflow skills inspired by [gstack](https://github.com/garrytan/gstack)
- Structure inspired by [gitagent](https://github.com/open-gitagent/gitagent)
- Skills sourced from [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- Repo augmentation methodology from [Understand-Anything](https://github.com/Lum1104/Understand-Anything) and [CLI-Anything](https://github.com/HKUDS/CLI-Anything)

## License

MIT
