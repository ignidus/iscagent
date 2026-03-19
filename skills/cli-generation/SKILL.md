---
name: cli-generation
version: 1.0.0
description: Generate stateful, agent-native CLI interfaces for any codebase or software. Dual output (human + JSON), backend bridging, session management, and auto-generated skill definitions. Extracted from CLI-Anything methodology.
author: iscmga
tags: [cli, code-generation, agent-native, tooling, automation]
triggers:
  globs: ["**/*_cli.py", "**/cli_anything/**", "**/SKILL.md"]
  keywords: [generate cli, create cli, cli tool, agent-native, cli-anything, wrap in cli]
---

# CLI Generation

Transform any codebase or software into a stateful, agent-native CLI with dual output modes, backend bridging, session management, and auto-generated discoverability.

Extracted from the [CLI-Anything](https://github.com/HKUDS/CLI-Anything) methodology.

## When to Activate

- User asks to "create a CLI for this repo/project/software"
- After running `codebase-understanding`, when the next step is making the repo interactive
- When wrapping a GUI application for agent use
- When building developer tooling for a codebase
- As part of the `repo-augmentation` pipeline

## Core Concept

AI agents excel at reasoning but struggle with GUIs. Instead of reimplementing features, bridge to the real backend and expose everything through structured commands with both human-readable and machine-parseable (JSON) output.

## Pipeline — 7 Phases

```
Phase 1: CODEBASE ANALYSIS
  Map the project's data model, key operations, and extension points
  If knowledge-graph.json exists, use it as input
  Identify: entry points, CRUD operations, config, import/export
        |
        v
Phase 2: CLI ARCHITECTURE DESIGN
  Define command groups:
    - project  (create, open, save, close, info)
    - core     (domain-specific CRUD operations)
    - config   (get, set, list settings)
    - export   (render, convert, output)
    - session  (undo, redo, history, status)
  Design state persistence model (JSON project files)
  Plan dual output: human tables + machine JSON
        |
        v
Phase 3: IMPLEMENTATION
  Build in this order:
    1. Data layer (read/write project state)
    2. Probe commands (info, list, status — read-only first)
    3. Mutation commands (create, update, delete — one per operation)
    4. Backend bridge (wrap real software/tools via subprocess)
    5. Session management (undo/redo with deep-copy snapshots)
    6. REPL mode (interactive shell with history)
        |
        v
Phase 4: TEST PLANNING
  Write TEST.md with full test inventory before writing any tests
  Plan three layers:
    - Unit tests (synthetic data, no external deps)
    - Integration tests (verify file format validity)
    - E2E tests (invoke real backend, verify actual output)
        |
        v
Phase 5: TEST IMPLEMENTATION
  Implement all planned tests
  Every mutation command needs: before-state → command → after-state verification
  CLI subprocess tests: test the installed command via subprocess.run()
        |
        v
Phase 6: DOCUMENTATION
  Auto-generate SKILL.md from CLI metadata (command names, groups, descriptions)
  Include: command reference, examples, agent-specific guidance
        |
        v
Phase 7: PACKAGING (optional)
  Structure as installable package
  Console script entry point puts command on PATH
  Discoverable via `which cli-<project-name>`
```

## CLI Architecture Pattern

### Directory Structure

```
<project>-cli/
  <project>_cli.py          # Main entry point (Click/Typer)
  core/
    project.py              # Project create/save/load
    session.py              # Undo/redo state management
    <domain>.py             # Domain-specific operations
  utils/
    backend.py              # Real software/tool invocation wrapper
    formatters.py           # Output formatting (table + JSON)
  tests/
    TEST.md                 # Test plan and results
    test_core.py            # Unit tests
    test_e2e.py             # End-to-end tests
  skills/
    SKILL.md                # Auto-generated skill definition
```

### Command Design Rules

1. **Every command supports `--json` flag** for machine-parseable output
2. **Bare command (no subcommand) enters REPL mode** for interactive use
3. **`--project` flag** for state persistence across commands
4. **One command per logical operation** — no multi-purpose flags
5. **Probe before mutate** — always build read-only commands first
6. **Consistent error format** — JSON errors when `--json`, human messages otherwise

### Dual Output Pattern

```python
# Human mode (default)
$ mycli project info
Project: my-app
Files: 42
Last modified: 2025-01-15

# Machine mode (--json)
$ mycli project info --json
{"name": "my-app", "files": 42, "last_modified": "2025-01-15"}
```

### Backend Bridge Pattern

When the CLI wraps external software (e.g., a build tool, renderer, compiler):

```
1. Find executable (PATH → platform-specific dirs → error with install instructions)
2. Generate valid intermediate file (JSON/XML/config)
3. Invoke real software via subprocess with timeout + error handling
4. Verify output (check file exists, validate format, check magic bytes)
5. Return result path + metadata
```

Never reimplement what the backend already does. Generate the input, let the real tool process it, verify the output.

### Session Management Pattern

```
- Deep-copy snapshots on every mutation (50-level undo stack)
- Atomic JSON save with file locking (prevent concurrent corruption)
- Every mutation records a description for undo history
- Session state stored in project JSON file
```

### REPL Mode

When invoked without a subcommand, enter an interactive loop:

```
- Display banner with project name and skill path
- Accept commands with history (up-arrow recall)
- Support tab completion for command names
- `help` lists all commands
- `exit` / `quit` / Ctrl+D exits cleanly
```

## Command Group Templates

### Project Management
| Command | Description |
|---------|-------------|
| `project create <name>` | Create new project with default state |
| `project open <path>` | Load existing project file |
| `project save [path]` | Save current state |
| `project info` | Display project metadata |
| `project close` | Close without saving |

### Core Operations (customize per domain)
| Command | Description |
|---------|-------------|
| `<entity> list` | List all entities |
| `<entity> show <id>` | Show entity details |
| `<entity> create [options]` | Create new entity |
| `<entity> update <id> [options]` | Modify entity |
| `<entity> delete <id>` | Remove entity |

### Session
| Command | Description |
|---------|-------------|
| `session status` | Show current session info |
| `session undo` | Undo last mutation |
| `session redo` | Redo last undone action |
| `session history` | Show mutation history |

### Export
| Command | Description |
|---------|-------------|
| `export <format> [path]` | Export to specified format |
| `export list-formats` | Show available export formats |

## Three-Layer Testing Strategy

### Layer 1: Unit Tests (synthetic data)
- Create in-memory project state
- Test every command's effect on state
- No external dependencies
- Fast, deterministic

### Layer 2: Integration Tests (file format)
- Verify generated files are structurally valid
- Check JSON schema conformance
- Validate XML well-formedness
- No external software needed

### Layer 3: E2E Tests (real backend)
- Invoke actual external tools
- Verify real output (file magic bytes, format validation)
- Skip gracefully if backend not installed
- These are the "truth" tests

## Auto-Generated SKILL.md

After implementation, generate a SKILL.md that makes the CLI discoverable by agents:

```yaml
---
name: cli-<project-name>
version: 1.0.0
description: CLI interface for <project-name>
tags: [cli, <project-name>]
triggers:
  keywords: [<project-name>, <key-operations>]
---
# cli-<project-name>

## Available Commands
[auto-generated from CLI metadata]

## Examples
[auto-generated usage examples]

## Agent Guidance
- Use `--json` flag for all programmatic access
- Always `project create` or `project open` before mutations
- Check `session status` to understand current state
```

## Anti-Patterns

- **Reimplementing the backend**: The CLI is a wrapper, not a replacement. Use subprocess.
- **Missing `--json`**: Every command MUST support JSON output for agent consumption
- **No undo**: Mutations without session snapshots make the CLI dangerous for agents
- **Monolithic commands**: One command doing 5 things via flags. Split into separate commands.
- **Testing only happy path**: Test error cases, missing backends, corrupt state files
- **No REPL**: Agents and humans both benefit from interactive mode

## Integration Points

### With `codebase-understanding` skill
Use the knowledge graph as input to Phase 1. The graph tells you:
- What entities exist (nodes) → command groups
- What operations are possible (edges) → commands
- What the architecture looks like (layers) → command organization

### With `repo-augmentation` skill
This skill is Stage 2 of the repo-augmentation pipeline.

### With `tdd-workflow` skill
Phase 4-5 (test planning + implementation) follows TDD principles. Write TEST.md first, then implement tests, then verify all pass.

### With `verification-loop` skill
After implementation, run the verification loop to ensure all commands work correctly and tests pass.
