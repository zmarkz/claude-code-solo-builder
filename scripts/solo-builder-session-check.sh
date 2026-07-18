#!/usr/bin/env bash
# SessionStart hook — warn (once, quietly) if the live ~/.claude setup has
# drifted from the claude-code-solo-builder repo, and nag about stale skill
# suites. Never blocks the session.
#
# Repo location: env SOLO_BUILDER_REPO > solo-builder.config > default clone path.
DEST="${CLAUDE_HOME:-$HOME/.claude}"
[ -f "$DEST/solo-builder.config" ] && . "$DEST/solo-builder.config"
REPO="${SOLO_BUILDER_REPO:-$HOME/claude-code-solo-builder}"

# 1. Repo -> ~/.claude drift.
if [[ -x "$REPO/install.sh" ]]; then
  drift="$("$REPO/install.sh" --check 2>/dev/null || true)"
  drift="$(printf '%s' "$drift" | tr -dc '0-9')"
  if [[ -n "$drift" && "$drift" -gt 0 ]]; then
    echo "⚠ solo-builder: ~/.claude is $drift file(s) behind the repo."
    echo "  Sync with:  (cd \"$REPO\" && ./install.sh)"
  fi
fi

# 2. Skill-suite freshness (cheap local checks — no network, no model calls).
GSTACK_CHECK="$DEST/skills/gstack/bin/gstack-update-check"
if [[ -x "$GSTACK_CHECK" ]]; then
  if "$GSTACK_CHECK" 2>/dev/null | grep -q "UPGRADE_AVAILABLE"; then
    echo "⚠ gstack: upgrade available — run /gstack-upgrade"
  fi
fi

# 3. Monthly /sync-skills reminder (based on the skill's last-run stamp).
STAMP="$DEST/sync-skills/state/last-run"
if [[ -f "$STAMP" ]]; then
  now=$(date +%s); last=$(cat "$STAMP" 2>/dev/null | tr -dc '0-9')
  if [[ -n "$last" ]] && (( (now - last) > 2592000 )); then
    echo "⚠ sync-skills: last run $(( (now - last) / 86400 )) days ago — run /sync-skills"
  fi
else
  mkdir -p "$(dirname "$STAMP")" 2>/dev/null || true
fi
exit 0
