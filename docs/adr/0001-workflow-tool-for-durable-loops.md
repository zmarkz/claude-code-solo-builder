# ADR 0001 — Use the `Workflow()` tool as the default substrate for durable parallel loops

- **Status:** Accepted
- **Date:** 2026-05-29
- **Deciders:** Markandey Singh (with Claude / Opus 4.8)

## Context

Mode 3 (`/orchestrate-loops`) fans a phase out into one background, worktree-isolated agent per
file-domain, with attempt caps, timeouts, and a reviewer integrating the result. The original
implementation drove this with a **model-driven loop**: an Opus orchestrator *agent* read
`tasks.json`, decided which leaves to spawn via `Agent(isolation:"worktree", run_in_background:true)`,
polled them with `Monitor` / `ScheduleWakeup`, and tracked retries in a hand-rolled
`tasks.json.attempts` counter.

Since that design was written, the harness shipped a first-class orchestration primitive: the
`Workflow()` tool. It runs a deterministic JavaScript script whose `pipeline()` / `parallel()`
constructs fan work across agents in *code*, with:

- automatic concurrency capping at `min(16, cores−2)`,
- built-in resume (`resumeFromRunId`) that replays the unchanged prefix from cache and re-runs only
  failed/edited leaves,
- schema-validated structured returns per agent,
- `isolation:'worktree'` as a first-class per-agent option,
- a shared token `budget` across all leaves.

For "partition a static task list into a domain DAG and run the leaves," every one of those maps
directly onto a need the hand-rolled loop met manually (and less robustly).

## Decision

Make `Workflow()` the **default substrate** for Mode 3 when the task list is static. Keep the
background-agent loop as an explicit **fallback** for the one case `Workflow()` does not serve well:
decomposition that must adapt *during* the run based on leaf results.

The durability contract is unchanged and now lives *in the script*: per-leaf retry loop (attempt
cap), timeout, 4 h wall-clock ceiling, and `LEAF_DOMAIN_GLOBS` passed into each leaf's prompt so the
`guard-file-domain.sh` `PreToolUse` hook still blocks out-of-domain writes. The human phase-review
gate is untouched — neither substrate self-approves.

`/orchestrate-loops` authors and invokes the script. Because `Workflow()` requires explicit user
opt-in (the keyword "workflow", or ultracode), the command surfaces that it is running as a workflow.

## Consequences

**Positive**
- Orchestration control flow costs ~0 tokens (it's code, not an Opus agent's reasoning).
- Killed/edited overnight runs resume cheaply instead of restarting.
- Concurrency auto-matches the host (≈12 leaves on the M4 Pro) instead of the old conservative "2".
- Per-leaf results are schema-validated, not parsed from prose summaries.

**Negative / trade-offs**
- Two substrates to document and maintain instead of one.
- `Workflow()` is single-level (no nested workflows) and needs explicit opt-in, so the dynamic-
  decomposition case still needs the agent-loop path.
- Authors must encode the durability knobs in JS rather than relying on the agent to "remember" them.

## References

- `docs/SWARM-ORCHESTRATION.md` › *Two substrates for Mode 3*
- `starter-kit/reference/commands/orchestrate-loops.md` › *Choose the substrate*
- `docs/AI-ROUTING.md` › loop-role model routing *(doc moved to the private overlay in v3.0 — see `docs/TOKEN-EFFICIENCY.md` Strategy 2)*
