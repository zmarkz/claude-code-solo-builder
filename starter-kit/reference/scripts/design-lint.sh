#!/usr/bin/env bash
# design-lint.sh — PostToolUse hook: fires when any UI file is written.
# Prints a lightweight design quality reminder. Non-blocking — never fails the write.
# Wired in settings.json PostToolUse matcher: "Write|Edit"

set -euo pipefail

# PostToolUse sends the tool payload as JSON on stdin; path is under tool_input.file_path.
INPUT=$(cat 2>/dev/null || true)
CHANGED_FILE="${CLAUDE_TOOL_FILE:-}"
if [[ -z "$CHANGED_FILE" && -n "$INPUT" ]]; then
  CHANGED_FILE=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read() or "{}")
except Exception:
    sys.exit(0)
if isinstance(d, dict):
    ti = d.get("tool_input") if isinstance(d.get("tool_input"), dict) else {}
    print(ti.get("file_path") or d.get("file_path", ""))
' 2>/dev/null || true)
fi

# arg form: --changed-only <file>
if [[ "${1:-}" == "--changed-only" && -z "$CHANGED_FILE" ]]; then
  CHANGED_FILE="${2:-}"
fi

# Only fire for UI-layer files
is_ui_file() {
  local f="$1"
  [[ "$f" == *"/components/"* ]] ||
  [[ "$f" == *"/app/"* ]] ||
  [[ "$f" == *"/pages/"* ]] ||
  [[ "$f" == *"/src/"* ]] ||
  [[ "$f" == *".tsx" ]] ||
  [[ "$f" == *".jsx" ]] ||
  [[ "$f" == *".vue" ]] ||
  [[ "$f" == *".svelte" ]]
}

if [[ -z "$CHANGED_FILE" ]] || ! is_ui_file "$CHANGED_FILE"; then
  exit 0
fi

# Check if DESIGN.md exists
DESIGN_MD_EXISTS=false
if [[ -f "DESIGN.md" ]]; then
  DESIGN_MD_EXISTS=true
fi

echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Design lint — UI file modified: $(basename "$CHANGED_FILE")"
echo "├─────────────────────────────────────────────────────────────┤"

if [[ "$DESIGN_MD_EXISTS" == "false" ]]; then
  echo "│  ⚠  No DESIGN.md found. Run /design-consultation before     │"
  echo "│     shipping UI to establish the project design system.     │"
else
  echo "│  ✓  DESIGN.md present.                                      │"
fi

echo "│                                                             │"
echo "│  Before marking this done:                                  │"
echo "│  → /design-review   — screenshot + visual QA + auto-fix    │"
echo "│  → Check: loading / empty / error / success states         │"
echo "│  → Check: keyboard nav, focus rings, ARIA labels           │"
echo "│  → Check: no Inter/Roboto defaults if DESIGN.md says otherwise │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

exit 0
