# ADR 0005 — "Opus at the gates": workflow model retune for the Sonnet 5 era

**Status:** Accepted
**Date:** 2026-07-19
**Deciders:** Markandey (with Claude)

## Context

The Best/Saver profiles (ADR 0002) were designed when Opus was the only
top-tier model: Best mode put Opus on every synthesis lane. Sonnet 5
(mid-2026) is near-Opus in capability at a fraction of the cost — and on Max
plans the binding constraint is the **weekly Opus usage cap**, not token cost.
Every non-essential Opus lane spends the scarce resource. (Fable 5's cap
metering vs Opus is UNDOCUMENTED as of this ADR — this retune assumes the
weekly Opus cap remains the scarce budget; revisit if metering is clarified.)

## Decision

**Opus runs only at the gates.** A gate is a lane whose single output accepts
or rejects work with real consequences:

| Recipe | Opus lanes kept | Moved to Sonnet 5 (both modes) |
|---|---|---|
| security-sweep | authz + prompt-injection lenses, report (best) | — |
| safe-migration | integration reviewer (writes!) | discover |
| release-readiness | critic + verdict (best) | — |
| fast-dag-build | final code-review + product-owner verdict (best) | — |
| exhaustive-review | security lens | synthesis |
| design-panel | — | synthesis, proposals |
| codebase-map | — | synthesis, critic |

Agent frontmatter is unchanged: `security-architect` and `solution-architect`
stay `opus` (high-stakes, hard-to-reverse outputs — they ARE gates).
Saver mode is unchanged (was already Opus-free).

## Consequences

- Best-mode Opus consumption drops to gate lanes only — the single biggest
  stretch of the weekly cap available without quality risk.
- Quality risk accepted: synthesis/proposal lanes lose the Opus margin;
  mitigated by Sonnet 5's near-Opus capability and by the gates still
  catching bad synthesis downstream.
- Uses tier aliases (`opus`/`sonnet`/`haiku`, ADR 0003) — the doctrine
  survives model releases; re-evaluate lane assignments, not IDs.
- Measurement: if gate rejections rise after this change (more redone work),
  promote the offending synthesis lane back to `opus` and note it here.
