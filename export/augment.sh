#!/bin/bash
# iscagent repo augmentation pipeline
#
# Orchestrates the full augmentation workflow:
#   Stage 1:   Understand — builds knowledge graph via Claude Code
#   Stage 1.5: Equip — runs automated skill recommender
#   Stage 2:   Generate — generates agent-native CLI via Claude Code
#
# Usage:
#   ./export/augment.sh <target-repo>
#   ./export/augment.sh <target-repo> --auto          # skip confirmations
#   ./export/augment.sh <target-repo> --skip-understand  # reuse existing knowledge graph
#   ./export/augment.sh <target-repo> --skip-cli        # skip CLI generation
#   ./export/augment.sh <target-repo> --dry-run         # preview only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISCAGENT_ROOT="$(dirname "$SCRIPT_DIR")"

# Defaults
AUTO=false
SKIP_UNDERSTAND=false
SKIP_CLI=false
DRY_RUN=false
TARGET=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --auto)       AUTO=true; shift ;;
    --skip-understand) SKIP_UNDERSTAND=true; shift ;;
    --skip-cli)   SKIP_CLI=true; shift ;;
    --dry-run)    DRY_RUN=true; shift ;;
    --help|-h)
      echo "iscagent repo augmentation pipeline"
      echo ""
      echo "Usage: ./export/augment.sh <target-repo> [options]"
      echo ""
      echo "Options:"
      echo "  --auto               Skip all confirmations"
      echo "  --skip-understand    Reuse existing knowledge graph"
      echo "  --skip-cli           Skip CLI generation"
      echo "  --dry-run            Preview without changes"
      echo ""
      echo "Pipeline:"
      echo "  Stage 1:   codebase-understanding -> .understand/knowledge-graph.json"
      echo "  Stage 1.5: skill-recommender -> .claude/skills/ (only relevant skills)"
      echo "  Stage 2:   cli-generation -> <project>-cli/"
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"; exit 1 ;;
    *)
      TARGET="$1"; shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Error: target repo path required"
  echo "Usage: ./export/augment.sh <target-repo>"
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║    iscagent — Repo Augmentation Pipeline ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Target: $TARGET"
echo ""

# Pre-flight checks
if [ ! -d "$TARGET/.git" ]; then
  echo "Warning: $TARGET is not a git repo. Incremental updates won't work."
fi

GRAPH="$TARGET/.understand/knowledge-graph.json"
HAS_GRAPH=false
if [ -f "$GRAPH" ]; then
  HAS_GRAPH=true
  echo "Found existing knowledge graph: $GRAPH"
fi

# ─── Stage 1: Understand ────────────────────────────────────────

if [ "$SKIP_UNDERSTAND" = true ] && [ "$HAS_GRAPH" = true ]; then
  echo ""
  echo "Stage 1: UNDERSTAND — skipped (using existing knowledge graph)"
elif [ "$DRY_RUN" = true ]; then
  echo ""
  echo "Stage 1: UNDERSTAND — would run codebase-understanding (dry run)"
else
  echo ""
  echo "━━━ Stage 1: UNDERSTAND ━━━"
  echo "Running codebase-understanding to build knowledge graph..."
  echo ""

  if ! command -v claude &> /dev/null; then
    echo "Error: 'claude' CLI not found. Install Claude Code first."
    exit 1
  fi

  claude -p "You are running the codebase-understanding skill. Analyze this repository and produce .understand/knowledge-graph.json following the exact schema from the codebase-understanding skill. Include: metadata (project name, languages, frameworks, integrations, database), nodes (files, modules with summaries, tags, complexity), edges (imports, inherits, calls, depends_on with weights), layers (3-7 architectural layers), and a guided tour (10-15 steps from entry point outward). Skip node_modules, vendor, .git, and library/ (third-party). Focus on application/, crons/, scripts/, node_server/, and database/." --cwd "$TARGET"

  if [ ! -f "$GRAPH" ]; then
    echo "Error: knowledge graph was not generated."
    exit 1
  fi
  echo ""
  echo "Knowledge graph generated: $GRAPH"
fi

# ─── Stage 1.5: Equip (Skill Recommender) ───────────────────────

echo ""
echo "━━━ Stage 1.5: EQUIP ━━━"
echo "Running automated skill recommender..."
echo ""

RECOMMEND_ARGS="$TARGET"
if [ "$AUTO" = true ]; then
  RECOMMEND_ARGS="$RECOMMEND_ARGS --auto"
fi
if [ "$DRY_RUN" = true ]; then
  RECOMMEND_ARGS="$RECOMMEND_ARGS --dry-run"
fi

python3 "$SCRIPT_DIR/recommend-skills.py" $RECOMMEND_ARGS

# ─── Stage 2: Generate CLI ──────────────────────────────────────

if [ "$SKIP_CLI" = true ]; then
  echo ""
  echo "Stage 2: GENERATE — skipped"
elif [ "$DRY_RUN" = true ]; then
  echo ""
  echo "Stage 2: GENERATE — would run cli-generation (dry run)"
else
  echo ""
  echo "━━━ Stage 2: GENERATE ━━━"
  echo "Generating agent-native CLI from knowledge graph..."
  echo ""

  if ! command -v claude &> /dev/null; then
    echo "Error: 'claude' CLI not found."
    exit 1
  fi

  PROJECT_NAME=$(python3 -c "import json; print(json.load(open('$GRAPH'))['metadata']['projectName'])" 2>/dev/null || basename "$TARGET")

  claude -p "You are running the cli-generation skill. Read .understand/knowledge-graph.json and generate an agent-native CLI for this project.

1. First create .understand/cli-design.json deriving command groups from the knowledge graph layers, nodes, and edges.
2. Then generate the CLI at ${PROJECT_NAME}-cli/ using Python + Click with these requirements:
   - Every command supports --json flag
   - Command groups derived from knowledge graph layers and entities
   - Include: code (stats, layers, tour, find, deps), route, cron, db, integration, session commands
   - Include setup.py, requirements.txt, tests/, and skills/SKILL.md
3. Run the tests to verify all commands work.

Follow the cli-generation skill exactly. Use the knowledge graph as the source of truth." --cwd "$TARGET"

  echo ""
  echo "CLI generated at: $TARGET/${PROJECT_NAME}-cli/"
fi

# ─── Summary ────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║    Augmentation Complete                 ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Artifacts:"
[ -f "$GRAPH" ] && echo "  .understand/knowledge-graph.json"
[ -f "$TARGET/.understand/cli-design.json" ] && echo "  .understand/cli-design.json"
[ -d "$TARGET/.claude/skills" ] && echo "  .claude/skills/ ($(ls "$TARGET/.claude/skills/" 2>/dev/null | wc -l | tr -d ' ') skills)"
for d in "$TARGET"/*-cli/; do
  [ -d "$d" ] && echo "  $(basename "$d")/"
done
echo ""
echo "Next steps:"
echo "  cd $TARGET"
echo "  git checkout -b feature/repo-augmentation"
echo "  git add .understand/ .claude/skills/ *-cli/"
echo "  git commit -m 'feat: add repo augmentation'"
