# Claude Code Export Guide

## How Claude Code Skills Work

Claude Code loads skills from two locations:
- **User-level**: `~/.claude/skills/` — available in every session
- **Project-level**: `.claude/skills/` — scoped to a specific repo

Each skill is a directory with a `SKILL.md` file. Claude Code reads the frontmatter `triggers.keywords` to decide when a skill is relevant.

## Installing iscagent Skills

### Using the install script (recommended)

```bash
# Install all skills to ~/.claude/skills/ (user-level)
./export/install-skills.sh

# Install specific skills
./export/install-skills.sh --skills "repo-augmentation,security-review"

# Install into a specific repo (project-level)
./export/install-skills.sh --target /path/to/your-project

# Preview without writing
./export/install-skills.sh --dry-run

# List available skills
./export/install-skills.sh --list
```

### Manual installation

```bash
# Copy a single skill
cp -r skills/security-review ~/.claude/skills/

# Copy all skills
cp -r skills/* ~/.claude/skills/
```

## Assembling a CLAUDE.md

If you want skills merged into a single `.claude/CLAUDE.md` file instead of separate skill directories:

```bash
mkdir -p /path/to/your-project/.claude

# Start with project context
echo "# Project Context" > /path/to/your-project/.claude/CLAUDE.md
echo "" >> /path/to/your-project/.claude/CLAUDE.md

# Append selected skills
for skill in skills/coding-standards skills/tdd-workflow skills/security-review; do
  echo -e "\n---\n" >> /path/to/your-project/.claude/CLAUDE.md
  cat "$skill/SKILL.md" >> /path/to/your-project/.claude/CLAUDE.md
done
```

## Skills as Slash Commands

Skills can also be exported as Claude Code commands:

```bash
mkdir -p /path/to/your-project/.claude/commands

# Each skill becomes a slash command
for skill_dir in skills/*/; do
  skill_name=$(basename "$skill_dir")
  [ -f "$skill_dir/SKILL.md" ] || continue
  cp "$skill_dir/SKILL.md" "/path/to/your-project/.claude/commands/${skill_name}.md"
done
```

Then invoke via `/skill-name` in Claude Code.

## Best Practices

- Prefer the install script over manual copying — it handles updates and deduplication
- Use project-level (`.claude/skills/`) for repo-specific skills
- Use user-level (`~/.claude/skills/`) for skills you want everywhere
- Skills with `triggers.keywords` in frontmatter are auto-suggested by Claude Code when relevant
