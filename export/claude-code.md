# Claude Code Export Guide

## What Gets Exported

The `iscagent export --target claude-code` command generates:

### .claude/CLAUDE.md

Assembled from:
1. **SOUL.md** — becomes the project context and personality section
2. **RULES.md** — becomes the behavioral constraints section
3. **skills/*.SKILL.md** — each skill's instructions appended as a section
4. **knowledge/** — referenced as context the agent should consult

### .claude/settings.json

Generated from:
- **tools/** — tool permissions mapped to `allowedTools`
- **RULES.md** — destructive operation rules mapped to permission prompts

### .claude/commands/

Each skill in `skills/` can export a slash command:
- `skills/terraform/` → `.claude/commands/terraform.md`
- `skills/aws-ops/` → `.claude/commands/aws-ops.md`

## Manual Assembly

Until the CLI is built, you can manually assemble a CLAUDE.md:

```bash
# Concatenate soul + rules + skills into CLAUDE.md
cat SOUL.md > .claude/CLAUDE.md
echo -e "\n---\n" >> .claude/CLAUDE.md
cat RULES.md >> .claude/CLAUDE.md
for skill in skills/*/SKILL.md; do
  echo -e "\n---\n" >> .claude/CLAUDE.md
  cat "$skill" >> .claude/CLAUDE.md
done
```
