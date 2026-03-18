# Cursor Export Guide

## What Gets Exported

The `iscagent export --target cursor` command generates:

### .cursor/rules/soul.mdc

Generated from **SOUL.md** — the agent's identity, communication style, and values become Cursor's base rule file.

### .cursor/rules/rules.mdc

Generated from **RULES.md** — hard constraints and boundaries applied globally.

### .cursor/rules/{skill}.mdc

Each skill in `skills/` exports a dedicated rule file:
- `skills/terraform/` → `.cursor/rules/terraform.mdc`
- `skills/aws-ops/` → `.cursor/rules/aws-ops.mdc`
- `skills/ci-cd/` → `.cursor/rules/ci-cd.mdc`

### .mdc File Format

Cursor rule files use frontmatter:

```markdown
---
description: Brief description of this rule
globs: ["**/*.tf", "*.tfvars"]
alwaysApply: false
---

Rule content here...
```

- `globs` — file patterns that trigger this rule
- `alwaysApply: true` — for soul/rules that always apply
- `alwaysApply: false` — for skills triggered by file type

## Manual Assembly

```bash
mkdir -p .cursor/rules

# Soul — always active
cat > .cursor/rules/soul.mdc << 'EOF'
---
description: Agent identity and values
alwaysApply: true
---
EOF
cat SOUL.md >> .cursor/rules/soul.mdc

# Rules — always active
cat > .cursor/rules/rules.mdc << 'EOF'
---
description: Hard constraints and boundaries
alwaysApply: true
---
EOF
cat RULES.md >> .cursor/rules/rules.mdc
```
