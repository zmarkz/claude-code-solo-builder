#!/usr/bin/env bash
# scripts/session-snapshot.sh
# Hook: PreCompact (Claude Code is about to compact context).
# Dumps a brief state file the next session can re-read at start to recover
# context cheaply. Output: docs/session-snapshots/<timestamp>.md
#
# This helps multi-week Claude Code engagements stay grounded — the snapshot
# survives compaction events and is loaded by /start-session on the next run.

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p docs/session-snapshots
TS=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
OUT="docs/session-snapshots/${TS}.md"

{
  echo "# Session snapshot — $TS"
  echo
  echo "**Branch:** $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  echo "**HEAD:** $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  echo
  echo "## Uncommitted changes"
  echo '```'
  git status --short 2>/dev/null || echo "(no git)"
  echo '```'
  echo
  echo "## Recent commits (last 10)"
  echo '```'
  git log --oneline -10 2>/dev/null || echo "(no git history)"
  echo '```'
  echo
  echo "## Active phase (first incomplete phase in ROADMAP.md)"
  echo '```'
  grep -A 2 -E "^## Phase [0-9]+" ROADMAP.md 2>/dev/null | grep -v "✅" | head -20 || echo "(no ROADMAP.md)"
  echo '```'
  echo
  echo "## In-progress tasks (TASKS.md)"
  echo '```'
  grep -E "\[~\]" TASKS.md 2>/dev/null || echo "(none)"
  echo '```'
  echo
  echo "## Recently added ADRs (DECISIONS.md)"
  echo '```'
  grep -E "^## ADR-" DECISIONS.md 2>/dev/null | head -10 || echo "(none)"
  echo '```'
} > "$OUT"

echo "→ Session snapshot written to $OUT"
exit 0
