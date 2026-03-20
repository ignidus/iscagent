---
name: investigate
version: 1.0.0
description: Systematic root-cause debugging and incident investigation. No fixes without understanding the problem first.
author: iscmga
tags: [debugging, investigation, incident, root-cause, troubleshooting]
triggers:
  globs: []
  keywords: [investigate, debug, root cause, incident, troubleshoot, why is this broken, what went wrong]
---

# Investigate

Systematic four-phase debugging methodology. The cardinal rule: **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.** Prevents superficial fixes that mask underlying problems. Inspired by gstack's investigate methodology.

## When to Activate

- "Why is this broken?"
- "Investigate this error"
- "Something went wrong in production"
- When a deployment fails and the cause isn't obvious
- When terraform plan shows unexpected changes
- When an incident is reported

## Core Principles

1. **Root cause first**: Never apply a fix until you understand WHY something broke.
2. **Evidence over intuition**: Every hypothesis must be tested, not assumed.
3. **Minimal blast radius**: Fixes should be scoped to the affected components only.
4. **Escalation triggers**: Know when to stop investigating and ask for help.

## Phase 1: Gather Symptoms

Collect all available evidence before forming any hypothesis.

### For Application/Service Issues
```bash
# Recent logs
aws logs tail /aws/ecs/<service> --since 1h --profile <profile>

# Service status
aws ecs describe-services --cluster <cluster> --services <service> --profile <profile>

# Recent deployments
aws ecs describe-task-definition --task-definition <task-def> --profile <profile>

# Health check status
aws elbv2 describe-target-health --target-group-arn <arn> --profile <profile>
```

### For Terraform Issues
```bash
# What changed?
git log --oneline -10
git diff HEAD~1

# Current state
terraform state list
terraform show <resource>

# Plan to see drift
terraform plan
```

### For Infrastructure Issues
```bash
# CloudTrail for recent API calls
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=<resource> --profile <profile>

# Config changes
aws configservice get-resource-config-history --resource-type <type> --resource-id <id> --profile <profile>
```

Document every symptom:
```
SYMPTOMS:
1. [timestamp] <what was observed>
2. [timestamp] <error message or behavior>
3. [timestamp] <related observation>

TIMELINE:
- Last known good: <when it was last working>
- First failure: <when it was first noticed>
- What changed between: <deployments, config changes, etc.>
```

## Phase 2: Pattern Analysis

Categorize the symptoms against known failure patterns:

### Infrastructure Failure Patterns

| Pattern | Symptoms | Common Cause |
|---------|----------|-------------|
| **Deployment rollback** | Tasks failing health checks, old task definition running | Bad container image, missing env vars, port mismatch |
| **Terraform drift** | Plan shows changes nobody made | Manual console changes, another pipeline, auto-scaling |
| **Permission denied** | 403/AccessDenied in logs | IAM policy change, SCP update, missing role trust |
| **Network timeout** | Connection refused, timeout errors | Security group change, NACL, route table, DNS |
| **Resource exhaustion** | OOM kills, disk full, CPU throttle | Undersized instances, missing limits, memory leak |
| **State corruption** | Terraform errors about existing resources | Concurrent applies, manual state edits, import issues |
| **Certificate issues** | TLS handshake failures, HTTPS errors | Expired cert, wrong domain, missing SAN |
| **DNS propagation** | Intermittent failures, some users affected | TTL, cached records, split-horizon issues |

### Cross-Reference

Check if this matches a known prior incident:
- Search JIRA for similar symptoms
- Check git log for recent related changes
- Review recent CloudTrail events

## Phase 3: Hypothesis Testing

For each plausible hypothesis:

1. **State the hypothesis clearly**: "The service is failing because X"
2. **Define a test**: "If X is the cause, then Y should be true"
3. **Run the test**: Execute the verification
4. **Record the result**: Confirmed or eliminated

```
HYPOTHESIS 1: Health check failing due to missing env var
TEST: Check task definition for required env vars
RESULT: CONFIRMED — DB_HOST is missing from latest task definition

HYPOTHESIS 2: Security group blocking port 8080
TEST: Check inbound rules on sg-xxxxx
RESULT: ELIMINATED — port 8080 is open from ALB security group
```

### Escalation Triggers

Stop investigating and escalate if:
- **3 failed hypotheses** with no new leads
- **Production impact** exceeding 30 minutes without root cause
- **Multi-service cascade** affecting more than one team's services
- **Data integrity** concerns (corruption, inconsistency)
- **Security incident** indicators (unauthorized access, exfiltration)

## Phase 4: Fix Implementation

Only after root cause is confirmed:

### Fix Scope
- Edit ONLY the files/resources directly related to the root cause
- Never "fix forward" by adding workarounds elsewhere
- If the fix requires changes to more than 3 files, re-evaluate scope

### Fix Verification
1. Apply the minimal fix
2. Verify the specific symptom is resolved
3. Check for regression — did the fix break anything else?
4. Document the fix and root cause

### Post-Fix Report

```markdown
## Incident Report

**Summary:** <one-line description>
**Duration:** <first symptom> to <resolution>
**Impact:** <what was affected>

### Root Cause
<Detailed explanation of what went wrong and why>

### Timeline
- HH:MM — First symptom observed
- HH:MM — Investigation started
- HH:MM — Root cause identified
- HH:MM — Fix applied
- HH:MM — Verified resolved

### Fix Applied
- <file:line — what was changed>
- <commit hash>

### Prevention
- <What would prevent this from happening again>
- <Monitoring/alerting to add>
- <Process changes>
```

## Investigation Tools

### AWS
```bash
# Recent errors in CloudWatch
aws logs filter-log-events --log-group-name <group> --filter-pattern "ERROR" --start-time <epoch-ms>

# Resource configuration history
aws configservice get-resource-config-history --resource-type AWS::EC2::SecurityGroup --resource-id <id>

# Who did what (CloudTrail)
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=<api-call>
```

### Terraform
```bash
# Show specific resource state
terraform state show <resource.name>

# Check for state lock
terraform force-unlock <lock-id>  # only after confirming lock holder

# Import missing resource
terraform import <resource.name> <id>
```

### Network
```bash
# DNS resolution
dig +short <hostname>
nslookup <hostname>

# Port connectivity
nc -zv <host> <port>

# Route tracing
traceroute <host>
```

## Anti-Patterns

- **Shotgun debugging**: Changing multiple things at once to "see what fixes it." Change one thing at a time.
- **Fix without understanding**: "I don't know why, but this fixes it" is not acceptable. Understand the cause.
- **Ignoring the timeline**: The timeline is your strongest tool. What changed between "working" and "broken"?
- **Skipping verification**: A fix that hasn't been verified is just another hypothesis.
- **Scope creep**: "While I'm in here, let me also fix..." — NO. Fix the issue, ship it, then address other findings separately.

## Integration Points

### With `careful` skill
Investigation should use careful mode to prevent accidental destructive actions while debugging production.

### With `review` skill
Post-fix changes should go through review before merge.

### With `retro` skill
Investigation findings feed into retrospectives for process improvement.
