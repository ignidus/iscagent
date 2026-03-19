---
name: knowledge-graph-visualizer
version: 1.0.0
description: Transform a knowledge graph into Mermaid diagrams for architecture visualization, dependency mapping, and data flow analysis.
author: iscmga
tags: [visualization, mermaid, diagrams, knowledge-graph, architecture, dependencies]
triggers:
  globs: ["**/knowledge-graph.json", "**/docs/diagrams/*.md"]
  keywords: [visualize, diagram, mermaid, graph diagram, architecture diagram, dependency diagram, show knowledge graph]
---

# Knowledge Graph Visualizer

Transform `.understand/knowledge-graph.json` into Mermaid diagrams that render natively in GitHub, GitLab, Obsidian, and most markdown viewers. Produces architecture overviews, dependency graphs, data flow maps, and file organization trees.

## When to Activate

- After running `codebase-understanding` (knowledge graph exists)
- "Show me a diagram of this codebase"
- "Visualize the architecture"
- "Generate dependency diagrams"
- "Draw the knowledge graph"
- As part of the `repo-augmentation` pipeline (Stage 1.75, alongside `docs-generation`)

## Prerequisites

- `.understand/knowledge-graph.json` must exist. Run `codebase-understanding` first if it doesn't.

## Output Structure

```
docs/
└── diagrams/
    ├── README.md              # Index of all diagrams with descriptions
    ├── architecture.md        # Layer overview diagram
    ├── dependencies.md        # Module dependency graph
    ├── data-flow.md           # How data flows through the system
    └── file-map.md            # File organization treemap
```

## Pipeline — 6 Steps

```
Step 1: READ knowledge graph
         |
Step 2: GENERATE docs/diagrams/architecture.md
         |
Step 3: GENERATE docs/diagrams/dependencies.md
         |
Step 4: GENERATE docs/diagrams/data-flow.md
         |
Step 5: GENERATE docs/diagrams/file-map.md
         |
Step 6: GENERATE docs/diagrams/README.md (index)
```

### Step 1: Read Knowledge Graph

Load `.understand/knowledge-graph.json` and extract:

```
layers[]     → for architecture diagram
nodes[]      → for all diagrams (files, classes, functions)
edges[]      → for dependency and data-flow diagrams
tour[]       → for highlighting entry points
metadata     → for labels and titles
```

### Step 2: Generate `docs/diagrams/architecture.md`

A top-down view of architectural layers and their relationships.

```markdown
# Architecture Overview

> Auto-generated from knowledge graph. Commit: `<hash>`

## Layer Diagram

```mermaid
flowchart TD
    subgraph <Layer1>[" <Layer1 Name> — <description snippet> "]
        L1F1["<top file 1>"]
        L1F2["<top file 2>"]
        L1F3["<top file 3>"]
    end

    subgraph <Layer2>[" <Layer2 Name> — <description snippet> "]
        L2F1["<top file 1>"]
        L2F2["<top file 2>"]
    end

    <Layer1> --> <Layer2>
    <Layer2> --> <Layer3>
`` `

## Layer Details

| Layer | Files | Description |
|-------|-------|-------------|
| <name> | <count> | <description> |
```

**Construction rules:**
- One `subgraph` per layer from `layers[]`
- Show top 3-5 files per layer (by edge count — most connected first)
- Draw edges between subgraphs based on cross-layer `imports`/`calls`/`depends_on` edges
- Use `-->` for direct dependencies, `-.->` for weak/optional dependencies
- Add brief descriptions in subgraph labels
- If a layer has >10 files, add a `...and N more` node

### Step 3: Generate `docs/diagrams/dependencies.md`

A graph showing how modules/files depend on each other.

```markdown
# Dependency Graph

> Shows import and dependency relationships between key files.

## Full Dependency Graph

```mermaid
graph LR
    A["src/index.ts"] --> B["src/routes/api.ts"]
    A --> C["src/config/db.ts"]
    B --> D["src/services/userService.ts"]
    B --> E["src/services/postService.ts"]
    D --> F["src/models/User.ts"]
    E --> F
    E --> G["src/models/Post.ts"]

    style A fill:#f9f,stroke:#333
    style F fill:#bbf,stroke:#333
`` `
```

**Construction rules:**
- Include only `imports`, `calls`, `depends_on`, and `routes_to` edge types
- Filter to top 30-40 most-connected nodes to keep the diagram readable
- If the graph has >40 nodes, generate per-layer subgraphs instead of one flat graph
- Use `graph LR` (left-to-right) for dependency flow
- Style entry points with a distinct fill color (pink/highlighted)
- Style high-complexity nodes with a warning color
- Add a legend section explaining the colors

**Per-layer variant (for large codebases):**

If total nodes > 40, generate additional focused diagrams:

```markdown
## <Layer Name> Dependencies

```mermaid
graph LR
    %% Only nodes in <Layer> and their direct dependencies
    ...
`` `
```

### Step 4: Generate `docs/diagrams/data-flow.md`

Shows how data moves through the system.

```markdown
# Data Flow

> How data enters, transforms, and exits the system.

## Request Flow

```mermaid
flowchart LR
    Client([Client]) --> Entry["Entry Point<br/><entry file>"]
    Entry --> Router["Router<br/><router file>"]
    Router --> Service["Service Layer<br/><service file>"]
    Service --> Data["Data Layer<br/><model/db file>"]
    Data --> DB[(Database)]

    Service --> External["External API<br/><integration file>"]
`` `
```

**Construction rules:**
- Use `flowchart LR` for left-to-right data flow
- Start from entry points (tour step 1, or highest fan-out nodes)
- Follow `imports` → `calls` → `reads_from`/`writes_to` edge chains
- Use special shapes:
  - `([...])` for external actors (Client, User)
  - `[(...)]` for databases
  - `["..."]` for internal components
  - `{{"..."}}` for decision points
- Group related nodes if they form a pipeline
- Add `:::className` for styling if needed
- If the system has multiple entry points (e.g., HTTP + cron + queue), show each as a separate flow

**Event-driven variant:**

If `subscribes`/`publishes` edges are present:

```markdown
## Event Flow

```mermaid
flowchart TD
    Publisher["<publisher file>"] -->|publishes| EventBus{{Event Bus}}
    EventBus -->|subscribes| HandlerA["<handler A>"]
    EventBus -->|subscribes| HandlerB["<handler B>"]
`` `
```

### Step 5: Generate `docs/diagrams/file-map.md`

A treemap/hierarchy showing file organization.

```markdown
# File Organization

> Directory structure with architectural layer annotations.

## File Tree

```mermaid
flowchart TD
    Root["<project-name>/"]
    Root --> Src["src/"]
    Root --> Config["config/"]
    Root --> Tests["tests/"]

    Src --> SrcAPI["api/ <br/> 🔵 API Layer"]
    Src --> SrcSvc["services/ <br/> 🟢 Service Layer"]
    Src --> SrcData["models/ <br/> 🟡 Data Layer"]

    SrcAPI --> API1["routes.ts"]
    SrcAPI --> API2["middleware.ts"]

    SrcSvc --> Svc1["userService.ts"]
    SrcSvc --> Svc2["postService.ts"]

    SrcData --> Data1["User.ts"]
    SrcData --> Data2["Post.ts"]
`` `
```

**Construction rules:**
- Use `flowchart TD` (top-down) for tree hierarchy
- Group files by directory, then annotate with layer assignment
- Use emoji color indicators for layers:
  - 🔵 API
  - 🟢 Service
  - 🟡 Data
  - 🟣 UI
  - ⚙️ Config
  - 🧪 Testing
  - 🏗️ Infrastructure
- Show individual files only for directories with ≤8 files
- For larger directories, show count: `"controllers/ (15 files)"`
- Max depth: 3 levels (project → directory → subdirectory)

### Step 6: Generate `docs/diagrams/README.md`

Index page linking all diagrams:

```markdown
# Diagrams

> Visual representations of the **<project name>** codebase.
> Generated from knowledge graph at commit `<hash>`.

## Available Diagrams

| Diagram | Description | Best For |
|---------|-------------|----------|
| [Architecture Overview](architecture.md) | Layer diagram showing system structure | Understanding the big picture |
| [Dependency Graph](dependencies.md) | Import/call relationships between files | Finding coupling and dependencies |
| [Data Flow](data-flow.md) | How data moves through the system | Understanding request/event lifecycle |
| [File Map](file-map.md) | Directory structure with layer annotations | Navigating the codebase |

## How to View

These diagrams use [Mermaid](https://mermaid.js.org/) syntax which renders natively in:
- GitHub / GitLab markdown preview
- Obsidian
- VS Code (with Mermaid extension)
- Notion (paste as code block, select Mermaid)

For other viewers, paste the mermaid code blocks into [mermaid.live](https://mermaid.live/).
```

## Mermaid Best Practices

Follow these rules to keep diagrams renderable and readable:

### Size Limits
- **Max 50 nodes** per diagram. Beyond that, split into sub-diagrams.
- **Max 3 nesting levels** for subgraphs.
- **Node labels under 40 characters.** Truncate file paths: `src/services/userService.ts` → `userService.ts` (show full path in a table below the diagram).

### Syntax Safety
- **Quote all node labels** with `["..."]` to avoid Mermaid parsing errors.
- **Avoid special characters** in node IDs — use alphanumeric + underscores only.
- **Sanitize file names** for IDs: `src/api/routes.ts` → `src_api_routes_ts`.
- **Test each diagram** mentally — if it has syntax errors, Mermaid renders nothing.

### Readability
- Use `graph LR` for dependency/flow diagrams (left-to-right reads naturally).
- Use `flowchart TD` for hierarchies and architecture (top-down).
- Add spacing with empty lines between subgraph blocks.
- Use `style` directives sparingly — only for entry points and high-complexity nodes.
- Include a legend/key if colors or shapes have meaning.

### Node ID Convention

Generate deterministic IDs from file paths:

```
File path:  src/api/routes.ts
Node ID:    src_api_routes_ts
Label:      ["routes.ts"]
```

This ensures:
- No ID collisions
- Reproducible diagrams on regeneration
- Valid Mermaid syntax (no dots or slashes in IDs)

## Incremental Updates

Same strategy as `docs-generation`:

1. Check if `docs/diagrams/` exists
2. Compare commit hash in `docs/diagrams/README.md` with current knowledge graph
3. If different → regenerate all diagrams
4. If same → skip

## Quality Checks

Before finalizing:

- [ ] All 4 diagram files + README exist in `docs/diagrams/`
- [ ] Each Mermaid code block is syntactically valid (no unclosed quotes, balanced brackets)
- [ ] No diagram exceeds 50 nodes
- [ ] Architecture diagram has one subgraph per layer
- [ ] Dependency diagram includes only the most-connected nodes
- [ ] Data flow diagram starts from an entry point
- [ ] File map depth does not exceed 3 levels
- [ ] All node IDs are sanitized (no special characters)
- [ ] README index links are valid

## Anti-Patterns

- **Giant hairball graphs**: A 200-node dependency diagram is useless. Filter aggressively — show the top 30-40 most important nodes.
- **Unlabeled diagrams**: Every diagram needs a title, description, and context about what it shows.
- **Syntax errors**: One bad character and the entire Mermaid block fails to render. Always sanitize IDs and quote labels.
- **Redundant diagrams**: Don't generate 4 diagrams that show the same thing differently. Each diagram has a distinct purpose.
- **Static screenshots**: Never generate image files. Mermaid is text-based and diff-friendly — that's the whole point.
- **Ignoring the knowledge graph**: Don't read source files to build diagrams. The knowledge graph is the single source of truth.

## Integration Points

### With `docs-generation` skill
Run alongside docs-generation. The docs can link to diagrams, and diagrams link back to docs:
- `docs/architecture.md` can embed or link to `docs/diagrams/architecture.md`
- `docs/modules/<layer>.md` can link to the relevant subgraph in the dependency diagram

### With `codebase-understanding` skill
This skill REQUIRES the knowledge graph as input. Always run `codebase-understanding` first.

### With `repo-augmentation` skill
Slots in as **Stage 1.75** alongside `docs-generation`. The updated pipeline:
1. Understand → knowledge-graph.json
2. **Document** → docs/ (prose)
3. **Visualize** → docs/diagrams/ (Mermaid)
4. Equip → install relevant skills
5. Generate → CLI
