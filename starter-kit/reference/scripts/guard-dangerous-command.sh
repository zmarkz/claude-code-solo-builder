#!/usr/bin/env bash
# scripts/guard-dangerous-command.sh
# Hook: PreToolUse on Bash (from .claude/settings.json).
# Blocks commands that could damage the repo, the host, or violate policy.
# Reads the proposed command from stdin (JSON via the hook payload) or arg.
#
# Returning a non-zero exit code blocks the tool call.

set -euo pipefail

# Claude Code sends the tool input as JSON on stdin.
# For a Bash tool the field is `command`.
INPUT="${1:-$(cat 2>/dev/null || true)}"
CMD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys; d=json.loads(sys.stdin.read() or "{}"); print(d.get("command", "") if isinstance(d, dict) else "")' 2>/dev/null || echo "$INPUT")

CMD_NORMALIZED=$(printf '%s' "$CMD" | tr -s ' \t\n' ' ')

block() {
  local reason="$1"
  echo "BLOCKED by guard-dangerous-command.sh: $reason" >&2
  echo "Command was: $CMD" >&2
  exit 2
}

# Catastrophic FS operations
if echo "$CMD_NORMALIZED" | grep -Eq '(^|;|&|\|)\s*rm\s+-rf?\s+(/|/\*|~|\$HOME)(/|\s|$)'; then
  block "Destructive rm on root / home"
fi

# Force-push to any branch
if echo "$CMD_NORMALIZED" | grep -Eq 'git\s+push\s+.*--force(\s|$)'; then
  block "git push --force is denied. Use a rebase + PR, or ask the human to force-push manually."
fi

# Reset / branch destruction
if echo "$CMD_NORMALIZED" | grep -Eq 'git\s+reset\s+--hard\s+HEAD~'; then
  block "Hard reset moves commits out of reach. If intentional, run manually."
fi

# Reading sensitive paths
if echo "$CMD_NORMALIZED" | grep -Eq '(cat|less|tail|head|bat|hexdump|xxd)\s+.*(\.ssh/|\.aws/|\.kube/|\.config/gcloud/|\.env(\s|$)|\.env\.[A-Za-z0-9_-]+)'; then
  block "Reading from a sensitive path"
fi

# Outbound SCP / rsync to remote hosts
if echo "$CMD_NORMALIZED" | grep -Eq '^(scp|rsync)\s+.+(@[^:]+:|::)'; then
  block "Outbound copy to a remote host. Confirm with the human first."
fi

# sudo
if echo "$CMD_NORMALIZED" | grep -Eq '(^|;|&|\|)\s*sudo(\s|$)'; then
  block "sudo is not allowed in Claude Code sessions. Ask the human to run manually."
fi

# Curl/wget piping to shell — supply-chain risk
if echo "$CMD_NORMALIZED" | grep -Eq '(curl|wget)\s.+\|\s*(sh|bash|zsh)(\s|$)'; then
  block "curl/wget piped to shell is denied (supply-chain risk)."
fi

# Docker volume / image deletion
if echo "$CMD_NORMALIZED" | grep -Eq 'docker\s+(system\s+prune\s+(-a|--all)|volume\s+rm)'; then
  block "Docker destructive prune/rm. Use 'make clean' which prompts for confirmation."
fi

exit 0
