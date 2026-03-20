#!/bin/bash
# iscagent repo augmentation pipeline
#
# Orchestrates the full augmentation workflow:
#   Stage 1: Understand — builds knowledge graph via Claude Code
#   Stage 2: Document  — generates docs/ from knowledge graph via Claude Code
#   Stage 3: Equip     — runs automated skill recommender (reads graph + docs)
#   Stage 4: Generate  — generates agent-native CLI via Claude Code
#
# Usage:
#   ./export/augment.sh <target-repo>
#   ./export/augment.sh <target-repo> --auto          # skip confirmations
#   ./export/augment.sh <target-repo> --skip-understand  # reuse existing knowledge graph
#   ./export/augment.sh <target-repo> --skip-docs      # skip docs generation
#   ./export/augment.sh <target-repo> --skip-cli        # skip CLI generation
#   ./export/augment.sh <target-repo> --dry-run         # preview only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISCAGENT_ROOT="$(dirname "$SCRIPT_DIR")"

# Defaults
AUTO=false
SKIP_UNDERSTAND=false
SKIP_DOCS=false
SKIP_CLI=false
DRY_RUN=false
TARGET=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --auto)       AUTO=true; shift ;;
    --skip-understand) SKIP_UNDERSTAND=true; shift ;;
    --skip-docs)  SKIP_DOCS=true; shift ;;
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
      echo "  --skip-docs          Skip docs generation"
      echo "  --skip-cli           Skip CLI generation"
      echo "  --dry-run            Preview without changes"
      echo ""
      echo "Pipeline:"
      echo "  Stage 1: codebase-understanding -> .understand/knowledge-graph.json"
      echo "  Stage 2: docs-generation -> docs/ (from knowledge graph)"
      echo "  Stage 3: skill-recommender -> .claude/skills/ (reads graph + docs)"
      echo "  Stage 4: cli-generation -> <project>-cli/"
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

DOCS_DIR="$TARGET/docs"
HAS_DOCS=false
if [ -d "$DOCS_DIR" ] && [ -f "$DOCS_DIR/README.md" ]; then
  HAS_DOCS=true
  echo "Found existing docs: $DOCS_DIR"
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

# ─── Stage 2: Document ──────────────────────────────────────────

if [ "$SKIP_DOCS" = true ] && [ "$HAS_DOCS" = true ]; then
  echo ""
  echo "Stage 2: DOCUMENT — skipped (using existing docs)"
elif [ "$SKIP_DOCS" = true ]; then
  echo ""
  echo "Stage 2: DOCUMENT — skipped"
elif [ "$DRY_RUN" = true ]; then
  echo ""
  echo "Stage 2: DOCUMENT — would run docs-generation (dry run)"
else
  echo ""
  echo "━━━ Stage 2: DOCUMENT ━━━"
  echo "Generating docs/ from knowledge graph..."
  echo ""

  if ! command -v claude &> /dev/null; then
    echo "Error: 'claude' CLI not found."
    exit 1
  fi

  claude -p "You are running the docs-generation skill. Read .understand/knowledge-graph.json and generate a docs/ folder with human-readable markdown documentation.

Follow the docs-generation skill exactly. Generate these files:
1. docs/README.md — Project overview with tech stack, architecture summary, and table of contents
2. docs/architecture.md — Detailed architecture: layers, dependency flow, design decisions
3. docs/modules/<layer>.md — One file per architectural layer with file details and relationships
4. docs/onboarding.md — Guided tour converted to narrative prose for new developers
5. docs/AGENTS.md — Structured agent reference optimized for LLM consumption (quick facts, layer map, key files, relationship summary, file index)

Use the knowledge graph as the single source of truth. Write prose, not reformatted JSON. Cross-link all docs files. Include commit hash and timestamp for staleness tracking." --cwd "$TARGET"

  if [ ! -f "$DOCS_DIR/README.md" ]; then
    echo "Error: docs were not generated."
    exit 1
  fi
  echo ""
  echo "Docs generated: $DOCS_DIR/"
fi

# ─── Stage 3: Equip (Skill Recommender) ─────────────────────────

echo ""
echo "━━━ Stage 3: EQUIP ━━━"
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

# ─── Stage 4: Generate CLI ──────────────────────────────────────

if [ "$SKIP_CLI" = true ]; then
  echo ""
  echo "Stage 4: GENERATE — skipped"
elif [ "$DRY_RUN" = true ]; then
  echo ""
  echo "Stage 4: GENERATE — would run cli-generation (dry run)"
else
  echo ""
  echo "━━━ Stage 4: GENERATE ━━━"
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
[ -d "$DOCS_DIR" ] && echo "  docs/ ($(find "$DOCS_DIR" -name '*.md' 2>/dev/null | wc -l | tr -d ' ') markdown files)"
[ -d "$TARGET/.claude/skills" ] && echo "  .claude/skills/ ($(ls "$TARGET/.claude/skills/" 2>/dev/null | wc -l | tr -d ' ') skills)"
for d in "$TARGET"/*-cli/; do
  [ -d "$d" ] && echo "  $(basename "$d")/"
done
echo ""
echo "Next steps:"
echo "  cd $TARGET"
echo "  git checkout -b feature/repo-augmentation"
echo "  git add .understand/ docs/ .claude/skills/ *-cli/"
echo "  git commit -m 'feat: add repo augmentation'"
