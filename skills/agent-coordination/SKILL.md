---
name: agent-coordination
version: 1.0.0
description: Memory-based agent communication protocol for multi-agent workflows
author: iscmga
tags: [agents, coordination, multi-agent, subagents]
triggers:
  keywords: [subagent, multi-agent, coordinate, delegate, parallel, orchestrate]
---

# Agent Coordination

## Principle

Agents coordinate through shared memory files, not direct messaging. Each agent reads inputs from and writes outputs to well-known paths. This works natively in Claude Code (via the Agent tool + workspace files) and Cursor (via workspace files).

## Memory Layout

```
memory/
  runtime/
    coordinator.md        # Current task decomposition and status
    handoffs/
      {agent-role}.md     # Output from each agent role
    decisions.md          # Key decisions made during coordination
```

## Protocol

### 1. Coordinator Writes Task Decomposition

The coordinator (main Claude Code session) decomposes work and writes:

```markdown
# Task: [description]

## Subtasks
- [ ] research: [what to investigate]
- [ ] implement: [what to build]
- [ ] test: [what to verify]
- [ ] review: [what to check]

## Constraints
- [shared context all agents need]

## Status: in-progress
```

### 2. Subagents Write Results to Handoff Files

Each subagent writes its output to `memory/runtime/handoffs/{role}.md`:

```markdown
# Research Output

## Findings
- [key finding 1]
- [key finding 2]

## Recommendations
- [recommendation]

## Files Touched
- path/to/file.ts:42

## Status: complete
```

### 3. Coordinator Reads and Integrates

The coordinator reads all handoff files, integrates results, and updates `coordinator.md` status.

## Claude Code Implementation

Use the `Agent` tool to spawn subagents. Each subagent gets a focused prompt:

```
Subagent prompt pattern:
"Read memory/runtime/coordinator.md for context.
Do [specific task].
Write your results to memory/runtime/handoffs/{role}.md.
Do not modify files outside your scope."
```

Spawn independent subagents in parallel. Wait for dependent ones sequentially.

## Cursor Implementation

In Cursor, coordination happens across chat sessions:
1. First session decomposes and writes coordinator.md
2. Subsequent sessions each read coordinator.md and write their handoff file
3. Final session reads all handoffs and integrates

## Rules

- Max 6-8 active agents for tight coordination
- Every agent must read coordinator.md before starting
- Every agent must write a handoff file when done
- Handoff files include status (in-progress, complete, blocked, failed)
- Coordinator checks all handoffs before declaring task complete
- Clean up memory/runtime/handoffs/ after integration

## Anti-Drift

- Keep subtasks small and focused (one clear deliverable per agent)
- Include constraints in coordinator.md that all agents must follow
- Coordinator validates outputs match the original task decomposition
- If an agent's output diverges, re-scope and re-delegate rather than patching
