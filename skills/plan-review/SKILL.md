---
name: plan-review
version: 1.0.0
description: Architecture review before implementation. Walk through design, failure modes, scope, and test strategy before writing code.
author: iscmga
tags: [architecture, design-review, planning, eng-review, pre-implementation]
triggers:
  globs: []
  keywords: [plan review, architecture review, design review, eng review, review the plan, before we build]
---

# Plan Review

Engineering manager-mode architecture review. Locks in execution plans before implementation by walking through architecture, failure modes, scope, and test strategy. One issue per question — never batch. Inspired by gstack's plan-eng-review methodology.

## When to Activate

- Before starting a complex feature or infrastructure change
- "Review this plan before I build it"
- "Is this architecture sound?"
- "Let's think through this design"
- When a task touches >5 files or >2 services
- Before any production infrastructure migration

## Core Principles

1. **One issue per question**: Never batch multiple concerns. Each gets its own discussion.
2. **Stop after each section**: Get user confirmation before moving to the next.
3. **Concrete alternatives**: Don't just say "this could be better" — propose a specific alternative.
4. **Explicit scope boundary**: Define what's NOT in scope and why.
5. **Failure modes first**: Every design decision should have its failure scenario identified.

## Workflow

### Section 1: Architecture Review

Walk through the proposed design:

**System Design**
- What components are involved?
- How do they communicate?
- Where does data flow?

**Dependency Analysis**
- What does this depend on? (services, APIs, databases)
- What depends on this? (downstream consumers)
- What's the blast radius if this breaks?

**Failure Scenarios**
For each component, answer:
- What happens if this component is unavailable?
- What happens if it's slow (5x normal latency)?
- What happens if it returns unexpected data?
- Is there a fallback or degraded mode?

Present findings. **Stop and ask**: "Any concerns with the architecture before I continue to scope?"

### Section 2: Scope Challenge

**Scope Assessment**
- How many files will this change? (flag >8 as a smell)
- How many services/modules are affected? (flag >2 as a smell)
- Is there a smaller version that delivers 80% of the value?

**Narrowest Wedge**
- What's the absolute smallest change that solves the core problem?
- Can this be done in phases? What's Phase 1?

**NOT in Scope**
Define explicitly what this change does NOT include, and why:
```
NOT IN SCOPE:
- Migration of existing data (Phase 2)
- Multi-region support (not needed for current scale)
- UI changes (handled by separate ticket)
```

Present findings. **Stop and ask**: "Agree with the scope boundary?"

### Section 3: Infrastructure Review (if applicable)

**Resource Design**
- Are instance types appropriate for the workload?
- Is auto-scaling configured with sensible min/max?
- Are backup/snapshot policies in place?
- Is encryption enabled (at rest + in transit)?

**Network Design**
- CIDR ranges: any overlaps?
- Security groups: principle of least privilege?
- DNS: correct records and TTLs?
- Cross-account access: explicitly documented?

**Cost Impact**
- What's the estimated monthly cost?
- Are there cheaper alternatives that meet requirements?
- Is there a kill switch / scale-to-zero option?

**State Management**
- How is Terraform state managed?
- Any shared state risks?
- Lock configuration correct?

Present findings. **Stop and ask**: "Any concerns with the infrastructure design?"

### Section 4: Test Strategy

**What to Test**
- Happy path: does the change work as intended?
- Failure path: does the system degrade gracefully?
- Edge cases: what about boundary conditions?
- Rollback: can the change be safely reverted?

**How to Test**
- Pre-deploy: `terraform plan`, unit tests, integration tests
- Post-deploy: health checks, smoke tests, monitoring
- Rollback test: verify the rollback procedure works

**Acceptance Criteria**
Define clear, verifiable criteria:
```
ACCEPTANCE:
- [ ] terraform plan shows only expected changes
- [ ] Health checks pass within 5 minutes of deploy
- [ ] Monitoring dashboard shows no error spike
- [ ] Rollback procedure tested in staging
```

Present findings. **Stop and ask**: "Agree with the test strategy?"

### Section 5: Summary and Decision

Produce a design document:

```markdown
## Design: <title>

### Decision
<One-paragraph summary of what will be built and why>

### Architecture
<ASCII diagram of component interactions>

### Scope
- IN: <what's included>
- OUT: <what's excluded and why>

### Failure Modes
| Component | Failure | Impact | Mitigation |
|-----------|---------|--------|------------|
| ... | ... | ... | ... |

### Test Plan
- Pre-deploy: ...
- Post-deploy: ...
- Rollback: ...

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ... | ... | ... | ... |

### Cost
- Estimated monthly: $X
- Cost optimization: ...

### Timeline
- Phase 1: <scope> — <estimate>
- Phase 2: <scope> — <estimate>
```

## Anti-Patterns

- **Analysis paralysis**: The review should take 15-30 minutes, not days. If the design is that complex, it needs to be broken down.
- **Review after implementation**: The whole point is to review BEFORE writing code. Reviewing finished work is a code review, not a plan review.
- **Skipping failure modes**: "It won't fail" is not an acceptable answer. Everything fails eventually.
- **Vague scope**: "We'll figure out the details later" means scope creep is guaranteed.
- **No test strategy**: "We'll test it manually" is not a test strategy.

## Integration Points

### With `review` skill
Plan review happens BEFORE implementation. Code review (review skill) happens AFTER.

### With `ship` skill
The design document from plan review should be referenced in the PR created by ship.

### With `investigate` skill
Failure modes identified in plan review inform the investigation playbook when things go wrong.
