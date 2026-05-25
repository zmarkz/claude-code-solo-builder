#!/usr/bin/env bash
# scripts/tasks-sync.sh
# Generate a machine-readable tasks.json from the human-edited TASKS.md.
# tasks.json is the durable, resumable substrate the orchestrator reads to build
# a file-domain DAG and that durable loops update as they run.
#
# Usage:  bash scripts/tasks-sync.sh [TASKS.md] [tasks.json]
#   defaults: ./TASKS.md  ->  ./tasks.json
#
# TASKS.md conventions parsed:
#   - Phase headers:  "## Phase 1" or "## Phase 1 — Title"
#   - Task lines:     "- [ ] text"   markers: [ ]=todo  [~]=in_progress  [x]=done  [!]=needs-human
#   - Optional inline harness tags on the task line (any order):
#       @id:slug                       explicit id (else slugified from text)
#       @domain:apps/web/**,packages/* comma-separated file-domain globs (the leaf's ownership)
#       @needs:other-id,another-id     depends_on ids
#     Acceptance criterion = text after an em-dash "—" or " - ", if present.
#
# Idempotent: re-running preserves each task's runtime "attempts" counter (matched
# by id) and takes "status" from the current TASKS.md markers.

set -euo pipefail

IN="${1:-TASKS.md}"
OUT="${2:-tasks.json}"

if [ ! -f "$IN" ]; then
  echo "tasks-sync: no $IN found — nothing to sync." >&2
  exit 1
fi

IN="$IN" OUT="$OUT" python3 <<'PY'
import json, os, re, sys

src = os.environ["IN"]
dst = os.environ["OUT"]

# Preserve runtime state (attempts) from any existing tasks.json, keyed by id.
prev = {}
if os.path.exists(dst):
    try:
        for t in json.load(open(dst)).get("tasks", []):
            prev[t.get("id")] = t
    except Exception:
        prev = {}

STATUS = {" ": "todo", "~": "in_progress", "x": "done", "X": "done", "!": "needs-human"}

def slugify(s):
    s = re.sub(r"[`*_]", "", s).strip().lower()
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s[:60] or "task"

task_re = re.compile(r"^\s*[-*]\s*\[([ ~xX!])\]\s*(.*)$")
phase_re = re.compile(r"^#{1,4}\s*Phase\s+(\S+)", re.IGNORECASE)

tasks = []
seen_ids = set()
phase = None

for raw in open(src):
    line = raw.rstrip("\n")
    pm = phase_re.match(line)
    if pm:
        phase = pm.group(1).rstrip(":—-")
        continue
    m = task_re.match(line)
    if not m:
        continue
    marker, text = m.group(1), m.group(2).strip()

    # Extract @tags, then strip them from the visible text.
    def take(tag):
        mm = re.search(r"@%s:([^\s]+)" % tag, text)
        return mm.group(1) if mm else None
    tid = take("id")
    domain = take("domain")
    needs = take("needs")
    clean = re.sub(r"@(id|domain|needs):[^\s]+", "", text).strip()

    # Acceptance = text after an em-dash / " - " separator.
    accept = ""
    sep = re.split(r"\s+—\s+|\s+-\s+", clean, maxsplit=1)
    title = sep[0].strip()
    if len(sep) > 1:
        accept = sep[1].strip()

    if not tid:
        tid = slugify(title)
    base, n = tid, 2
    while tid in seen_ids:
        tid = "%s-%d" % (base, n); n += 1
    seen_ids.add(tid)

    tasks.append({
        "id": tid,
        "phase": phase,
        "title": title,
        "status": STATUS.get(marker, "todo"),
        "domain_globs": [g for g in (domain.split(",") if domain else []) if g],
        "depends_on": [d for d in (needs.split(",") if needs else []) if d],
        "attempts": int(prev.get(tid, {}).get("attempts", 0)),
        "acceptance": accept,
    })

out = {"version": 1, "source": src, "tasks": tasks}
with open(dst, "w") as fh:
    json.dump(out, fh, indent=2)
    fh.write("\n")

counts = {}
for t in tasks:
    counts[t["status"]] = counts.get(t["status"], 0) + 1
summary = ", ".join("%s=%d" % (k, counts[k]) for k in sorted(counts))
print("tasks-sync: %s -> %s | %d tasks (%s)" % (src, dst, len(tasks), summary or "none"))

missing = [t["id"] for t in tasks if t["status"] in ("todo", "in_progress") and not t["domain_globs"]]
if missing:
    print("  note: %d active task(s) have no @domain: globs — they can't run in parallel safely:" % len(missing))
    for mid in missing[:10]:
        print("    - " + mid)
PY
