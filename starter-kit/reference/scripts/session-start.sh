#!/usr/bin/env bash
# scripts/session-start.sh
# Hook: SessionStart (from .claude/settings.json).
# Prints the current phase, key env-flag state, and git status.
# Non-blocking — informational only.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "──────────────────────────────────────────────────────────────────"
echo "  Project session start"
echo "──────────────────────────────────────────────────────────────────"

# Current phase from ROADMAP.md (first non-completed phase)
if [ -f ROADMAP.md ]; then
  phase=$(grep -E "^## Phase [0-9]+" ROADMAP.md | grep -v "✅" | head -1 || true)
  if [ -n "$phase" ]; then
    echo "  Active phase  : ${phase#\#\# }"
  else
    echo "  Active phase  : all phases marked complete in ROADMAP.md"
  fi
fi

# Project-specific env flags (customize per project)
if [ -n "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" ]; then
  echo "  AgentTeams    : enabled"
fi
# Add project-specific flag echoes here, e.g.:
# echo "  STRICT_MODE   : ${STRICT_MODE:-true (default)}"

# Git status — uncommitted changes
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  uncommitted=$(git status --porcelain | wc -l | tr -d ' ')
  if [ "$uncommitted" != "0" ]; then
    echo "  Git           : $uncommitted uncommitted change(s)"
  else
    echo "  Git           : clean"
  fi
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(detached)")
  echo "  Branch        : $branch"
fi

# Phase review pending?
if [ -d docs/phase-reviews ]; then
  pending=$(ls docs/phase-reviews/*.md 2>/dev/null | xargs -I{} grep -l "Signed by <name>" {} 2>/dev/null | wc -l | tr -d ' ' || echo 0)
  if [ "$pending" != "0" ]; then
    echo "  ⚠  Phase reviews awaiting human signature: $pending"
  fi
fi

# Reminder
echo ""
echo "  → /start-session  to re-load context"
echo "  → /plan-feature   before implementing anything new"
echo "──────────────────────────────────────────────────────────────────"
