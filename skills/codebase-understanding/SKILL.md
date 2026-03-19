---
name: codebase-understanding
version: 1.0.0
description: Systematic codebase analysis that builds a knowledge graph — scan, analyze, map architecture, and generate guided tours. Extracted from Understand-Anything methodology.
author: iscmga
tags: [codebase-analysis, knowledge-graph, architecture, onboarding, documentation]
triggers:
  globs: ["**/knowledge-graph.json", "**/ARCHITECTURE.md"]
  keywords: [understand codebase, analyze repo, map architecture, knowledge graph, codebase tour]
---

# Codebase Understanding

Systematically decompose any codebase into a structured knowledge graph that maps files, functions, classes, relationships, architectural layers, and guided learning tours.

Extracted from the [Understand-Anything](https://github.com/Lum1104/Understand-Anything) methodology.

## When to Activate

- Onboarding to an unfamiliar codebase
- Before making architectural changes to a repo you don't fully understand
- When a user asks "how does this repo work?" or "explain this codebase"
- Before running the `cli-generation` or `repo-augmentation` skills
- When generating documentation for a project

## Core Concept

Rather than reading an entire codebase top-to-bottom, decompose it into **nodes** (files, functions, classes, modules, concepts) and **edges** (imports, calls, inherits, configures, etc.), add plain-English explanations, and produce a navigable map.

## Pipeline — 5 Stages

```
Stage 0: PRE-FLIGHT
  Has this repo been analyzed before?
  If knowledge-graph.json exists and git HEAD unchanged → skip
  If files changed → incremental update (re-analyze only changed files)
        |
        v
Stage 1: SCAN
  Discover all source files
  Exclude: node_modules, dist, .git, lock files, images, generated code
  Produce: file inventory with languages, frameworks, line counts
        |
        v
Stage 2: ANALYZE (parallel, batched)
  For each batch of 5-10 files:
    - Extract: functions, classes, imports/exports, types
    - Summarize: plain-English description of each file's purpose
    - Tag: categorize by role (controller, model, util, config, test, etc.)
    - Rate: complexity (low/medium/high)
  Produce: nodes + edges per batch
        |
        v
Stage 3: ASSEMBLE
  Merge all batch results into unified graph
  Remove dangling edges (refs to non-existent nodes)
  Deduplicate nodes by ID
  Verify referential integrity
        |
        v
Stage 4: ARCHITECTURE
  Assign each file to 3-7 architectural layers:
    API / Service / Data / UI / Config / Testing / Infrastructure
  Use: directory patterns + import flow analysis
  Produce: layer assignments with descriptions
        |
        v
Stage 5: TOUR
  Identify entry points (high fan-out, low fan-in, index/main files)
  Follow dependency chains via BFS from entry points
  Design 5-15 pedagogical steps that teach the codebase
  Order: entry → direct deps → deeper deps → utilities → config
  Produce: guided tour with step descriptions
```

## Output Format

Write results to `.understand/knowledge-graph.json` at the repo root:

```json
{
  "metadata": {
    "projectName": "string",
    "analyzedAt": "ISO-8601",
    "gitCommitHash": "string",
    "totalFiles": 0,
    "totalNodes": 0,
    "totalEdges": 0,
    "languages": ["typescript", "python"],
    "frameworks": ["express", "react"]
  },
  "nodes": [
    {
      "id": "src/api/routes.ts",
      "type": "file",
      "name": "routes.ts",
      "filePath": "src/api/routes.ts",
      "summary": "Defines all REST API endpoints and maps them to controller handlers.",
      "tags": ["api", "routing", "express"],
      "complexity": "medium",
      "language": "typescript",
      "lineCount": 142,
      "children": ["src/api/routes.ts::getUsers", "src/api/routes.ts::createUser"]
    }
  ],
  "edges": [
    {
      "source": "src/api/routes.ts",
      "target": "src/services/userService.ts",
      "type": "imports",
      "weight": 0.8
    }
  ],
  "layers": [
    {
      "name": "API",
      "description": "HTTP endpoints and request handling",
      "files": ["src/api/routes.ts", "src/api/middleware.ts"]
    }
  ],
  "tour": [
    {
      "step": 1,
      "nodeId": "src/index.ts",
      "title": "Application Entry Point",
      "description": "The app starts here. It initializes the Express server, loads middleware, and mounts route handlers."
    }
  ]
}
```

## Edge Types

Use these relationship types for edges:

| Type | Meaning |
|------|---------|
| `imports` | File A imports from File B |
| `exports` | File A exports to consumers |
| `calls` | Function A calls Function B |
| `inherits` | Class A extends Class B |
| `implements` | Class A implements Interface B |
| `reads_from` | Code reads from a data source |
| `writes_to` | Code writes to a data source |
| `configures` | Config file controls behavior of target |
| `tested_by` | Source file is tested by test file |
| `depends_on` | Generic dependency relationship |
| `subscribes` | Subscribes to events/messages from target |
| `publishes` | Publishes events/messages consumed by target |
| `renders` | UI component renders another component |
| `routes_to` | Router dispatches to handler |
| `similar_to` | Semantically related (not structural) |

## Node Types

| Type | Description |
|------|-------------|
| `file` | Source file (primary unit of analysis) |
| `function` | Named function or method |
| `class` | Class or interface definition |
| `module` | Logical grouping of related files |
| `concept` | Architectural pattern or language feature |

## Incremental Updates

For repos already analyzed:

1. Read existing `knowledge-graph.json`
2. Run `git diff <lastCommitHash>..HEAD --name-only` to find changed files
3. If no changes → done (graph is current)
4. If changes exist:
   - Remove nodes whose `filePath` matches changed files
   - Remove edges whose `source` or `target` was removed
   - Re-analyze only changed files (Stage 2)
   - Re-merge (Stage 3)
   - Re-evaluate architecture and tour if >20% of files changed

## Execution Strategy

### Using Subagents (recommended for large repos)

```
Stage 1 (SCAN):     1 Explore agent — file discovery
Stage 2 (ANALYZE):  N general-purpose agents in parallel — batch analysis
Stage 3 (ASSEMBLE): Main agent — merge results
Stage 4 (ARCH):     1 general-purpose agent — layer detection
Stage 5 (TOUR):     1 general-purpose agent — tour generation
```

### Solo Agent (small repos, <50 files)

Run all stages sequentially in the main context. Write intermediate results to `.understand/intermediate/` and clean up after assembly.

## Quality Checks

Before finalizing the knowledge graph, verify:

- [ ] Every edge references existing nodes (no dangling refs)
- [ ] No duplicate node IDs
- [ ] Every file in scan inventory has a corresponding node
- [ ] At least 1 layer defined with at least 1 file
- [ ] Tour has at least 3 steps
- [ ] Tour starts from an entry point (not a utility)
- [ ] No empty summaries on nodes

## Anti-Patterns

- **Analyzing everything**: Skip test fixtures, generated code, lock files, vendor dirs
- **Flat graphs**: Always assign layers — a graph without architecture is just a file list
- **No tour**: The tour is what makes the graph useful for humans — never skip it
- **Stale graphs**: Always check git hash before re-analyzing; incremental > full rebuild
- **Over-nesting**: Keep node IDs as file paths, not deeply nested identifiers

## Integration Points

### With `cli-generation` skill
Run codebase-understanding FIRST, then feed the knowledge graph to cli-generation. The graph tells the CLI generator which commands to create, what data models exist, and how components relate.

### With `repo-augmentation` skill
This skill is Stage 1 of the repo-augmentation pipeline.

### With `search-first` skill
Before analyzing, check if the repo already has documentation, architecture diagrams, or ADRs that can accelerate understanding.
