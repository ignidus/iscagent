---
name: repo-augmentation
version: 1.0.0
description: End-to-end pipeline that understands a codebase and generates an agent-native CLI for it. Chains codebase-understanding into cli-generation as a single workflow.
author: iscmga
tags: [repo-augmentation, codebase-analysis, cli, agent-native, automation, pipeline]
triggers:
  globs: []
  keywords: [augment repo, augment repository, make repo agent-native, repo augmentation, understand and cli]
---

# Repo Augmentation

End-to-end pipeline: understand a codebase deeply, then generate a CLI so agents (and humans) can interact with it programmatically. Chains the `codebase-understanding` and `cli-generation` skills into a single coordinated workflow.

## When to Activate

- "Make this repo agent-native"
- "Augment this repository"
- "I want to understand this codebase and build a CLI for it"
- When onboarding to a new project and wanting both understanding AND tooling
- When preparing a repo for multi-agent workflows

## Pipeline Overview

```
STAGE 1: UNDERSTAND        STAGE 1.75: DOCUMENT+VISUALIZE    STAGE 1.5: EQUIP         STAGE 2: GENERATE
(codebase-understanding)   (docs-generation +                 (skill-recommender)       (cli-generation)
                            knowledge-graph-visualizer)

 Scan files                 Read knowledge graph               Read knowledge graph      Analyze knowledge graph
      |                          |           |                      |                         |
 Analyze structure  ──>     Generate docs   Generate diagrams  Match signals to catalog  Design CLI commands
      |              kg          |           |                      |                         |
 Map architecture    .json  docs/README.md  docs/diagrams/     Recommend skills          Implement CLI
      |                     docs/modules/   architecture.md         |                         |
 Generate tour              docs/AGENTS.md  dependencies.md    Fetch & install matched   Test & document
      |                     docs/onboard..  data-flow.md            |                         |
 knowledge-graph.json                       file-map.md        .claude/skills/*          Working CLI + SKILL.md
```

## Workflow

### Step 1: Pre-flight

Check the target repo:
- Is it a git repo? (required for incremental updates)
- Does `.understand/knowledge-graph.json` already exist? (skip Stage 1 if current)
- Does a CLI already exist? (extend rather than rebuild)
- What languages/frameworks are used? (determines CLI technology choice)

### Step 2: Understand (invoke codebase-understanding skill)

Run the full codebase-understanding pipeline:

1. **Scan** all source files, detect languages and frameworks
2. **Analyze** in batches — extract functions, classes, imports, write summaries
3. **Assemble** into unified graph with referential integrity
4. **Map architecture** into 3-7 layers
5. **Generate tour** from entry points outward

Output: `.understand/knowledge-graph.json`

### Step 2.5: Document & Visualize (invoke docs-generation + knowledge-graph-visualizer skills)

Using the knowledge graph, generate human-readable documentation and visual diagrams:

1. **docs-generation** — transforms the knowledge graph into a `/docs` folder:
   - `docs/README.md` — project overview + table of contents
   - `docs/architecture.md` — layers, patterns, tech stack
   - `docs/modules/<layer>.md` — per-layer deep dives
   - `docs/onboarding.md` — guided tour as prose narrative
   - `docs/AGENTS.md` — agent-optimized quick reference

2. **knowledge-graph-visualizer** — generates Mermaid diagrams:
   - `docs/diagrams/architecture.md` — layer overview diagram
   - `docs/diagrams/dependencies.md` — module dependency graph
   - `docs/diagrams/data-flow.md` — request/event flow
   - `docs/diagrams/file-map.md` — directory tree with layer annotations

These two skills can run in parallel since they both read from the knowledge graph independently.

### Step 2.75: Equip (invoke skill-recommender skill)

Using the knowledge graph, search the awesome-agent-skills catalog for relevant skills:

1. **Extract signals** — languages, frameworks, layers, tooling from the graph
2. **Match** against the catalog (549+ skills from Anthropic, Vercel, Cloudflare, Stripe, etc.)
3. **Present** ranked recommendations grouped by confidence
4. **Fetch** user-approved skills into `.claude/skills/`

This ensures the agent has the right domain-specific skills installed BEFORE generating the CLI. For example, if the repo uses Next.js, the Vercel next-best-practices skill gets installed and can inform the CLI design.

### Step 3: Derive CLI Design from Knowledge Graph

This is the bridge between understanding and generation. Read the knowledge graph and derive:

| Graph Element | CLI Design Decision |
|---------------|-------------------|
| **Node types** (file, function, class) | Entity command groups (`<entity> list/show/create`) |
| **Entry points** (high fan-out nodes) | Primary commands (most important operations) |
| **Layers** (API, Service, Data) | Command group organization |
| **Edge types** (imports, calls, configures) | Operation dependencies and ordering |
| **Complexity ratings** | Which operations need confirmation prompts |
| **Tour steps** | `help` command ordering and onboarding flow |

Write the derivation to `.understand/cli-design.json`:

```json
{
  "projectName": "my-project",
  "cliName": "my-project-cli",
  "commandGroups": [
    {
      "name": "api",
      "description": "API endpoint operations",
      "derivedFrom": "API layer in knowledge graph",
      "commands": [
        {"name": "list", "description": "List all API endpoints", "sourceNodes": ["src/routes/*.ts"]},
        {"name": "test", "description": "Test an endpoint", "sourceNodes": ["src/routes/*.ts"]}
      ]
    }
  ],
  "entities": ["route", "middleware", "model", "migration"],
  "backends": ["npm", "node", "prisma"],
  "stateModel": {
    "description": "What gets persisted in project JSON",
    "fields": ["selectedEndpoint", "environment", "lastTestResult"]
  }
}
```

### Step 4: Generate (invoke cli-generation skill)

Using the CLI design from Step 3, run the cli-generation pipeline:

1. **Design** command groups and state model
2. **Implement** data layer, probe commands, mutation commands, backend bridge
3. **Add** session management (undo/redo)
4. **Add** REPL mode
5. **Test** at all three layers (unit, integration, E2E)
6. **Generate** SKILL.md for agent discoverability

### Step 5: Validate the Augmentation

Run a final validation pass:

- [ ] Knowledge graph exists and passes integrity checks
- [ ] CLI installs and runs without errors
- [ ] `--json` flag works on all commands
- [ ] REPL mode launches successfully
- [ ] SKILL.md accurately describes available commands
- [ ] At least one E2E test passes
- [ ] CLI design traces back to knowledge graph nodes (no orphan commands)

### Step 6: Commit Artifacts

Stage the following for commit:
```
.understand/
  knowledge-graph.json     # Codebase understanding
  cli-design.json          # Bridge document (graph -> CLI design)
docs/
  README.md                # Project documentation entry point
  architecture.md          # Architecture overview
  onboarding.md            # Guided tour as prose
  AGENTS.md                # Agent-optimized reference
  modules/                 # Per-layer documentation
  diagrams/                # Mermaid visualizations
    architecture.md
    dependencies.md
    data-flow.md
    file-map.md
<project>-cli/             # Generated CLI
  ...
  skills/
    SKILL.md               # Agent-discoverable skill definition
```

## Execution Strategy

### For Small Repos (<50 files)

Run everything sequentially in the main agent context:
1. Scan + analyze + assemble (inline)
2. Derive CLI design (inline)
3. Generate CLI (inline)
4. Test + validate (inline)

### For Medium Repos (50-200 files)

Use two subagents:
1. **Understand agent** — runs full codebase-understanding pipeline
2. **Main agent** — derives CLI design from graph, then generates CLI

### For Large Repos (200+ files)

Use parallel subagents:
1. **Scanner agent** — file discovery (Stage 1)
2. **N Analyzer agents** — parallel batch analysis (Stage 2)
3. **Main agent** — assemble, architecture, tour (Stages 3-5)
4. **CLI Design agent** — derive CLI design from graph
5. **CLI Implementation agent** — generate CLI code
6. **Test agent** — implement and run tests

## Technology Selection

Choose CLI framework based on the repo's primary language:

| Repo Language | CLI Framework | Package Format |
|--------------|---------------|----------------|
| Python | Click | pip / PyPI |
| TypeScript/JavaScript | Commander.js or oclif | npm |
| Go | Cobra | go install |
| Rust | Clap | cargo install |
| Ruby | Thor | gem |
| Any (fallback) | Python + Click | pip |

## Example: Augmenting a Node.js API

```
Input: Express.js REST API with Prisma ORM

Stage 1 Output (understanding):
  - 47 files analyzed
  - Layers: API (routes), Service (business logic), Data (Prisma models), Config
  - Entry point: src/index.ts
  - Key entities: User, Post, Comment
  - Tour: index.ts -> routes/ -> services/ -> prisma/schema.prisma

Stage 2 Bridge (cli-design.json):
  - Command groups: user, post, comment, db, server
  - Backends: node (server), prisma (migrations/queries)
  - State: selected environment, last query result

Stage 3 Output (CLI):
  $ myapi-cli user list --json
  $ myapi-cli db migrate
  $ myapi-cli server start --port 3000
  $ myapi-cli post create --title "Hello" --author-id 1
  $ myapi-cli session undo
```

## Anti-Patterns

- **Skipping understanding**: Don't generate a CLI without first building the knowledge graph. You'll miss entities and create an incomplete interface.
- **CLI that doesn't match the codebase**: Every command group should trace back to a knowledge graph layer or entity. No orphan commands.
- **Understanding without action**: A knowledge graph alone isn't actionable. The CLI is what makes it useful for agents.
- **One-size-fits-all CLI**: Use the repo's own language for the CLI when possible. A Python CLI for a Go project creates unnecessary friction.
- **Ignoring existing CLIs**: If the repo already has a CLI (Makefile, npm scripts, rake tasks), extend it rather than creating a parallel one.

## Integration Points

### With `agent-teams` skill
Use the "Feature" team template for large repos:
- Architect → derives CLI design from knowledge graph
- Implementer → generates CLI code
- Tester → writes and runs tests
- Documenter → generates SKILL.md

### With `verification-loop` skill
After generation, run the verification loop:
- Execute all CLI commands
- Verify JSON output parses correctly
- Confirm undo/redo works
- Validate SKILL.md accuracy

### With `model-routing` skill
Route stages to appropriate models:
- Scanning (Stage 1) → Haiku (mechanical file discovery)
- Analysis (Stage 2) → Sonnet (structured extraction + summarization)
- Architecture + Tour (Stage 4-5) → Opus (requires deep reasoning)
- CLI Implementation → Sonnet (well-defined code generation)
- Testing → Sonnet (standard test patterns)
