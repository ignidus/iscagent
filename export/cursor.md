# Cursor Export Guide

## How Cursor Rules Work

Cursor rules live in `.cursor/rules/` as `.md` or `.mdc` files. They're version-controlled with your project.

### Rule Types

| Type | Frontmatter | When Applied |
|------|-------------|--------------|
| **Always Apply** | `alwaysApply: true` | Every session |
| **Apply Intelligently** | `alwaysApply: false` + `description` | Agent decides based on description |
| **Apply to Specific Files** | `globs: ["**/*.ts"]` | When matching files are open |
| **Apply Manually** | No frontmatter, or `alwaysApply: false` | Only when @-mentioned in chat |

### .mdc File Format

```yaml
---
description: "Concise summary so the agent knows when this rule is relevant"
globs: ["**/*.tf", "*.tfvars"]
alwaysApply: false
---

Rule content here (markdown)...
```

Keep rules under 500 lines. Split larger ones into multiple composable rules.

## Installing iscagent Skills as Cursor Rules

### All skills

```bash
mkdir -p /path/to/your-project/.cursor/rules

for skill_dir in skills/*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"
  [ -f "$skill_file" ] || continue

  # Extract globs from SKILL.md frontmatter if present
  globs=$(grep -A1 'globs:' "$skill_file" | tail -1 | sed 's/^[ ]*//')

  # Write .mdc with frontmatter
  cat > "/path/to/your-project/.cursor/rules/${skill_name}.mdc" << EOF
---
description: $(grep '^description:' "$skill_file" | sed 's/^description: //')
alwaysApply: false
---
EOF
  # Strip YAML frontmatter from SKILL.md and append content
  sed '1,/^---$/{ /^---$/,/^---$/d }' "$skill_file" >> "/path/to/your-project/.cursor/rules/${skill_name}.mdc"
done
```

### Specific skills

```bash
# Example: install just security-review as an always-apply rule
cat > .cursor/rules/security-review.mdc << 'EOF'
---
description: "Security review checklist for auth, user input, secrets, APIs"
alwaysApply: true
---
EOF
sed '1,/^---$/{ /^---$/,/^---$/d }' skills/security-review/SKILL.md >> .cursor/rules/security-review.mdc
```

### With glob triggers

Some skills have natural file-pattern triggers:

```bash
# Docker patterns — triggered by Docker files
cat > .cursor/rules/docker-patterns.mdc << 'EOF'
---
description: "Docker and container best practices"
globs: ["**/Dockerfile", "**/docker-compose*.yml", "**/.dockerignore"]
alwaysApply: false
---
EOF
sed '1,/^---$/{ /^---$/,/^---$/d }' skills/docker-patterns/SKILL.md >> .cursor/rules/docker-patterns.mdc
```

## Alternative: AGENTS.md

For simpler setups, Cursor also supports `AGENTS.md` files:
- Place `AGENTS.md` at the project root for global instructions
- Place `AGENTS.md` in subdirectories for scoped instructions
- No frontmatter needed — just plain markdown
- More specific (deeper) files take precedence

## Best Practices

- Keep each rule under 500 lines
- Use `description` field so the agent can decide relevance intelligently
- Use `globs` for file-type-specific skills (docker, terraform, database)
- Use `alwaysApply: true` sparingly — only for universal standards like security
- Point to canonical examples rather than copying full code into rules
- Nest rules in subdirectories for organization if needed
