#!/usr/bin/env bash
# scripts/guard-file-domain.sh
# Hook: PreToolUse on Write/Edit (from .claude/settings.json).
# Enforces a leaf's file-domain boundary during durable parallel loops
# (`/orchestrate-loops`). A leaf may only write inside the globs assigned to it;
# any write outside those globs is blocked, preventing the "merge storm" failure
# mode when several worktree agents run against the same repo.
#
# Boundary source (first match wins):
#   1. env LEAF_DOMAIN_GLOBS   — ':'/','/whitespace-separated globs (e.g. "apps/web/**:packages/ui/**")
#   2. file at  $LEAF_DOMAIN_MANIFEST  (one glob per line; '#' comments allowed)
# If NEITHER is set, this hook is a NO-OP (exit 0) — so it never interferes with
# ordinary interactive sessions, only with orchestrated leaves that set the env.
#
# Returning exit code 2 blocks the tool call.

set -euo pipefail

INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0

# No boundary configured → not inside an orchestrated leaf → allow everything.
if [ -z "${LEAF_DOMAIN_GLOBS:-}" ] && [ -z "${LEAF_DOMAIN_MANIFEST:-}" ]; then
  exit 0
fi

FILE_PATH=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read() or "{}")
except Exception:
    print(""); sys.exit(0)
print(d.get("file_path", "") if isinstance(d, dict) else "")
' 2>/dev/null || true)

[ -z "$FILE_PATH" ] && exit 0

DECISION=$(
  FILE_PATH="$FILE_PATH" python3 <<'PY'
import os, re, fnmatch, sys

file_path = os.environ.get("FILE_PATH", "")
root = os.getcwd()

# Relativise to the project root so globs are written repo-relative.
rel = file_path
if os.path.isabs(file_path):
    try:
        rel = os.path.relpath(file_path, root)
    except ValueError:
        rel = file_path
rel = rel.lstrip("./")

# Collect globs from env, else from manifest file.
globs = []
env = os.environ.get("LEAF_DOMAIN_GLOBS", "")
if env.strip():
    for part in re.split(r"[:,\s]+", env.strip()):
        if part:
            globs.append(part)
else:
    manifest = os.environ.get("LEAF_DOMAIN_MANIFEST", "")
    if manifest and os.path.exists(manifest):
        with open(manifest) as fh:
            for line in fh:
                line = line.split("#", 1)[0].strip()
                if line:
                    globs.append(line)

if not globs:
    print("ALLOW")
    sys.exit(0)

def to_regex(glob):
    # Translate a path glob (with **) to a full-match regex.
    i, n, out = 0, len(glob), []
    while i < n:
        c = glob[i]
        if glob[i:i+3] == "**/":
            out.append("(?:.*/)?"); i += 3
        elif glob[i:i+2] == "**":
            out.append(".*"); i += 2
        elif c == "*":
            out.append("[^/]*"); i += 1
        elif c == "?":
            out.append("[^/]"); i += 1
        else:
            out.append(re.escape(c)); i += 1
    return re.compile("^" + "".join(out) + "$")

for g in globs:
    g_norm = g.lstrip("./")
    if to_regex(g_norm).match(rel) or fnmatch.fnmatch(rel, g_norm):
        print("ALLOW"); sys.exit(0)

print("BLOCK\t" + rel + "\t" + " | ".join(globs))
PY
)

if printf '%s' "$DECISION" | grep -q '^BLOCK'; then
  REL=$(printf '%s' "$DECISION" | awk -F'\t' '{print $2}')
  GLOBS=$(printf '%s' "$DECISION" | awk -F'\t' '{print $3}')
  echo "BLOCKED by guard-file-domain.sh: write outside this leaf's assigned domain." >&2
  echo "  file:           $REL" >&2
  echo "  allowed globs:  $GLOBS" >&2
  echo "" >&2
  echo "This leaf owns only the globs above. To touch another domain, hand the task" >&2
  echo "to the owning leaf via the orchestrator, or split the task in tasks.json." >&2
  exit 2
fi

exit 0
