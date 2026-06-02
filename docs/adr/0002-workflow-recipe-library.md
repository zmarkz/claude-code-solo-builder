# ADR 0002 — Ship a committed, profile-aware library of Workflow() recipes

- **Status:** Accepted
- **Date:** 2026-06-02
- **Deciders:** Markandey Singh (with Claude / Opus 4.8)

## Context

ADR 0001 standardized the `Workflow()` tool as the Mode-3 durable-loop substrate, but the setup shipped
**zero committed workflow assets** — `Workflow()` was only ever authored at runtime inside
`/orchestrate-loops`. The doctrine (`docs/SWARM-ORCHESTRATION.md`, `BEST-PRACTICES.md`, the
`CLAUDE.md.template`) repeatedly promised a `.claude/workflows/` recipe library that did not exist. The
highest-leverage `Workflow()` patterns Anthropic ships the tool for — adversarial verify, judge panel,
loop-until-dry, multi-modal sweep, completeness critic — were not captured as reusable, shareable
assets. Meanwhile a downstream project had independently grown a strong build-orchestration recipe,
proving the pattern was worth committing upstream and generalizing.

The goal: operationalize the doctrine for **maximum execution speed and quality by default**, on a
Claude Max plan where the binding constraint is the **weekly Opus sub-cap**, not per-token cost.

## Decision

Commit a library of **seven profile-aware recipes** to `starter-kit/reference/workflows/` (propagated
like `agents/` and `commands/`): `exhaustive-review`, `codebase-map`, `security-sweep`, `design-panel`,
`safe-migration`, `release-readiness`, `fast-dag-build`. Only `safe-migration` and `fast-dag-build`
write; the rest are read-only.

- **Invocation.** Saved recipes auto-register as `/<name>`. Add **four** thin commands for
  discoverability and profile-forwarding: `/review-exhaustive`, `/audit-security`, `/map-codebase`, and
  `/mode`. The other recipes stay invocation-by-name, referenced from existing commands.
- **Two profiles, default Best.** Every recipe reads `args.mode` (`best` default / `saver`). Best =
  wide fan-out, 5 Sonnet skeptics/finding, Opus synthesis; Saver = narrow, Haiku skeptics, Sonnet
  synthesis. Even Best keeps bulk leaves (skeptics, grind) on Sonnet/Haiku — to preserve the weekly
  Opus cap, not to cut token cost. `/mode best|saver` sets the session profile; the runtime cannot flip
  `/model` programmatically, so `/mode` records the profile for `args.mode` forwarding and prints the
  manual model/effort switch.
- **Propagation across three paths.** `install.sh` (repo → `~/.claude/workflows/`, additive, README
  excluded), `/sync-project` (→ existing projects), and `starter-kit/SKILL.md` (→ new scaffolds). The
  scaffold path was the one the first draft missed.
- **`safe-migration` is the generic, committed form of the Mode-3 substrate** ADR 0001 prescribed —
  reusing the same safety contract (non-overlapping `domain_globs`, `isolation:'worktree'`, attempt cap,
  `guard-file-domain.sh`, human gate) for the common "one big codemod" case.
- **Authoring constraints (runtime ground truth).** `export const meta` must be a **pure literal** or
  the loader rejects it. Recipes are **plain JavaScript** with **no filesystem/shell/env access** — all
  configuration arrives via `args` (a repo path defaults to `'.'`, never `process.cwd()`).
- **Phantom-roster reconciliation.** The deleted `claude solo/` draft named agents that never existed
  (`verifier`, `db-migrator`, `mcp-eval-engineer`, …). Those map to capabilities the recipes now
  operationalize as *pipeline stages* rather than standalone agents: `verifier` → the adversarial-verify
  stage; `db-migrator` → `backend-engineer` + `safe-migration`; `mcp-eval-engineer` → `ai-engineer`. The
  real 11-agent roster is unchanged.

## Consequences

**Positive**
- The doctrine's promised `.claude/workflows/` library now exists and is shareable on clone.
- Max-quality verification (adversarial skeptics, judge panels, loop-until-dry) is one command away.
- Recipes scale cleanly between max-quality and token-saver via a single `args.mode` knob.
- `safe-migration` gives the Mode-3 substrate a reusable, parameterized home.

**Negative / trade-offs**
- More surface to maintain (7 recipes + 4 commands + 3 propagation edits).
- Recipes cost meaningfully more tokens than a normal turn; the opt-in + `budget` guard, but the
  discipline is on the operator.
- `/mode` is session sugar, not an enforced setting — it cannot flip `/model` for the user.

## References

- `starter-kit/reference/workflows/README.md` — recipe index + authoring rules
- `docs/SWARM-ORCHESTRATION.md` › *Saved recipes (the committed Workflow assets)*
- `docs/BEST-PRACTICES.md` §6–§7 — recipes + operating profiles
- `docs/TOKEN-EFFICIENCY.md` › *On Max plans: the weekly cap is the budget*
- ADR 0001 — `Workflow()` as the Mode-3 substrate
