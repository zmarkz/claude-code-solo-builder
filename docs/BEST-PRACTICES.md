# Best Practices — Running the Solo Builder Setup

> How to operate this setup day to day. The companion to `README.md` (what it is) and
> `PLAYBOOK.md` (the full operating manual). This page is the short list you actually follow.

---

## 1. Propagation discipline — the repo is the only source of truth

This repo is canonical. `~/.claude` is a **copy**. Each app's `.claude/` is a copy of the copy.

```
repo  ──./install.sh──►  ~/.claude  ──/sync-project──►  each app's .claude/
```

- **Never hand-edit `~/.claude/agents` or `~/.claude/commands`.** Edit the repo, then `make install`.
  The only files you own directly are `~/.claude/settings.json` and `~/.claude/CLAUDE.md`.
- **After every `git pull`:** `make install` (idempotent — safe to re-run).
- **Before you trust your setup:** `make check` (read-only; content-based, ignores mtime).
- The **SessionStart drift hook** nudges you automatically — silent means in sync. Don't ignore it.
- After updating the repo, run **`/sync-project`** inside each app that should pick up the change.

`make install` is additive for shared dirs (it never deletes your `seo-*` or third-party agents) and
prunes only the dirs this repo fully owns (the scaffold skill, `sync-skills`).

---

## 2. Model & speed (Opus 4.8 era)

- **Opus 4.8 + `/fast` is the daily driver.** Fast mode is Opus-class reasoning at higher
  throughput *without* downgrading the model. The old "sit on Sonnet to dodge latency" rule is
  retired.
- **Reserve Sonnet 4.6 for wide parallel leaves** (token economy on fan-outs); **Haiku 4.5 / local
  Qwen for grind** (migrations, boilerplate, renames).
- Keep the two routing axes separate:
  - *Product routing* — your app's runtime AI calls: `classifyQuery` → local Qwen (free) vs Claude.
  - *Harness routing* — which model each swarm role uses (see `docs/AI-ROUTING.md`).

---

## 3. Parallelization

- **Pick the mode by posture, not by size:**
  | Posture | Mode |
  |---|---|
  | At the keyboard, want it now | `/start-phase-team` |
  | Sequential, cost-sensitive | `/build-phase-autopilot` |
  | Overnight / AFK, durable | `/orchestrate-loops` |
- **Mode 3 → prefer the `Workflow()` substrate** for a static task list: free resume
  (`resumeFromRunId`), automatic concurrency cap, schema-validated leaf results, ~0 orchestration
  token cost. Drop to the background-agent loop only when the DAG must re-plan mid-run (ADR 0001).
- **Fan-out width = `min(16, cores−2)`** — that's **12 on the M4 Pro**, not 2. Let the harness cap
  it; don't hand-throttle. Watch for thermal throttling on sustained multi-hour runs.
- **Never poll.** Background work re-invokes you on completion. Use `ScheduleWakeup` only as a long
  (1200 s+) fallback heartbeat, never a tight loop.

---

## 4. Non-negotiable guardrails

- **The human phase gate never self-approves.** No mode or substrate bypasses `/phase-review`.
- **`guard-file-domain.sh` must be wired before any parallel write run** — it is the only thing
  preventing a merge storm when multiple leaves write the same repo.
- **Tests before commit; ADR for any decision meeting the 3-test threshold.**
- **Secrets:** never write to `~/.ssh`, `~/.aws`, `~/.gnupg`; `check-secrets-staged.sh` runs on
  every Write; `secret-scan.sh` pre-commit.

---

## 5. The golden-path loop

```bash
ccc                      # launch (caffeinate + re-index vault on exit)
/start-session           # in a scaffolded app: reload phase/tasks/ADRs
/plan-feature <name>     # PM + architect + (UI) design review
/build-feature <slug>    # vertical-slice TDD
/diagnose                # when something breaks
/vault-update            # end of session: refresh INDEX.md + re-index
/phase-review N          # end of phase: product-owner gate + human signature
git pull && make install # whenever the toolkit repo changed
```
