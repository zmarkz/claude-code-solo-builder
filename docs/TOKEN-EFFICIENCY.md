# Token Efficiency Guide

> Verified against Claude Code v2.1.214 — 2026-07-18
>
> How to get 85-93% cost savings while building faster with Claude Code.

---

## The Real Cost Problem

Most developers using Claude Code bleed tokens in three ways:

1. **Model waste** — sending simple lookups to expensive models
2. **Context bloat** — loading the same boilerplate every session
3. **Re-explaining** — telling Claude things it already decided last week

This guide fixes all three.

---

## On Max plans: the weekly cap is the budget, not the token

> **If you're on a Claude Max plan (e.g. Max 20x), read this first.** You pay a flat subscription, not
> per token — so the strategies below split into two buckets:
>
> - **Product-runtime AI** — your *app's own* API calls (Strategy 1, Strategy 10). Still real money.
>   Keep the frugality: classify → route the bulk of simple queries to a free local model, etc.
> - **The harness** — how *you* drive Claude Code (which model your sessions and swarm roles use). Token
>   cost is **not** your constraint here; the **weekly Opus sub-cap** is — drain it mid-week and you get
>   silently downgraded to Sonnet. Reframe the harness goal as *"spend the weekly Opus cap on judgment,
>   not grind."* Lean **into** wide workflows/parallelization (that's what the 20x headroom buys);
>   reserve Opus for planning, synthesis, and final review; run bulk leaves (skeptics, mechanical grind)
>   on Sonnet/Haiku to make the cap last; cap any fan-out with the workflow `budget`.
>
> This split is exactly the **Best** profile (`/mode best`, the default) vs **Saver** (`/mode saver`) —
> see `docs/BEST-PRACTICES.md` §7. Strategies 2, 6, 7 below apply to the harness bucket; the rest mostly
> to product-runtime.

---

## Strategy 1 — AI Model Routing (85% savings)

The single largest optimization. **Never send every query to Claude** — classify first.

### The COMPLEX vs SIMPLE split

```
COMPLEX (→ Claude Sonnet, paid ~$0.001–0.003/call):
  analyze, recommend, decide, sell, buy, risk, plan, forecast,
  rebalance, should I, compare, strategy, tax, deep dive,
  outlook, action plan, which is best/worst, portfolio health

SIMPLE (→ local model via Ollama, FREE):
  what is, how many, show me, list, allocation, explain, define,
  total value, how much, summary, what does, meaning, count

DEFAULT → COMPLEX (safer — use Claude if unsure)
```

### Implementation

Route through a classifier layer, not directly to the model:

```typescript
// NEVER do this:
const result = await anthropic.messages.create({...})

// ALWAYS do this — classify first, then route:
const complexity = classifyQuery(userMessage) // "COMPLEX" | "SIMPLE"
const model = complexity === "COMPLEX" ? PAID_MODEL : LOCAL_MODEL
const result = await route(model, userMessage)
```

Routing like this typically serves the large majority of queries from a free local model, cutting
product-runtime AI cost by ~85%+ — the exact split depends on your query mix.

---

## Strategy 2 — Model Selection by Task

Don't always reach for Sonnet. Match the model to the task:

| Task | Model | Cost Multiplier |
|------|-------|----------------|
| Planning, architecture, code review | Opus 4.8 | 5x |
| Parallel feature execution | Sonnet 4.6 | 1x (baseline) |
| Repetitive / structured work (tests, boilerplate) | Haiku 4.5 | 0.05-0.1x |
| Local / private / cost-sensitive | Qwen3-Coder 32B via MLX | 0x |

**Pattern for swarm teams:**
- Team Lead (planning, decomposition) → Opus 4.8
- Workers (parallel feature execution) → Sonnet 4.6
- Repetitive tasks (type stubs, test fixtures) → Haiku 4.5

---

## Strategy 3 — CLAUDE.md ≤ 200 Lines (The Cap Rule)

`CLAUDE.md` is loaded at the start of **every session**. Every extra line costs you tokens forever.

**Hard rule: CLAUDE.md must be ≤200 lines.**

What belongs in CLAUDE.md (L1 personal):
- Stack defaults (non-negotiables, 5-10 lines)
- Security rules (never-do list, 5 lines)
- MCP vault-first rule (3 lines)
- Available skills (list, 10-15 lines)

What does NOT belong:
- Full architecture docs → reference `ARCHITECTURE.md` by name, don't inline
- Test case lists → reference `TEST_CASES.md`
- Full API endpoint lists → reference project CLAUDE.md
- Database schemas → in code, not in CLAUDE.md

**CLAUDE.md hierarchy (three levels):**

```
L1 — ~/.claude/CLAUDE.md            ← Personal non-negotiables (<200 lines)
L2 — <app>/CLAUDE.md                ← Per-app rules + contracts (~100 lines)
L3 — <app>/<module>/CLAUDE.md       ← Only where a subdir has unusual rules
```

Progressive disclosure: keep task-specific docs in separate files and reference them.

---

## Strategy 4 — Vault-First Queries (Avoid Re-Explaining)

Every time you explain a past decision to Claude, you're paying twice — once when you made it, once now. The vault captures past decisions so you never re-explain.

**Before every non-trivial task, Claude should:**
1. `kg_search` the vault for related prior decisions
2. For architecture decisions: check `02-Areas/` and ADRs in `01-Projects/`
3. For library work: query Context7 for fresh docs
4. Synthesize vault findings + fresh docs → then write code

**What this saves:**
- "How should I handle Stripe webhooks?" → finds your past Stripe ADR + wrapper
- "What's our auth pattern?" → finds your security architecture decision
- "How did we structure this table?" → finds your schema migration ADR

**Setup:** The vault is an optional module — see `docs/VAULT.md` for enabling it and wiring the MCP servers.

---

## Strategy 5 — Context Window Management

> **Caveat (2026):** Current frontier models ship 1M-token context; several context-rationing tactics
> below matter less than when this was written — re-evaluate before optimizing.

A context window degrades noticeably above 70% utilization. Strategies:

### Use swarms, not monolith sessions

Instead of one long session doing everything:
```
One long session:
  Planning → Design → Backend → Frontend → Tests → Review
  → Context fills, quality degrades mid-session
```

Use parallel workers with isolated contexts:
```
Worker A (small context): Backend API endpoint
Worker B (small context): Frontend component
Worker C (small context): Tests + fixtures
Team Lead (small context): Decompose → merge → review
```

### The PreCompact hook

When Claude Code compacts the context, it fires the `PreCompact` hook first. `session-snapshot.sh` dumps the current state to `docs/session-snapshots/` before compaction happens:

```bash
# scripts/session-snapshot.sh fires on PreCompact
# Saves: current branch, HEAD, uncommitted files, recent commits, open tasks
```

This means even after compaction, you can `/start-session` and recover instantly.

### /start-session at session start

Always begin with `/start-session`. It reads:
- Active phase from ROADMAP.md
- Open tasks from TASKS.md
- Recent decisions from ADR index
- Current branch and uncommitted work

Costs ~200 tokens but saves the first 10 minutes of every session.

---

## Strategy 6 — /caveman for Long Sessions

For long sessions where communication verbosity is high, `/caveman` compresses by ~75%:

```
Normal mode: "I've analyzed the codebase and I believe the issue stems from..."
Caveman mode: "Bug: race condition OrderService line 47. Fix: add mutex. Test: concurrent 100 orders."
```

`caveman` is a **frozen local skill** — mattpocock deleted it upstream during the 2026-07 plugin migration, so it lives locally under `~/.claude/skills/` (not in the `mattpocock-skills` plugin). Nothing to install; invoke it by name.

When to use:
- Session is >2 hours old
- You're in implementation mode (not planning)
- Context window is above 50% utilization

When NOT to use:
- Planning sessions (need full reasoning)
- Security review (need explicit logic)
- First session on a new feature (need full spec)

---

## Strategy 7 — Session Architecture

**5-hour rolling usage windows** (doubled on Pro/Max). Plan sessions around this:

| Session type | Typical length | Model | Purpose |
|-------------|---------------|-------|---------|
| Planning | 30-60 min | Opus 4.8 | Architecture, ADRs, phase planning |
| Feature build | 2-4 hours | Sonnet 4.6 | Vertical-slice implementation |
| Bug fix | 30-90 min | Sonnet 4.6 | /diagnose loop |
| Review | 30-60 min | Opus 4.8 | PR review, security review |
| QA | 1-2 hours | Haiku 4.5 | Test generation, fixture work |

Break features into focused sub-tasks, each in its own session. A "restart with fresh context" is free — a degraded near-full context is expensive.

---

## Strategy 8 — Structured Output for COMPLEX Queries

Instead of streaming prose, request structured JSON from complex queries. The frontend renders it more efficiently, and the model spends fewer tokens on formatting:

```json
{
  "summary": {"keyInsight": "...", "pnl": "..."},
  "sections": [
    {"type": "table", "title": "...", "rows": [[...]]},
    {"type": "recommendations", "items": [{"action": "BUY", "reason": "..."}]}
  ]
}
```

**Why this saves tokens:**
- No markdown formatting tokens in the response
- Cacheability: same JSON structure → prompt cache hit on subsequent calls
- Frontend renders deterministically — no model re-decisions on layout

---

## Strategy 9 — Prompt Caching

For repeat operations (document parsing, session summaries, daily briefings):

```typescript
// Cache the system prompt — cache reads cost ~10% of the base input price
const response = await anthropic.messages.create({
  model: "sonnet",
  system: [
    {
      type: "text",
      text: systemPrompt,
      cache_control: { type: "ephemeral" } // 5-minute cache TTL
    }
  ],
  messages: [{ role: "user", content: userMessage }]
})
```

The cache TTL is 5 minutes. For operations that repeat within that window (session summaries every few turns, daily briefings at a fixed time), a cache hit costs ~10% of the base input price — roughly a 90% saving on the cached tokens.

---

## Strategy 10 — Local Models for Free Operations

Several operations can run entirely locally with no API cost:

| Operation | Local model | Quality vs paid |
|-----------|------------|----------------|
| Document parsing (PDFs, CSVs) | Qwen2.5-coder:14b | Good enough for structured extraction |
| Session summarization (every 3 turns) | Qwen2.5-coder:14b | Adequate for factual summaries |
| Insight extraction from complex responses | Qwen2.5-coder:14b | Good for key-fact extraction |
| Embedding generation (RAG) | nomic-embed-text (768 dims) | On par with paid for retrieval |
| Daily briefings / formatting | Qwen2.5-coder:14b | Works well |

Setup Ollama:
```bash
brew install ollama
ollama pull qwen2.5-coder:14b
ollama pull nomic-embed-text
ollama serve
```

---

## The Combined Savings

Running all strategies:

| Strategy | Savings |
|----------|---------|
| Model routing (bulk to a free local model) | 85-93% of product AI cost |
| Haiku for repetitive tasks | 10-20x cheaper per task |
| Vault-first (no re-explaining) | Fewer tokens per session |
| CLAUDE.md ≤200 lines | Capped load cost |
| /caveman in long sessions | 75% compression |
| Local models for documents/summaries | 100% of that cost |
| Prompt caching | ~90% on cached input |

Stacked, these cut a multi-app AI bill by roughly an order of magnitude versus sending everything to a frontier model.

---

*See also: `PLAYBOOK.md` Part 2 for model selection by task, `docs/SWARM-ORCHESTRATION.md` for per-swarm-role model routing.*
