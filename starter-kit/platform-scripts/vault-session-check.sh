#!/bin/bash
# SessionStart hook: reports vault freshness for the current project.
# Checks if the current project has a vault INDEX.md and when it was last updated.

VAULT_PATH="$HOME/Obsidian/Builds/01-Projects"
CWD=$(pwd)

# Try to detect current project name from directory
PROJECT_NAME=$(basename "$CWD")

# Check for vault note
VAULT_NOTE="$VAULT_PATH/$PROJECT_NAME/INDEX.md"

if [[ -f "$VAULT_NOTE" ]]; then
  LAST_MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d" "$VAULT_NOTE" 2>/dev/null || date -r "$VAULT_NOTE" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
  TODAY=$(date "+%Y-%m-%d")
  DAYS_OLD=$(( ( $(date -j -f "%Y-%m-%d" "$TODAY" "+%s" 2>/dev/null || date -d "$TODAY" "+%s") - $(date -j -f "%Y-%m-%d" "$LAST_MODIFIED" "+%s" 2>/dev/null || date -d "$LAST_MODIFIED" "+%s") ) / 86400 ))
  
  if [[ "$DAYS_OLD" -gt 7 ]]; then
    echo "⚠️  Vault: $PROJECT_NAME/INDEX.md last updated $DAYS_OLD days ago ($LAST_MODIFIED) — consider updating"
  else
    echo "✓  Vault: $PROJECT_NAME/INDEX.md is fresh ($LAST_MODIFIED)"
  fi
else
  echo "⚠️  Vault: No INDEX.md found for '$PROJECT_NAME' at $VAULT_NOTE"
  echo "   → Run /vault-update to create it"
fi
