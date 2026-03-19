#!/bin/bash
# iscagent skill installer for Claude Code
#
# Usage:
#   ./export/install-skills.sh                    # install all skills to ~/.claude/skills/
#   ./export/install-skills.sh --skills "repo-augmentation,cli-generation"  # specific skills
#   ./export/install-skills.sh --target project    # install to .claude/skills/ in current dir
#   ./export/install-skills.sh --target user       # install to ~/.claude/skills/ (default)
#   ./export/install-skills.sh --list              # list available skills
#   ./export/install-skills.sh --dry-run           # show what would be installed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISCAGENT_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$ISCAGENT_ROOT/skills"

# Defaults
TARGET="user"
SELECTED_SKILLS=""
DRY_RUN=false
LIST_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --skills)
      SELECTED_SKILLS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --list)
      LIST_ONLY=true
      shift
      ;;
    --help|-h)
      echo "iscagent skill installer for Claude Code"
      echo ""
      echo "Usage:"
      echo "  ./export/install-skills.sh                                    # install all to ~/.claude/skills/"
      echo "  ./export/install-skills.sh --skills \"skill1,skill2\"           # install specific skills"
      echo "  ./export/install-skills.sh --target project                   # install to ./.claude/skills/"
      echo "  ./export/install-skills.sh --target user                      # install to ~/.claude/skills/ (default)"
      echo "  ./export/install-skills.sh --target /path/to/repo             # install to specific repo"
      echo "  ./export/install-skills.sh --list                             # list available skills"
      echo "  ./export/install-skills.sh --dry-run                          # preview without installing"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Resolve target directory
case "$TARGET" in
  user)
    DEST="$HOME/.claude/skills"
    ;;
  project)
    DEST=".claude/skills"
    ;;
  *)
    # Treat as a path
    DEST="$TARGET/.claude/skills"
    ;;
esac

# Get all available skills
ALL_SKILLS=$(ls -d "$SKILLS_SRC"/*/ 2>/dev/null | xargs -I{} basename {})

# List mode
if [ "$LIST_ONLY" = true ]; then
  echo "Available iscagent skills:"
  echo ""
  for skill in $ALL_SKILLS; do
    DESC=$(grep -m1 '^description:' "$SKILLS_SRC/$skill/SKILL.md" 2>/dev/null | sed 's/^description: //' || echo "No description")
    printf "  %-30s %s\n" "$skill" "$DESC"
  done
  echo ""
  echo "Total: $(echo "$ALL_SKILLS" | wc -w | tr -d ' ') skills"
  exit 0
fi

# Filter skills if --skills specified
if [ -n "$SELECTED_SKILLS" ]; then
  INSTALL_SKILLS=""
  IFS=',' read -ra SKILL_ARRAY <<< "$SELECTED_SKILLS"
  for skill in "${SKILL_ARRAY[@]}"; do
    skill=$(echo "$skill" | tr -d ' ')
    if [ -d "$SKILLS_SRC/$skill" ]; then
      INSTALL_SKILLS="$INSTALL_SKILLS $skill"
    else
      echo "WARNING: Skill '$skill' not found in $SKILLS_SRC"
    fi
  done
else
  INSTALL_SKILLS="$ALL_SKILLS"
fi

# Trim whitespace
INSTALL_SKILLS=$(echo "$INSTALL_SKILLS" | xargs)

if [ -z "$INSTALL_SKILLS" ]; then
  echo "No skills to install."
  exit 1
fi

SKILL_COUNT=$(echo "$INSTALL_SKILLS" | wc -w | tr -d ' ')

echo "iscagent skill installer"
echo "========================"
echo "Source:  $SKILLS_SRC"
echo "Target:  $DEST"
echo "Skills:  $SKILL_COUNT"
echo ""

# Install each skill
INSTALLED=0
UPDATED=0
SKIPPED=0

for skill in $INSTALL_SKILLS; do
  SRC_DIR="$SKILLS_SRC/$skill"
  DEST_DIR="$DEST/$skill"

  if [ ! -f "$SRC_DIR/SKILL.md" ]; then
    echo "  SKIP  $skill (no SKILL.md)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Check if already installed and unchanged
  if [ -f "$DEST_DIR/SKILL.md" ]; then
    if diff -q "$SRC_DIR/SKILL.md" "$DEST_DIR/SKILL.md" > /dev/null 2>&1; then
      echo "  OK    $skill (unchanged)"
      SKIPPED=$((SKIPPED + 1))
      continue
    else
      ACTION="UPDATE"
      UPDATED=$((UPDATED + 1))
    fi
  else
    ACTION="NEW"
    INSTALLED=$((INSTALLED + 1))
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "  $ACTION $skill → $DEST_DIR (dry run)"
  else
    mkdir -p "$DEST_DIR"
    # Copy SKILL.md and any supporting files
    cp "$SRC_DIR/SKILL.md" "$DEST_DIR/SKILL.md"
    # Copy non-SKILL.md files (supporting configs, scripts, etc.)
    find "$SRC_DIR" -maxdepth 1 -type f ! -name "SKILL.md" -exec cp {} "$DEST_DIR/" \; 2>/dev/null
    echo "  $ACTION $skill → $DEST_DIR"
  fi
done

echo ""
echo "Done: $INSTALLED new, $UPDATED updated, $SKIPPED unchanged"

if [ "$DRY_RUN" = true ]; then
  echo "(Dry run — nothing was written)"
fi
