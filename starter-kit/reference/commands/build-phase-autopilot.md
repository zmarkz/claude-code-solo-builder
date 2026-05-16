---
description: Phase autopilot. Chains plan → auto-approve spec → build → commit for whitelisted Phase 1 task slugs (or other early phases by ADR). Skips spec-approval and per-commit human review gates. Refuses to run outside the allowlist. STOPS at the phase-review gate; that one is non-negotiable.
argument-hint: <comma-separated slugs from the allowlist, or "all">
---

# Phase autopilot

This is a **bounded autopilot**. Read its limits before running.

## Default scope: Phase 1 only

By default, this command only operates on slugs **defined in TASKS.md under Phase 1**. To use the same pattern for Phase 2+, the project must have an ADR in `DECISIONS.md` from the last 30 days explicitly extending the allowlist with the affected slugs. Phase 4-6 work (in a typical phased project) usually touches auth, citations, authorization, external APIs — coordination friction outweighs the autopilot's benefit.

If `$ARGUMENTS` is `all`, run every Phase 1 slug listed in `TASKS.md` in the order they appear. Sequential — so a failure stops the chain at a known good state. Do not parallelize within a single autopilot run (use `/start-phase-team` for parallelism instead).

## Hard preconditions (verify before doing anything)

Stop with a clear error if any of the following is false:

1. The slug list is non-empty and every slug is in the Phase 1 task list in `TASKS.md`.
2. Working tree is clean (`git status --porcelain` is empty).
3. Current branch is NOT `main` / `master`. Require a feature or autopilot branch. If on main, instruct the user: `git checkout -b feature/phase-1-autopilot`. Do not create the branch yourself.
4. `make quality` passes at the starting state. Autopilot does not start on red.
5. The phase referenced is Phase 1 (or has an ADR extension as noted above).

## Per-slug procedure

For each slug in the run order:

### Step 1 — Plan

Invoke the `/plan-feature <slug>` workflow as documented:

1. Read context (`PROJECT_CONTEXT.md`, ROADMAP.md current phase, relevant TASKS.md entry, recent ADRs).
2. Launch `product-manager` for vertical-slice scoping.
3. Launch `solution-architect` for design review.
4. Launch `security-architect` if the slug touches auth/tenancy/storage/model.
5. Consolidate into `docs/specs/<slug>.md` with `status: drafted`.

### Step 2 — Auto-approve the spec (explicit exception)

Set the spec's frontmatter to `status: approved-by-autopilot`. Add a top-of-doc note:

```
> **Approved by Phase autopilot on <ISO timestamp>.** This spec did not pass through the
> usual human approval gate because the autopilot was explicitly invoked for this slug.
> The human gate at end-of-phase (`/phase-review <N>`) compensates.
```

Append a line to `docs/autopilot-runs/<run-id>.md`: slug, spec hash, timestamp.

### Step 3 — Build

Invoke the `/build-feature <slug>` workflow:

1. Vertical slice in order: schema → model → schema → service (test-first) → router → worker (if applicable) → UI (if applicable) → docs.
2. Run `make quality` between layers. If anything goes red, **stop the entire autopilot run** at this slug.
3. If the build engages an LLM call (none should in Phase 1 of a typical project), refuse — that's later-phase work creeping in.

### Step 4 — Commit (explicit exception)

If `make quality` is green at the end of the build:

1. Stage all changes (`git add .`).
2. Run `bash scripts/secret-scan.sh --staged` — must pass.
3. Generate a Conventional Commits message: `feat(<scope>): phase 1 — <slug>`.
4. Commit. Do not push, do not tag, do not open a PR.

### Step 5 — Update task tracking

1. Mark the slug as completed in `TASKS.md` (`[x]`).
2. Append to `docs/autopilot-runs/<run-id>.md`: slug, end timestamp, commit SHA, files-changed count, tests-added count.

### Step 6 — Move to next slug

Repeat the per-slug procedure. Do not parallelize.

## The hard stop

After the final slug in the run completes, **STOP**. Do not invoke `/phase-review`. Print:

```
Phase autopilot complete.

Slugs built: <list with commit SHAs>
Total quality runs: <N>, all green.
Run log: docs/autopilot-runs/<run-id>.md

NEXT STEPS — HUMAN ACTIONS REQUIRED:
1. Review the run log and the commits (git log).
2. Optionally: spot-review one or two specs in docs/specs/ and the corresponding diffs.
3. If satisfied, run `/phase-review <N>` yourself in a fresh session.
   Sign docs/phase-reviews/phase-<N>.md by hand.

Autopilot will NOT run /phase-review. Phase gates are non-negotiable.
```

## Failure handling

If any step fails (`make quality` red, secret-scan blocked, schema migration fails to apply-then-revert), stop the chain immediately. Do not attempt to "fix forward" by editing and re-running. Print:

- The slug that failed.
- The step that failed.
- The error output.
- The state of the working tree (`git status` summary).
- Recommended next action: hand to the human, or invoke the relevant single-feature commands manually.

Mark the slug as `[!]` (blocked) in `TASKS.md` with a note.

## Why these exceptions are bounded

Skipping two human gates (spec approval, per-commit review) is bought back by:

1. **The Phase 1 default** — phase-1 slugs typically don't touch auth, citations, authorization, or external APIs.
2. **`make quality` between every layer** — same checks the per-commit hook runs.
3. **The per-slug commit** — discrete review surfaces in `git log`, not one massive diff.
4. **The hard stop at phase review** — the human gate remains.
5. **The run log at `docs/autopilot-runs/<run-id>.md`** — audit trail of every autopilot-approved spec and commit.

If at any point during a run you want to drop back to manual, `Ctrl-C` the Claude Code session — the next slug won't start, and the work already committed is preserved.

## Refuse-to-run list

This command refuses for any of:

- A slug not in the current phase's allowlist.
- A dirty working tree.
- Running on `main` / `master`.
- A red `make quality` at the start.
- An ADR in `DECISIONS.md` from the last 7 days marking autopilot as suspended.

Relaxing the refuse-to-run list is an ADR-level decision, not an in-line edit.
