# Token Efficiency Guide

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
>   Keep the frugality: classify → route 93% to local Qwen, etc.
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

SIMPLE (→ local Qwen via Ollama, FREE):
  what is, how many, show me, list, allocation, explain, define,
  total value, how much, summary, what does, meaning, count

DEFAULT → COMPLEX (safer — use Claude if unsure)
```

### Implementation

Route through an Agent Farm classifier, not directly to the model:

```typescript
// NEVER do this:
const result = await anthropic.messages.create({...})

// ALWAYS do this — route through classifier first:
const complexity = classifyQuery(userMessage) // "COMPLEX" | "SIMPLE"
const template = complexity === "COMPLEX" ? TEMPLATE_3_CLAUDE : TEMPLATE_4_LOCAL
const result = await agentFarm.execute(template, userMessage)
```

### Real-world cost evidence

| Period | Without routing | With routing | Savings |
|--------|----------------|--------------|---------|
| Monthly (portfolio app) | ~₹200+ | ~₹28 | 85%+ |
| Per query distribution | 100% paid | 7% paid, 93% free | — |

The mcp-farm Agent Farm in this setup handles templates:
- **Template 3** — Claude Sonnet 4.6 (complex analysis, structured JSON output)
- **Template 4** — Qwen local via Ollama (simple queries, streaming markdown, ₹0)

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

**Setup:** See `docs/OBSIDIAN-CONTEXT7.md` for MCP server installation.

---

## Strategy 5 — Context Window Management

The 200K context window degrades noticeably above 70% utilization. Strategies:

### Use swarms, not monolith sessions

Instead of one long session doing everything:
```
One session (200K context):
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

Install from mattpocock/skills: `npx skills@latest add mattpocock/skills` → select `caveman`.

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

Break features into focused sub-tasks, each in its own session. A "restart with fresh context" is free — a degraded 180K context is expensive.

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
// Cache the system prompt — pays ~25% of full cost on cache hit
const response = await anthropic.messages.create({
  model: "claude-sonnet-4-6",
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

The cache TTL is 5 minutes. For operations that repeat within that window (session summaries every 3 turns, daily briefings at a fixed time), cache hits reduce cost by 75-90%.

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
| Model routing (93% local) | 85-93% of AI cost |
| Haiku for repetitive tasks | 10-20x cheaper per task |
| Vault-first (no re-explaining) | Fewer tokens per session |
| CLAUDE.md ≤200 lines | Capped load cost |
| /caveman in long sessions | 75% compression |
| Local Qwen for documents/summaries | 100% of that cost |
| Prompt caching | 75-90% on cached hits |

**Real monthly cost for a portfolio of 2-3 active apps: ~₹50-100 (~$0.60-1.20)**

Without these strategies, the same portfolio would cost ₹500-2000/month in Claude API calls.

---

## Cost Monitoring

Log every AI call:
```
[ROUTING] query="Analyze portfolio" → COMPLEX → Claude (template 3) | session=42
[RESULT]  COMPLEX → Claude | 31000ms | 3957chars | ~₹5.05 | JSON_STRUCTURED
[ROUTING] query="How many stocks?" → SIMPLE → Qwen local (template 4)
[RESULT]  SIMPLE → Qwen local | STREAMING_MARKDOWN | cost=₹0.00
```

View cost breakdown:
```bash
docker logs -f portfolio_tracker_api 2>&1 | grep "\[RESULT\]" | grep "₹" | awk -F'₹' '{print $2}' | paste -sd+ | bc
```

---

*See also: `docs/AI-ROUTING.md` for the implementation pattern, `PLAYBOOK.md` Part 2 for model selection by task.*
