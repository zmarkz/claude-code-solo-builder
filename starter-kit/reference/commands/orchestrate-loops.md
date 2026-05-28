---
description: Mode 3 — Durable Parallel Loops. Spawns one background, worktree-isolated, attempt-capped agent per independent file-domain in tasks.json, integrates via a reviewer, and stops at the human phase gate. Built entirely on native Claude Code primitives (background Agents, Monitor, ScheduleWakeup) — no external orchestrator. For large or overnight builds where you will NOT babysit. For interactive parallelism use /start-phase-team; for sequential use /build-phase-autopilot.
argument-hint: <phase number, default 1>
---

# Orchestrate durable parallel loops — Phase $ARGUMENTS

This is the **durable, headless** sibling of `/start-phase-team`. Where a team runs interactive
in-process teammates, this spawns **background worktree agents** that survive long runs via
attempt caps, timeouts, and stuck-detection, while the orchestrator's own context window stays
lean (it holds `tasks.json` + one-paragraph leaf summaries — never worker transcripts).

> Doctrine reminder (`docs/SWARM-ORCHESTRATION.md`): we do **not** build or install a custom
> orchestrator. This command is glue over native primitives — the `Workflow()` tool
> (`pipeline()`/`parallel()`, auto-resume, shared budget) as the preferred substrate, falling back
> to `Agent(isolation:"worktree", run_in_background:true)` + `Monitor` + `ScheduleWakeup` for
> dynamic decomposition. Nothing here self-approves a phase; the human gate is non-negotiable.

## Preflight (fix and re-run if any fails)

1. **`tasks.json` exists and is current.** If `TASKS.md` is newer, run `bash scripts/tasks-sync.sh`
   first. Refuse if `tasks.json` is missing.
2. **Clean working tree:** `git status --porcelain` is empty.
3. **Feature branch:** NOT on `main`/`master`. If on main, instruct: `git checkout -b feature/phase-$ARGUMENTS-loops`.
4. **`make quality` is green at the start.** Durable loops do not start on red.
5. **Phase scope:** default Phase 1 only. For Phase ≥2, refuse unless a recent ADR (last 30 days)
   in `docs/adr/` explicitly extends loop coverage — same rule as `/build-phase-autopilot`.
6. **The domain hook is wired:** confirm `scripts/guard-file-domain.sh` exists and is referenced in
   `.claude/settings.json` PreToolUse(Write|Edit). Refuse to run parallel leaves without it — it is
   the only thing preventing a merge storm.

## Partition into a file-domain DAG

1. Read `tasks.json`. Select tasks where `status` is `todo`/`in_progress`, `phase` matches
   `$ARGUMENTS`, and every id in `depends_on` is already `done`.
2. Group selected tasks by **non-overlapping `domain_globs`**. Two tasks may run in parallel only
   if their globs do not intersect. A task with empty `domain_globs` is **not eligible** for
   parallel runs — either give it globs in `TASKS.md` + re-sync, or run it via `/build-feature`.
3. Concurrency is bounded by the harness at **`min(16, cores−2)`** (≈12 on an M4 Pro — see
   `docs/SWARM-ORCHESTRATION.md` › *Concurrency tuning*). With the `Workflow()` substrate you do
   **not** set this — the tool enforces the cap and queues the overflow. With the manual loop, size
   the batch to that cap. Remaining eligible domains queue behind the first batch.

## Choose the substrate

- **Static task list (default) → use `Workflow()`.** Author a script that reads `tasks.json`,
  groups by non-overlapping `domain_globs`, and runs leaves with `pipeline()` (per-leaf:
  implement → `make quality` → commit) under `parallel()` for independent domains. Give each leaf
  `isolation:'worktree'`, a result `schema:` (so a leaf's summary is validated, not parsed from
  prose), and pass `LEAF_DOMAIN_GLOBS` in its prompt so `guard-file-domain.sh` still enforces the
  boundary. Encode the attempt-cap (retry loop), timeout, and 4h ceiling in the script. Resume a
  killed run with `resumeFromRunId` — unchanged leaves replay from cache. `Workflow()` needs
  explicit opt-in, so tell the user it's running as a workflow.
- **Decomposition must adapt mid-run → use the manual background-agent loop** described next.

## Spawn one durable leaf per domain (manual fallback substrate)

For each independent domain, launch a **background, worktree-isolated** agent:

- Tool: `Agent` with `isolation: "worktree"`, `run_in_background: true`, a stable `name` (e.g.
  `leaf-<domain-slug>`), and a role-appropriate model per the loop-role routing in
  `docs/AI-ROUTING.md` (feature work → Sonnet; pure grind/boilerplate → Haiku/local).
- In the leaf's prompt, set its boundary so the hook enforces it:
  `export LEAF_DOMAIN_GLOBS="<comma/colon-joined globs for this domain>"`.
- Leaf contract (state in the prompt):
  1. Read only its assigned task(s) from `tasks.json` and the files under its globs.
  2. For each task: implement → run `make quality` for the affected scope → on green, commit
     (Conventional Commits, one commit per task) → set the task `status: done` and `attempts`.
  3. **Durability:** retry a failed `make quality` up to **3** attempts; increment `attempts` each
     try. On the 4th failure, set `status: needs-human`, stop touching that task, and move on.
  4. **TDD + vertical slice** per the worker agent definitions; no commit without tests.
  5. Return a **one-paragraph summary** only (commits, tasks done, any `needs-human`). Do not echo
     transcripts back to the orchestrator.

## Orchestrator duties (keep your own window lean)

- Track progress by reading `tasks.json` status + each leaf's returned summary. **Never read a
  leaf's transcript** — that re-creates the single-giant-window problem.
- Use `Monitor` / `ScheduleWakeup` to wait on background completion rather than polling in-context.
- **Runtime ceiling:** if total wall-clock exceeds the configured cap (default 4h), stop launching
  new leaves, let in-flight ones finish, and report. Page via the Telegram digest on cap or on any
  `needs-human` flip.
- When a batch completes, launch the next eligible batch (dependencies now satisfied), up to the
  concurrency cap.

## Integration & termination

When no eligible `todo` tasks remain for Phase $ARGUMENTS:

1. Hand the merge queue to the **reviewer**: run gstack `/review` on each leaf branch, then
   `/land-and-deploy` to merge in dependency order. Per-leaf gates caught unit breakage; the
   reviewer catches **cross-leaf contract drift** (run consumer-side integration tests here).
2. Print the hand-off block and **STOP** — do not run `/phase-review`:

```
Durable loop run complete — Phase $ARGUMENTS.

Leaves: <n>  | Tasks done: <list of ids>  | needs-human: <list or none>
Commits: <list by leaf>  | Runtime: <wall-clock>  | Est. cost: <₹/$>
Open contract risks (reviewer): <list or none>

NEXT — HUMAN ACTIONS REQUIRED:
1. Review the merged diff: git log --since=<run-start> --stat
2. Resolve any needs-human tasks in TASKS.md, then re-sync: bash scripts/tasks-sync.sh
3. Run /phase-review $ARGUMENTS in a fresh session and sign docs/phase-reviews/phase-$ARGUMENTS.md by hand.
```

## Failure handling

- A leaf that wedges (no output past the stuck threshold) is terminated; its task keeps its
  `attempts` count and is left for the next run or flipped to `needs-human`.
- If `guard-file-domain.sh` blocks a leaf, that is **correct behavior** — the task's globs are too
  narrow or the decomposition was wrong. Fix `domain_globs` in `TASKS.md`, re-sync, re-run.
- Never "fix forward" by widening a leaf's domain mid-run to unblock it.

## Why this is bounded

Background autonomy raises the stakes of the existing gates, so they all stay: per-task `make
quality`, the file-domain hook, the reviewer's contract tests, and the human phase review. The
loop generates work; it never approves it.
