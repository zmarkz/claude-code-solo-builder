#!/usr/bin/env bash
# platform-scripts/fleet-status.sh
# Emit a per-workstream fleet status line for the 9 AM Telegram digest, sourced
# from each app's tasks.json + git. This is the parallel analog of a single-session
# log: it lets you trust (or intervene in) an unattended overnight /orchestrate-loops run.
#
# Usage:
#   bash fleet-status.sh [APP_DIR ...]      # explicit project dirs
#   bash fleet-status.sh                    # defaults to ~/builds/*/ with a tasks.json
#
# One line per app:
#   <app> | phase tasks: done D/T, in-prog P | needs-human: N [ids] | HEAD <sha> <subject>
# Pipe into your digest sender (e.g. send-digest.sh) or read it standalone.

set -euo pipefail

dirs=("$@")
if [ "${#dirs[@]}" -eq 0 ]; then
  shopt -s nullglob
  for f in "$HOME"/builds/*/tasks.json; do
    dirs+=("$(dirname "$f")")
  done
  shopt -u nullglob
fi

if [ "${#dirs[@]}" -eq 0 ]; then
  echo "Fleet: no apps with a tasks.json found under ~/builds/."
  exit 0
fi

echo "Fleet status — $(date '+%Y-%m-%d %H:%M')"
for dir in "${dirs[@]}"; do
  app=$(basename "$dir")
  tj="$dir/tasks.json"
  [ -f "$tj" ] || continue

  line=$(TJ="$tj" python3 <<'PY'
import json, os
try:
    d = json.load(open(os.environ["TJ"]))
except Exception:
    print("(unreadable tasks.json)"); raise SystemExit
tasks = d.get("tasks", [])
total = len(tasks)
done = sum(1 for t in tasks if t.get("status") == "done")
inprog = sum(1 for t in tasks if t.get("status") == "in_progress")
nh = [t.get("id") for t in tasks if t.get("status") == "needs-human"]
seg = "tasks: done %d/%d, in-prog %d" % (done, total, inprog)
if nh:
    seg += " | needs-human: %d [%s]" % (len(nh), ", ".join(nh[:5]))
print(seg)
PY
)

  head=$(git -C "$dir" log -1 --format='%h %s' 2>/dev/null || echo "no git")
  printf '  %-20s | %s | HEAD %s\n' "$app" "$line" "$head"
done
