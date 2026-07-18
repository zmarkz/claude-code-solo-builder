# Benchmark: Our Setup vs Karpathy's CLAUDE.md

> Karpathy's CLAUDE.md has 134k GitHub stars. This doc compares it against our setup,
> identifies gaps, and records the improvements we applied.

---

## What Karpathy Has (verbatim distillation)

65 lines. 4 behavioral principles. No stack config. No tool routing. No project structure.
His file is a **behavioral OS for Claude** — how to think, not what tools to use.

### Principle 1 — Think Before Coding
- State your understanding of the request before writing code.
- If ambiguous: present 2–3 interpretations and ask which is right.
- Never assume a requirement that isn't stated.
- Stop and ask rather than guess and redo.

### Principle 2 — Simplicity First
- Write the minimum code that correctly solves the stated problem.
- No speculative features ("while I'm here…").
- No abstractions built for a single use-case.
- No design patterns applied unless complexity obviously demands them.
- Simple, readable code beats clever code every time.

### Principle 3 — Surgical Changes
- Touch only what you must. No opportunistic cleanups.
- Match the existing style of the file — don't impose your own.
- Don't "improve" adjacent code that wasn't asked about.
- Small, reviewable diffs are a feature.

### Principle 4 — Goal-Driven Execution
- Transform any task into a verifiable goal before starting.
- Write the test (or describe the observable outcome) first.
- For multi-step work: state the plan before executing.
- Track whether each step moved toward the goal.

---

## What Our Setup Has (Karpathy doesn't)

| Capability | Details |
|---|---|
| **Knowledge vault** | Cross-project knowledge graph. kg_search before every task. Cross-project pattern discovery. |
| **AI model routing** | COMPLEX → Claude Sonnet (paid), SIMPLE → Qwen local (free). 93% of queries free. |
| **Kill discipline** | Portfolio tracker with kill-by dates enforced. Postmortem required. Anti-patterns documented. |
| **Operational skills** | 30+ gstack + 14 mattpocock + seed skills. /ship, /qa, /investigate, /retro all automated. |
| **Rolling context compression** | Qwen compresses every 3 turns → 85% token reduction. Sessions stay cheap indefinitely. |
| **Two-stack doctrine** | Your primary stack vs an optional legacy stack. Clear rules, no rewrites. |
| **Scheduled digest** | Nightly briefing (e.g. Telegram/Slack bot). Portfolio health, kill-by alerts, cost report. |
| **Secret scanning** | scripts/secret-scan.sh pre-commit on every project. |
| **Tenant isolation** | tenant_id mandatory on all multi-tenant tables from day one. |
| **Cross-project routing** | CLAUDE.md keyword routing rules map requests to the right project directory. |
| **Vault-first behavior** | kg_search → check 02-Areas → Context7 before any non-trivial task. |
| **Context7 integration** | Fresh library docs on demand. Never relies on stale training data for APIs. |
| **Postmortem system** | 04-Archive/ with postmortem required before any restart. Failure patterns documented. |

---

## Gap Analysis: What We Were Missing

### Gap 1 — No Explicit "Think Before Coding" Principle
**Karpathy**: Claude must state its interpretation before writing any code.
**Ours**: Silent. Nothing in `~/.claude/CLAUDE.md` tells Claude to surface assumptions.
**Impact**: Claude frequently picks an interpretation and codes it without confirming. Rework happens.
**Fix**: Add the principle verbatim.

### Gap 2 — No Explicit "Simplicity First" Rule
**Karpathy**: Minimum code that solves the problem. No speculative features.
**Ours**: `Never use` list covers technology choices (jQuery, Material UI) but not behavioral scope-creep.
**Impact**: Claude adds "while I'm here" code, premature abstractions, extra error handling.
**Fix**: Add explicit scope discipline.

### Gap 3 — No "Surgical Changes" Rule
**Karpathy**: Touch only what was asked. Don't improve adjacent code.
**Ours**: Nothing.
**Impact**: Diffs grow. Reviews take longer. Unexpected regressions from "improvements" to unrelated code.
**Fix**: Add surgical changes rule.

### Gap 4 — No "Goal-Driven Execution" Rule
**Karpathy**: Transform task → verifiable goal → test → plan → execute.
**Ours**: Nothing explicit. We have "pnpm typecheck && pnpm test before PR" but that's post-hoc.
**Impact**: Claude dives into multi-step tasks without stating a plan. Hard to redirect mid-flight.
**Fix**: Add goal-driven execution — state plan before multi-step tasks.

### Gap 5 — Behavioral Principles Buried Under Config
**Karpathy**: 100% behavioral. Nothing about stack.
**Ours**: Stack config dominates `~/.claude/CLAUDE.md`. The behavioral surface is small.
**Risk**: Claude treats CLAUDE.md as a config file to look up, not a behavioral OS to internalize.
**Fix**: Move behavioral principles to the TOP of `~/.claude/CLAUDE.md`, before stack config.

---

## Verdict

Karpathy's file is a **behavioral layer** (how to think and act).
Our file is a **configuration layer** (what stack to use, where files live).

Neither replaces the other. A complete setup needs both.

**Karpathy wins on**: behavioral discipline, simplicity enforcement, scope containment.
**We win on**: tool ecosystem, context retrieval, cost control, kill discipline, cross-project coherence.

**Action**: Merge Karpathy's 4 principles into the TOP of our `~/.claude/CLAUDE.md` as `## Behavioral Principles`.

---

## What We Applied

Added `## Behavioral Principles` section to `~/.claude/CLAUDE.md` with all 4 Karpathy principles.
Positioned BEFORE stack config so Claude encounters them first.

Applied: 2026-05-17

---

## What We Chose Not to Apply

Karpathy's file has no tool routing, no vault-first, no MCP config.
We kept all of those — they handle different problems (infrastructure knowledge, cost control).

The principles are additive, not replacements.
