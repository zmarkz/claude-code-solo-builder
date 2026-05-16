# Vault Automation — Auto-Indexing and Session Hooks

> Three scripts that keep the knowledge-graph index fresh without any manual intervention.

---

## The Problem

The knowledge-graph (`obra/knowledge-graph-mcp`) builds a queryable SQLite index of your Obsidian vault. Without automation:
- The index goes stale as soon as you add new notes
- You have to manually remember to run `/kg-index` after vault changes
- Session starts have no signal about whether the current project's vault note is fresh

These three scripts fix all of that.

---

## Scripts

Copy all three to `~/builds/_platform/scripts/` and make them executable:

```bash
chmod +x ~/builds/_platform/scripts/kg-reindex.sh
chmod +x ~/builds/_platform/scripts/vault-session-check.sh
chmod +x ~/builds/_platform/scripts/vault-write-hook.sh
```

### 1. `kg-reindex.sh` — Rebuild the knowledge-graph index

```bash
#!/bin/bash
KG_DIR="$HOME/builds/_knowledge-graph"
VAULT_PATH="$HOME/Obsidian/Builds"
LOG_DIR="$HOME/logs"
mkdir -p "$LOG_DIR"
echo "[kg-reindex] $(date '+%Y-%m-%d %H:%M:%S') — starting"
cd "$KG_DIR"
KG_VAULT_PATH="$VAULT_PATH" \
  npx --prefix "$KG_DIR" tsx "$KG_DIR/src/cli/index.ts" index \
  2>&1 | tee -a "$LOG_DIR/kg-reindex.log" | tail -3
echo "[kg-reindex] $(date '+%Y-%m-%d %H:%M:%S') — done"
```

### 2. `vault-session-check.sh` — SessionStart hook

Runs at the start of every Claude Code session. Prints a warning if the current project's vault note is stale (>7 days old) or missing.

```bash
#!/bin/bash
VAULT_PATH="$HOME/Obsidian/Builds/01-Projects"
PROJECT_NAME=$(basename "$(pwd)")
VAULT_NOTE="$VAULT_PATH/$PROJECT_NAME/INDEX.md"
if [[ -f "$VAULT_NOTE" ]]; then
  LAST_MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d" "$VAULT_NOTE" 2>/dev/null || \
                  stat -c "%y" "$VAULT_NOTE" 2>/dev/null | cut -d' ' -f1)
  TODAY=$(date '+%Y-%m-%d')
  DAYS_OLD=$(( ($(date -d "$TODAY" +%s 2>/dev/null || date -j -f '%Y-%m-%d' "$TODAY" +%s) \
              - $(date -d "$LAST_MODIFIED" +%s 2>/dev/null || date -j -f '%Y-%m-%d' "$LAST_MODIFIED" +%s)) / 86400 ))
  if [[ "$DAYS_OLD" -gt 7 ]]; then
    echo "⚠️  Vault: $PROJECT_NAME/INDEX.md last updated $DAYS_OLD days ago — consider /vault-update"
  else
    echo "✓  Vault: $PROJECT_NAME/INDEX.md is fresh ($LAST_MODIFIED)"
  fi
else
  echo "⚠️  Vault: No INDEX.md for '$PROJECT_NAME' — Run /vault-update to create it"
fi
```

### 3. `vault-write-hook.sh` — PostToolUse hook

Fires after Claude writes any file inside `~/Obsidian/Builds/`. Queues a deferred kg-reindex (2-second delay, with lock file to prevent overlapping runs).

```bash
#!/bin/bash
VAULT_PATH="$HOME/Obsidian/Builds"
WRITTEN_FILE="${TOOL_OUTPUT_FILE:-}"
LOCK_FILE="/tmp/kg-reindex.lock"
if [[ -z "$WRITTEN_FILE" ]]; then
  WRITTEN_FILE=$(cat 2>/dev/null || true)
fi
if [[ "$WRITTEN_FILE" != "$VAULT_PATH"* ]]; then exit 0; fi
if [[ -f "$LOCK_FILE" ]]; then exit 0; fi
touch "$LOCK_FILE"
(sleep 2; ~/builds/_platform/scripts/kg-reindex.sh >> ~/logs/kg-reindex.log 2>&1; rm -f "$LOCK_FILE") &
echo "[vault-hook] Queued kg-reindex for vault write: $WRITTEN_FILE"
exit 0
```

---

## Wire into Claude Code settings.json

Add the hooks section to `~/.claude/settings.json`:

```json
"hooks": {
  "SessionStart": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "bash /YOUR_HOME/builds/_platform/scripts/vault-session-check.sh"
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "command",
          "command": "bash /YOUR_HOME/builds/_platform/scripts/vault-write-hook.sh"
        }
      ]
    }
  ]
}
```

Replace `/YOUR_HOME` with your actual home path (e.g., `/Users/yourname`).

**Critical:** Each hook entry MUST have `"type": "command"` — the settings schema requires it.

---

## Shell wrapper — re-index on session close

The `PostToolUse` hook only fires when Claude writes vault files. For regular coding sessions, the nightly cron is the safety net — but if you want the index updated the moment you close Claude Code, add this to `~/.zshrc`:

```bash
# claude wrapper: re-index knowledge-graph after every session ends
function cc() {
  caffeinate -s claude --dangerously-skip-permissions "$@"
  bash /YOUR_HOME/builds/_platform/scripts/kg-reindex.sh
}
```

Replace `/YOUR_HOME` with your actual home path. Adjust the `claude` invocation flags to match how you normally launch Claude Code. Then use `cc` instead of your usual launch command. When you exit (`Cmd+C` or `:q`), the re-index runs automatically.

---

## Nightly cron

Add a 2 AM re-index to ensure the index is always fresh, even if no vault writes happened:

```bash
# Add to crontab:
crontab -e

# Entry:
0 2 * * * /YOUR_HOME/builds/_platform/scripts/kg-reindex.sh >> /YOUR_HOME/logs/kg-reindex.log 2>&1
```

---

## The `/vault-update` command

Run `/vault-update` at the end of any session to:
1. Write or update the current project's `INDEX.md` in the vault
2. Trigger a kg-reindex
3. Commit the vault to git

This closes the loop: the vault stays current, the index stays current, and future sessions have a warm start.

---

## Verification

After setup, verify all three layers work:

```bash
# 1. Hooks installed
grep -A5 '"hooks"' ~/.claude/settings.json

# 2. Scripts executable
ls -la ~/builds/_platform/scripts/*.sh

# 3. Cron registered
crontab -l | grep kg-reindex

# 4. MCP connected (vault-files should show ✓)
claude mcp list

# 5. Run a manual test re-index
bash ~/builds/_platform/scripts/kg-reindex.sh
```

---

*See also: `docs/OBSIDIAN-CONTEXT7.md` for vault setup, `docs/INSTALL.md` for initial MCP configuration.*
