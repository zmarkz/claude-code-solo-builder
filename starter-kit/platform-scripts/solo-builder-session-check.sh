#!/usr/bin/env bash
# SessionStart hook — warn (once, quietly) if the live ~/.claude setup has
# drifted from the claude-code-solo-builder repo. Never blocks the session.
#
# Point it at the repo via SOLO_BUILDER_REPO; defaults to the standard location.
REPO="${SOLO_BUILDER_REPO:-$HOME/Documents/claude/Projects/claude-code-solo-builder}"

[[ -x "$REPO/install.sh" ]] || exit 0

drift="$("$REPO/install.sh" --check 2>/dev/null || true)"
drift="$(printf '%s' "$drift" | tr -dc '0-9')"

if [[ -n "$drift" && "$drift" -gt 0 ]]; then
  echo "⚠ solo-builder: ~/.claude is $drift file(s) behind the repo."
  echo "  Sync with:  (cd \"$REPO\" && ./install.sh)"
fi
exit 0
