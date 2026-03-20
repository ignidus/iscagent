---
name: docs-generation
version: 1.0.0
description: Transform a knowledge graph into a human-readable /docs folder with markdown documentation that both humans and agentic workflows can reference.
author: iscmga
tags: [documentation, markdown, knowledge-graph, onboarding, auto-docs, agent-readable]
triggers:
  globs: ["**/knowledge-graph.json", "**/docs/README.md"]
  keywords: [generate docs, auto docs, documentation, document codebase, docs folder, write documentation]
---

# Docs Generation

Transform `.understand/knowledge-graph.json` into a structured `/docs` folder with human-readable markdown that also serves as an agentic reference. This is the "prose layer" on top of the knowledge graph — same data, optimized for reading.

## When to Activate

- After running `codebase-understanding` (knowledge graph exists)
- "Generate documentation for this repo"
- "Create a docs folder"
- "Make this codebase easier to understand"
- As part of the `repo-augmentation` pipeline (Stage 1.75)
- When onboarding new team members

## Prerequisites

- `.understand/knowledge-graph.json` must exist. Run `codebase-understanding` first if it doesn't.

## Output Structure

```
docs/
├── README.md              # Project overview + table of contents
├── architecture.md        # Layers, patterns, tech stack, high-level design
├── onboarding.md          # Guided tour in prose (from knowledge graph tour)
├── AGENTS.md              # Agent-optimized quick reference (structured for LLM consumption)
├── modules/
│   ├── <layer-1>.md       # One file per architectural layer
│   ├── <layer-2>.md
│   └── ...
└── api/                   # (optional) Only if API layer detected
    └── endpoints.md       # API endpoint catalog
```

## Pipeline — 6 Steps

```
Step 1: READ knowledge graph
         |
Step 2: GENERATE docs/README.md (overview + TOC)
         |
Step 3: GENERATE docs/architecture.md (layers + tech stack)
         |
Step 4: GENERATE docs/modules/<layer>.md (per-layer deep dives)
         |
Step 5: GENERATE docs/onboarding.md (tour → prose)
         |
Step 6: GENERATE docs/AGENTS.md (structured agent reference)
```

### Step 1: Read Knowledge Graph

Load `.understand/knowledge-graph.json` and extract:

```
metadata     → project name, languages, frameworks, file count
nodes[]      → files with summaries, tags, complexity
edges[]      → relationships between files
layers[]     → architectural layers with file assignments
tour[]       → guided learning steps
```

### Step 2: Generate `docs/README.md`

The entry point for all documentation. Structure:

```markdown
# <Project Name>

> Auto-generated documentation from codebase analysis.
> Last generated: <analyzedAt from metadata>
> Commit: <gitCommitHash>

## Overview

<2-3 paragraph summary derived from:>
- metadata.languages and metadata.frameworks
- Number of files, nodes, layers
- Primary purpose inferred from entry point node summaries

## Tech Stack

| Category | Technologies |
|----------|-------------|
| Languages | <metadata.languages> |
| Frameworks | <metadata.frameworks> |
| Total Files | <metadata.totalFiles> |

## Architecture

This project is organized into **<N> layers**:

| Layer | Description | Files |
|-------|-------------|-------|
| <layer.name> | <layer.description> | <layer.files.length> |

→ See [Architecture](architecture.md) for details.

## Quick Links

- [Architecture Overview](architecture.md)
- [Onboarding Guide](onboarding.md)
- [Agent Reference](AGENTS.md)
- Modules:
  - [<Layer 1>](modules/<layer-1>.md)
  - [<Layer 2>](modules/<layer-2>.md)
  - ...
```

### Step 3: Generate `docs/architecture.md`

Deep dive into system architecture:

```markdown
# Architecture

## System Overview

<Describe the overall architecture pattern (MVC, microservices, monolith, etc.)
 inferred from layer structure and edge patterns>

## Layers

### <Layer Name>

**Purpose:** <layer.description>

**Files (<count>):**

| File | Purpose | Complexity |
|------|---------|------------|
| <node.filePath> | <node.summary> | <node.complexity> |

**Key Relationships:**
- <Summarize edges where source OR target is in this layer>
- Focus on cross-layer dependencies

<Repeat for each layer>

## Dependency Flow

<Describe how data/control flows between layers, derived from edge analysis>
<Which layers depend on which? Are there circular dependencies?>

## Key Design Decisions

<Infer from patterns observed:>
- Framework choices and why they matter
- Data flow patterns (sync vs async, event-driven, etc.)
- Configuration strategy (env vars, config files, etc.)
```

### Step 4: Generate `docs/modules/<layer>.md`

One file per architectural layer for deep exploration:

```markdown
# <Layer Name>

> <layer.description>

## Files

### `<node.filePath>`

**Summary:** <node.summary>
**Complexity:** <node.complexity>
**Tags:** <node.tags joined>

**Exports/Key Functions:**
<List node.children if present, with brief descriptions>

**Dependencies:**
- Imports: <list edges where this node is source, type=imports>
- Used by: <list edges where this node is target>

<Repeat for each file in the layer, ordered by importance (fan-out count)>

## Layer Relationships

<Summarize how this layer connects to others>
<Include a count: "This layer imports from N files in <other layer>">
```

### Step 5: Generate `docs/onboarding.md`

Convert the knowledge graph tour into a narrative guide:

```markdown
# Onboarding Guide

Welcome to **<project name>**. This guide walks you through the codebase
step-by-step, starting from the entry point and following the natural
dependency chain.

## Before You Start

- **Languages:** <metadata.languages>
- **Frameworks:** <metadata.frameworks>
- **Total files:** <metadata.totalFiles>
- **Estimated reading time:** ~<tour.length * 3> minutes

## The Tour

### Step <tour.step>: <tour.title>

📍 **File:** `<tour.nodeId>`

<tour.description>

<Add context from the node's summary and its immediate edges:>
- What this file does
- What it connects to (list 2-3 key imports/exports)
- Why it matters in the architecture

**Next:** This leads us to [Step <next>](#step-<next>-<next-title>)...

<Repeat for each tour step>

## What's Next?

Now that you've walked through the core architecture:
- Explore individual [modules](modules/) for deeper dives
- Check the [architecture overview](architecture.md) for the big picture
- See [AGENTS.md](AGENTS.md) for a machine-readable reference
```

### Step 6: Generate `docs/AGENTS.md`

Structured reference optimized for LLM/agent consumption:

```markdown
# Agent Reference — <Project Name>

> Machine-readable project reference. Use this file to quickly understand
> the project structure when operating as an AI agent.

## Quick Facts

- **Name:** <metadata.projectName>
- **Languages:** <metadata.languages as comma-separated>
- **Frameworks:** <metadata.frameworks as comma-separated>
- **Files:** <metadata.totalFiles>
- **Layers:** <layers.length>
- **Analyzed:** <metadata.analyzedAt>
- **Commit:** <metadata.gitCommitHash>

## Layer Map

<For each layer, one-line summary:>
- **<layer.name>**: <layer.description> (<file count> files)

## Entry Points

<List nodes that appear as tour step 1, or nodes with highest fan-out:>
- `<filePath>` — <summary>

## Key Files (by complexity/importance)

<Top 10-15 files sorted by edge count (most connected first):>
| File | Layer | Connections | Summary |
|------|-------|-------------|---------|
| `<path>` | <layer> | <edge count> | <summary> |

## Relationship Summary

<Aggregate edge types:>
| Relationship | Count | Example |
|-------------|-------|---------|
| imports | <count> | `A` → `B` |
| calls | <count> | `A` → `B` |
| configures | <count> | `A` → `B` |

## File Index

<Complete alphabetical file list with one-line summaries:>
- `<path>` — <summary>
```

## Incremental Updates

When the knowledge graph is updated:

1. Check if `docs/` exists
2. Compare `metadata.gitCommitHash` in docs/README.md with current graph
3. If different → regenerate all docs
4. If same → skip (docs are current)

For future optimization: only regenerate docs for layers that contain changed files. But for v1, full regeneration is fine since it's fast.

## Formatting Rules

- Use GitHub-flavored markdown throughout
- Keep line lengths under 120 characters for readability
- Use tables for structured data (file lists, relationships)
- Use code blocks with backticks for file paths and code references
- Link between docs files using relative paths
- Include the generation timestamp in README.md so staleness is visible
- Use emoji sparingly — only in onboarding.md for visual waypoints

## Quality Checks

Before finalizing:

- [ ] `docs/README.md` exists and has a valid table of contents
- [ ] Every layer in the knowledge graph has a corresponding `docs/modules/<layer>.md`
- [ ] `docs/onboarding.md` has the same number of steps as the knowledge graph tour
- [ ] `docs/AGENTS.md` lists all files from the knowledge graph
- [ ] All internal links between docs files are valid (no broken refs)
- [ ] No empty sections (if a section would be empty, omit it)
- [ ] File summaries match between AGENTS.md and module docs (no drift)

## Anti-Patterns

- **Dumping raw JSON**: The docs should be prose, not reformatted JSON. Summarize, don't serialize.
- **Skipping the tour**: The onboarding guide is the most valuable doc for humans — always generate it.
- **No cross-links**: Every doc should link to related docs. Isolated pages are hard to navigate.
- **Stale docs**: Always include the commit hash and timestamp so readers know if docs are current.
- **Over-documenting utilities**: Focus depth on high-complexity, high-connectivity files. Utility files get one-liners.
- **Generating without a knowledge graph**: Never try to generate docs by reading source files directly. Always go through the knowledge graph — it's the single source of truth.

## Integration Points

### With `codebase-understanding` skill
This skill REQUIRES the knowledge graph as input. Always run `codebase-understanding` first.

### With `knowledge-graph-visualizer` skill
The visualizer generates Mermaid diagrams that can be embedded in or linked from the docs. Run both skills to get prose + diagrams.

### With `repo-augmentation` skill
This skill is **Stage 2** of the 4-stage augmentation pipeline:
1. **Understand** → knowledge-graph.json
2. **Document** → docs/ folder (this skill)
3. **Equip** → install relevant skills (reads graph + docs for richer signals)
4. **Generate** → CLI

### With `skill-recommender` skill
The skill-recommender reads the generated `docs/` folder to extract additional domain signals (architecture patterns, integration details, design decisions) that improve skill matching accuracy beyond what the knowledge graph's structured metadata provides.
