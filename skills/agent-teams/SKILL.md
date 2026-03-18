---
name: agent-teams
version: 1.0.0
description: Team composition templates for coordinated multi-agent tasks
author: iscmga
tags: [agents, teams, orchestration, roles]
triggers:
  keywords: [team, swarm, multi-agent, coordinate, complex task, large task, feature, refactor]
---

# Agent Teams

## Principle

Match team composition to task type. Smaller, focused teams outperform large swarms. Each role has a clear responsibility and produces a defined artifact.

## Team Templates

### Bug Fix (4 agents)

| Role | Responsibility | Produces |
|------|---------------|----------|
| Researcher | Reproduce bug, trace root cause, gather context | `handoffs/research.md` — reproduction steps, root cause analysis |
| Implementer | Write the fix based on research findings | The code change |
| Tester | Write/update tests that cover the fix | Test files |
| Reviewer | Review fix for correctness, side effects, regressions | `handoffs/review.md` — approval or change requests |

**Sequence:** Researcher → Implementer → Tester + Reviewer (parallel)

### Feature Development (5 agents)

| Role | Responsibility | Produces |
|------|---------------|----------|
| Architect | Design approach, identify affected components | `handoffs/design.md` — approach, interfaces, risks |
| Implementer | Build the feature per design | The code |
| Tester | Write unit + integration tests | Test files |
| Reviewer | Code quality, security, patterns compliance | `handoffs/review.md` |
| Documenter | Update docs, README, inline comments if needed | Doc changes |

**Sequence:** Architect → Implementer → Tester + Reviewer + Documenter (parallel)

### Refactor (3 agents)

| Role | Responsibility | Produces |
|------|---------------|----------|
| Analyst | Map current code, identify dependencies, plan changes | `handoffs/analysis.md` — dependency map, risk areas |
| Implementer | Execute refactor per analysis | The code changes |
| Reviewer | Verify behavior preservation, no regressions | `handoffs/review.md` |

**Sequence:** Analyst → Implementer → Reviewer

### Security Audit (3 agents)

| Role | Responsibility | Produces |
|------|---------------|----------|
| Scanner | Run automated checks (Prowler, Security Hub, OWASP) | `handoffs/scan-results.md` |
| Analyst | Triage findings, assess severity, identify false positives | `handoffs/triage.md` — prioritized findings |
| Remediator | Fix critical/high findings | The code fixes |

**Sequence:** Scanner → Analyst → Remediator

### Performance Investigation (3 agents)

| Role | Responsibility | Produces |
|------|---------------|----------|
| Profiler | Identify bottlenecks, gather metrics | `handoffs/profile.md` — bottleneck analysis |
| Optimizer | Implement targeted optimizations | The code changes |
| Validator | Benchmark before/after, verify improvements | `handoffs/benchmark.md` |

**Sequence:** Profiler → Optimizer → Validator

### Infrastructure Change (4 agents)

| Role | Responsibility | Produces |
|------|---------------|----------|
| Architect | Design infrastructure change, assess blast radius | `handoffs/design.md` |
| Implementer | Write Terraform/IaC code | The .tf files |
| Security Reviewer | Check IAM, network, encryption, compliance | `handoffs/security-review.md` |
| Validator | Run plan, verify no unintended changes | `handoffs/plan-output.md` |

**Sequence:** Architect → Implementer → Security Reviewer + Validator (parallel)

## How to Use

### Claude Code

The coordinator (your main session) follows this pattern:

1. **Identify task type** → pick the matching team template
2. **Write coordinator.md** with task decomposition (see agent-coordination skill)
3. **Spawn agents sequentially or in parallel** per the template's sequence using the Agent tool
4. **Each agent reads coordinator.md**, does its work, writes its handoff file
5. **Coordinator reads all handoffs** and integrates

### Cursor

Run each role as a separate chat session, passing context through the handoff files in the workspace.

## Guidelines

- Don't create teams for simple tasks — one agent is fine for small changes
- Use the smallest team that covers the task — 3 agents beats 6 if 3 is enough
- Every agent must have exactly one clear deliverable
- Parallel agents must not modify the same files
- The coordinator is always human-in-the-loop for destructive operations
