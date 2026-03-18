---
name: model-routing
version: 1.0.0
description: Decision framework for selecting the right model for each task
author: iscmga
tags: [models, routing, cost, optimization]
triggers:
  keywords: [model, routing, cost, haiku, sonnet, opus, cheap, expensive, token]
---

# Model Routing

## Principle

Use the cheapest model that meets quality requirements. Not every task needs the most powerful model. Route by task complexity to extend budget and reduce latency.

## Routing Table

| Task Complexity | Model Tier | Examples |
|----------------|-----------|---------|
| **Simple** | Haiku | Formatting, renaming, simple lookups, generating boilerplate, summarizing short text |
| **Standard** | Sonnet | Code implementation, bug fixes, test writing, code review, documentation |
| **Complex** | Opus | Architecture design, multi-file refactoring, security analysis, debugging subtle issues, ambiguous requirements |

## Decision Framework

Ask these questions in order:

1. **Is this a mechanical transform?** (rename, reformat, add imports) → **Haiku**
2. **Is the task well-defined with clear inputs/outputs?** (implement this function, write tests for X) → **Sonnet**
3. **Does it require deep reasoning, multi-step planning, or judgment calls?** (design a system, debug a race condition, assess security posture) → **Opus**

## Claude Code Configuration

Claude Code model can be set per-session:
- Default to Sonnet for everyday work
- Switch to Opus for architecture, complex debugging, or multi-agent coordination
- Use Haiku for subagents doing simple, focused tasks (lookups, formatting)

Subagents spawned via the Agent tool can specify `subagent_type`:
- `Explore` — research tasks, can use Sonnet
- Default — task execution, matches main session model

## Cursor Configuration

Cursor allows model selection per chat. Apply the same framework:
- Routine coding → Sonnet
- Complex design decisions → Opus
- Quick questions → Haiku (if available)

## Building AI Applications

When building apps that call the Claude API, route at the application level:

```python
def select_model(task_complexity: str) -> str:
    routing = {
        "simple": "claude-haiku-4-5-20251001",
        "standard": "claude-sonnet-4-6",
        "complex": "claude-opus-4-6",
    }
    return routing.get(task_complexity, "claude-sonnet-4-6")
```

## Cost Impact

Approximate relative cost per million tokens (input):

| Model | Relative Cost | Best For |
|-------|--------------|----------|
| Haiku | 1x | High-volume, simple tasks |
| Sonnet | 3-5x | Balanced quality/cost |
| Opus | 15-25x | Highest quality, complex reasoning |

Routing 60% of tasks to Sonnet and 30% to Haiku instead of sending everything to Opus can reduce costs by 70-80%.

## Guidelines

- Default to Sonnet — it handles most programming tasks well
- Upgrade to Opus when Sonnet produces incorrect or shallow results
- Downgrade to Haiku for subagents doing narrowly scoped lookups
- For coordinated agent teams: coordinator uses Opus, workers use Sonnet or Haiku based on role
- Monitor quality — if a cheaper model consistently fails at a task type, upgrade the routing for that type
