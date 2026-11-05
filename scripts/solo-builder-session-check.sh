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
# A missing stamp counts as overdue: the old check stayed silent in that case, so a
# machine that never wrote the stamp went unsynced for months with no warning.
STAMP="$DEST/sync-skills/state/last-run"
LAST_SYNC="$DEST/sync-skills/state/last-sync.json"
now=$(date +%s); last=""
[[ -f "$STAMP" ]] && last=$(tr -dc '0-9' < "$STAMP" 2>/dev/null)
if [[ -z "$last" && -f "$LAST_SYNC" ]]; then
  last=$(stat -f %m "$LAST_SYNC" 2>/dev/null || stat -c %Y "$LAST_SYNC" 2>/dev/null)
fi
if [[ -z "$last" ]]; then
  echo "⚠ sync-skills: no record of a run — run /sync-skills"
elif (( (now - last) > 2592000 )); then
  echo "⚠ sync-skills: last run $(( (now - last) / 86400 )) days ago — run /sync-skills"
fi

# 4. A project pin to a full model ID overrides /model on every restart and goes stale
#    silently. Aliases (opus, sonnet, haiku) always resolve to the latest of the tier.
pin=$(grep -E '^[[:space:]]*"model"[[:space:]]*:[[:space:]]*"claude-' .claude/settings.json 2>/dev/null | head -1 | sed -E 's/.*"(claude-[^"]+)".*/\1/')
if [[ -n "$pin" ]]; then
  echo "⚠ model: .claude/settings.json pins $pin — use an alias such as \"opus\" so it cannot go stale"
fi
exit 0
