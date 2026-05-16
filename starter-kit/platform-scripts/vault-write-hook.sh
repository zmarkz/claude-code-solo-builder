#!/bin/bash
# PostToolUse hook: if Claude just wrote a file inside the Obsidian vault,
# schedule a background kg re-index (debounced — only one at a time).

VAULT_PATH="$HOME/Obsidian/Builds"
WRITTEN_FILE="${TOOL_OUTPUT_FILE:-}"   # Claude Code passes this in env
LOCK_FILE="/tmp/kg-reindex.lock"

# Check if the written file is inside the vault
if [[ -z "$WRITTEN_FILE" ]]; then
  # Try reading from stdin (some hook invocations pass file path via stdin)
  WRITTEN_FILE=$(cat 2>/dev/null || true)
fi

# Only trigger if file is in vault
if [[ "$WRITTEN_FILE" != "$VAULT_PATH"* ]]; then
  exit 0
fi

# Debounce: skip if a reindex is already queued or running
if [[ -f "$LOCK_FILE" ]]; then
  exit 0
fi

touch "$LOCK_FILE"

# Run in background, remove lock when done
(
  sleep 2   # brief debounce for rapid successive writes
  ~/builds/_platform/scripts/kg-reindex.sh >> ~/logs/kg-reindex.log 2>&1
  rm -f "$LOCK_FILE"
) &

echo "[vault-hook] Queued kg-reindex for vault write: $WRITTEN_FILE"
exit 0
