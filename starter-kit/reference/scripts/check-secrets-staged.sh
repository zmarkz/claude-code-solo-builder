#!/usr/bin/env bash
# scripts/check-secrets-staged.sh
# Hook: PreToolUse on Write/Edit. Light check against the about-to-be-written
# content. NOT a replacement for the full gitleaks scan — that runs at commit
# time and in CI. This catches the obvious: AWS keys, generic API tokens,
# private keys in the diff Claude is about to write.

set -euo pipefail

# Hook payload contains the proposed Write content under `content`,
# or the Edit's new_string. Read from stdin.
INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0

CONTENT=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read() or "{}")
except Exception:
    print(""); sys.exit(0)
parts = []
for k in ("content", "new_string"):
    v = d.get(k)
    if isinstance(v, str):
        parts.append(v)
print("\n".join(parts))
' 2>/dev/null || true)

[ -z "$CONTENT" ] && exit 0

# Patterns — kept narrow to minimize false positives.
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                                       # AWS access key ID
  'ASIA[0-9A-Z]{16}'                                       # AWS temporary key ID
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'                      # private key
  'xox[abprs]-[A-Za-z0-9-]{10,}'                            # Slack token
  'ghp_[A-Za-z0-9]{36}'                                     # GitHub PAT
  'gho_[A-Za-z0-9]{36}'                                     # GitHub OAuth
  'sk-[A-Za-z0-9]{32,}'                                     # OpenAI/Anthropic-style key
  'sk-ant-[A-Za-z0-9-]{32,}'                                # Anthropic key prefix
  '"secret_key"\s*:\s*"[A-Za-z0-9_/+=-]{20,}"'              # generic secret_key json
  'AIza[0-9A-Za-z\-_]{35}'                                  # Google API key
)

found=0
for pattern in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -E -- "$pattern" >/dev/null 2>&1; then
    matched=$(echo "$CONTENT" | grep -nE -- "$pattern" | head -3)
    echo "BLOCKED: secret-like pattern detected in proposed write:" >&2
    echo "  pattern: $pattern" >&2
    echo "  matched:" >&2
    echo "$matched" | sed 's/^/    /' >&2
    found=$((found+1))
  fi
done

if [ "$found" -gt 0 ]; then
  echo "" >&2
  echo "If this is a placeholder, mask it (e.g. AKIA<EXAMPLE>) or move to .env (gitignored)." >&2
  exit 2
fi

exit 0
