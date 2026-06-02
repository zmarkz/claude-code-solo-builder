#!/usr/bin/env bash
# install.sh — propagate this repo into your live Claude Code setup (~/.claude).
#
# This repo is the SOURCE OF TRUTH. Your live setup at ~/.claude is a copy.
# Run this after every `git pull` so the copy never drifts from the source.
#
#   ./install.sh           Sync repo -> ~/.claude (idempotent, safe to re-run)
#   ./install.sh --check    Read-only drift report. Prints the number of files
#                           that WOULD change to stdout; per-area detail to stderr.
#                           Exit 0 = in sync, exit 1 = drift. Used by the
#                           SessionStart drift hook.
#
# What it does NOT touch: your live ~/.claude/settings.json and ~/.claude/CLAUDE.md
# (those are yours to edit). It prints guidance if they lack the recommended wiring.
#
# Override targets via env: CLAUDE_HOME=... PLATFORM_SCRIPTS=...
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
PLATFORM="${PLATFORM_SCRIPTS:-$HOME/builds/_platform/scripts}"

MODE="install"
[[ "${1:-}" == "--check" ]] && MODE="check"

command -v rsync >/dev/null 2>&1 || { echo "rsync required but not found" >&2; exit 2; }

TOTAL_DRIFT=0

# sync <label> <src-dir> <dst-dir> <delete:0|1> [extra rsync args...]
#  - delete=1: dst is fully owned by us (skill dirs) -> prune stale files
#  - delete=0: dst is shared (agents/commands live alongside seo-* etc.) -> additive only
sync() {
  local label="$1" src="$2" dst="$3" del="$4"; shift 4
  # -c: compare by checksum, not mtime — a fresh git clone has different mtimes
  # but identical content, which must NOT register as drift.
  local opts=(-rc "$@")
  [[ "$del" == "1" ]] && opts+=(--delete)
  if [[ ! -d "$src" ]]; then return 0; fi
  if [[ "$MODE" == "check" ]]; then
    # Count only real changes: new/changed files (>,<), created dirs (c), deletions (*).
    # Attribute-only lines (mtime/perms) start with '.' and are excluded.
    local n
    n="$(rsync -in "${opts[@]}" "$src"/ "$dst"/ 2>/dev/null | grep -cE '^(>|<|c|\*)' || true)"
    TOTAL_DRIFT=$(( TOTAL_DRIFT + n ))
    printf '  %-22s %s change(s)\n' "$label:" "$n" >&2
  else
    mkdir -p "$dst"
    rsync -i "${opts[@]}" "$src"/ "$dst"/ 2>/dev/null | grep -E '^(>|<|c|\*)' | sed "s/^/  [$label] /" || true
  fi
}

[[ "$MODE" == "install" ]] && echo "Syncing $REPO -> $DEST ..."

# 1. The scaffold skill (we own this dir fully; exclude platform-scripts — those go to $PLATFORM).
sync "scaffold-skill" "$REPO/starter-kit" "$DEST/skills/ai-project-scaffold" 1 --exclude 'platform-scripts/'

# 2. sync-skills command (we own it; prune cruft like old .bak files).
sync "sync-skills" "$REPO/skills/sync-skills" "$DEST/skills/sync-skills" 1

# 3. Builder agents + commands + workflow recipes (shared dirs — additive, never delete
#    seo-*/third-party files; exclude the human-only workflows README from the synced runtime dir).
sync "agents" "$REPO/starter-kit/reference/agents" "$DEST/agents" 0
sync "commands" "$REPO/starter-kit/reference/commands" "$DEST/commands" 0
sync "workflows" "$REPO/starter-kit/reference/workflows" "$DEST/workflows" 0 --exclude 'README.md'

# 4. Platform automation scripts (shared dir — additive).
sync "platform-scripts" "$REPO/starter-kit/platform-scripts" "$PLATFORM" 0

if [[ "$MODE" == "check" ]]; then
  echo "$TOTAL_DRIFT"
  [[ "$TOTAL_DRIFT" -gt 0 ]] && exit 1 || exit 0
fi

# install mode: advise on the two files we deliberately don't overwrite.
echo ""
if ! grep -q "solo-builder-session-check.sh" "$DEST/settings.json" 2>/dev/null; then
  echo "NOTE: your $DEST/settings.json has no solo-builder drift hook."
  echo "      Add the SessionStart hook from settings/settings.json.template to get"
  echo "      a sync reminder at the start of every session."
fi
if ! grep -q "Behavioral Principles" "$DEST/CLAUDE.md" 2>/dev/null; then
  echo "NOTE: your $DEST/CLAUDE.md has no 'Behavioral Principles' section."
  echo "      Consider merging it from settings/CLAUDE.md.template."
fi
echo ""
echo "Done. Next: run /sync-project inside each app to push updated agents/commands into it."
