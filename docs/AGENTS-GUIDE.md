# The 11 Specialist Agents — Guide

> Why specialized agents outperform "just Claude" for serious work.

---

## The Core Argument

Matt Pocock's skills approach assumes you bring senior-engineer judgment to every domain. That works if you *are* a senior engineer in every domain. If you're solo and shipping B2B SaaS with auth + payments + multi-tenancy, you can't simultaneously be a security architect, a QA engineer, a product manager, AND a backend engineer.

Specialized agents codify those roles' working rules. They're cheap to invoke, and they catch what generalists miss.

---

## The 11 Agents

### 1. product-manager

**When to invoke:** Scoping features, writing user stories, validating proposals against personas, trimming scope.

**What it does differently:**
- Reads `PROJECT_CONTEXT.md` (personas, market, non-goals)
- Asks "does this serve persona X?" not "is this technically possible?"
- Produces a vertical-slice spec in `docs/specs/<slug>.md`
- Refuses to scope features without knowing who benefits and how

**Invoke when:** A new feature is being considered, or current work feels too big to finish in one sprint.

### 2. solution-architect

**When to invoke:** System design decisions, ADRs, evaluating trade-offs, reviewing cross-service changes.

**What it does differently:**
- Applies the 3-test ADR threshold before writing any ADR: *hard-to-reverse + surprising-without-context + real-trade-off*
- Writes ADRs in `docs/adr/NNNN-<slug>.md` with Context / Decision / Alternatives / Trade-offs / Reversibility
- Reads CONTEXT.md for ubiquitous language before any non-trivial response
- Refuses to approve changes that cross service boundaries without an ADR

**Invoke when:** Before any change that crosses service boundaries or introduces a new technology.

### 3. security-architect

**When to invoke:** Any change touching auth, tenancy, storage, network, or model calls.

**What it does differently:**
- 10-point security checklist on every review
- Checks for prompt injection, SSRF, SQL injection, IDOR, broken auth, missing rate limits
- Requires explicit threat model for any new auth surface
- Mandates `tenant_id` in every multi-tenant table
- Mandates audit log for every state change (actor, tenant, resource, action, before/after hash)

**Checklist excerpt:**
1. Input validation: Zod schemas at all API boundaries
2. Auth: JWT expiry, rotation, refresh logic
3. Tenancy: all queries filtered by tenant_id
4. Storage: RLS policies tested with cross-tenant test
5. Secrets: no secrets in code, logs, or error messages
6. Rate limiting: auth endpoints have stricter limits
7. CORS: explicit allowlist, not wildcard
8. Prompt injection: LLM inputs sanitized
9. Dependency CVEs: no high-severity unaddressed
10. Audit log: every state change captured

**Invoke:** Proactively whenever code touches auth, tenancy, storage, or AI — not just when asked.

### 4. backend-engineer

**When to invoke:** API endpoints, database models, migrations, worker tasks, service code.

**What it does differently:**
- Follows the stack defined in CLAUDE.md (no deviations without ADR)
- Always adds Zod validation at API boundary
- Vertical slice: schema → API → worker → test (never just the API without the test)
- Uses the patterns established in CONTEXT.md

**Invoke when:** Implementing backend features from a spec.

### 5. frontend-engineer

**When to invoke:** UI pages, components, styling, server-state hooks, forms.

**What it does differently:**
- **Reads `DESIGN.md` before any implementation** — it is the design source of truth
- Blocks on missing DESIGN.md for non-trivial UI surfaces — prompts `/design-consultation`
- Invokes `frontend-design` skill for aesthetic direction on new pages/major components
- Uses Figma MCP `get_design_context` when a Figma URL is in project context
- Server Components by default, `"use client"` only when genuinely needed
- Reads existing component patterns before creating new ones
- No new UI primitives if shadcn/ui has it
- Always includes all four render states: loading skeleton, empty, error, success
- Rejects generic AI defaults (Inter font, purple gradients, flat layouts) — DESIGN.md or `frontend-design` output overrides

**Invoke when:** Implementing UI features from a spec.

**Design pipeline this agent follows:**
1. Check DESIGN.md → invoke `frontend-design` for aesthetic brief → build → `/design-review` exit gate

**After any UI implementation:** suggests `/design-review` before marking the task done.

### 6. ai-engineer

**When to invoke:** RAG pipelines, embeddings, retrieval, LLM prompt design, structured output schemas, evaluation datasets.

**What it does differently:**
- Always routes AI calls through the Agent Farm classifier (never direct API calls)
- Designs structured output schemas for COMPLEX queries
- Writes evaluation datasets alongside prompts
- Explicitly handles hallucination controls and output validation

**Invoke when:** Designing or modifying any AI feature.

### 7. devops-engineer

**When to invoke:** Docker, CI workflows, observability, deployment, Makefile changes.

**What it does differently:**
- All services bind to 127.0.0.1, not 0.0.0.0
- Multi-stage Dockerfiles with non-root users
- Health checks on every service
- No secrets in Dockerfiles or docker-compose.yml

**Invoke when:** Infrastructure changes, CI breakage, or developer-experience improvements.

### 8. qa-engineer

**When to invoke:** Test strategy, evaluation datasets, adversarial test cases, regression coverage.

**10-item adversarial catalog:**
1. Empty state (no data, new user)
2. Maximum data (performance at scale)
3. Concurrent writes (race conditions)
4. Partial failure (service timeout mid-operation)
5. Permission boundary (user accessing another user's data)
6. Injection (SQL, prompt, command)
7. Network interruption (retry behavior)
8. Malformed input (missing fields, wrong types, XSS payloads)
9. Session expiry (mid-operation)
10. Idempotency (same request twice)

**Invoke when:** Phase nears completion or when adding a feature that touches existing behavior.

### 9. domain-expert

**When to invoke:** Business domain concepts, regulations, industry standards, compliance requirements.

**What it does differently:**
- Cites sources with explicit version/date (regulatory docs change)
- Distinguishes "aligned with X" from "certified by X"
- Refuses to answer as a professional advisor (legal, medical, financial)
- Flags when something requires licensed professional review

**Invoke when:** Features reference domain-specific concepts, regulations, or industry standards.

### 10. technical-writer

**When to invoke:** README updates, runbooks, API documentation, onboarding guides.

**What it does differently:**
- Writes for the reader who arrived 6 months later with no context
- Includes "why" comments for non-obvious decisions
- Keeps CLAUDE.md ≤200 lines (enforces the cap)
- Updates docs alongside code changes (not at the end)

**Invoke when:** Phase nears completion or after significant feature addition.

### 11. product-owner-reviewer

**When to invoke:** End-of-phase review gate — only at phase boundaries via `/phase-review`.

**What it does differently:**
- Produces a one-page exec summary at `docs/phase-reviews/phase-N.md`
- Demoability check: "Can this be shown to a real user in a 10-minute session?"
- Business-risk callouts: what breaks if this ships?
- Go / Fix / Redo recommendation

**Invoke when:** Using `/phase-review N` at phase boundaries. No autopilot self-approves.

---

## Model Routing per Agent

Every agent now declares a `model:` field in its frontmatter. This pins the right model to the right cognitive load — saving cost on lightweight roles without compromising on high-stakes ones.

| Agent | Model | Reason |
|-------|-------|--------|
| `security-architect` | `opus` | Highest stakes — missed findings have real consequences |
| `solution-architect` | `opus` | Architecture decisions are hard to reverse |
| `product-owner-reviewer` | `sonnet` | Balanced judgment across business + technical |
| `ai-engineer` | `sonnet` | Complex but well-structured domain |
| `qa-engineer` | `sonnet` | Adversarial thinking needs depth |
| `backend-engineer` | `sonnet` | Standard implementation work |
| `frontend-engineer` | `sonnet` | Standard implementation work |
| `devops-engineer` | `sonnet` | Standard implementation work |
| `domain-expert` | `sonnet` | Domain research needs good recall |
| `product-manager` | `haiku` | Structured output, lightweight reasoning (~10-20x cheaper) |
| `technical-writer` | `haiku` | Doc formatting, low cognitive load (~10-20x cheaper) |

> **Why aliases, not pinned IDs.** `opus` / `sonnet` / `haiku` resolve to the
> latest model of each tier (currently Opus 4.8 / Sonnet 5 / Haiku 4.5) and
> advance automatically with Claude Code releases. Pinned IDs
> (`claude-sonnet-4-6`-style) hard-fail when a model is retired — the kit
> switched to aliases in v3.0 to eliminate that failure class. Pin a full ID in
> a project override only if you need snapshot stability.

---

## How Agents Work in Claude Code

### As subagents (within a session)

The main agent spawns them via the Task tool:
```
> "Review the auth changes with the security-architect perspective"
# Claude invokes security-architect as a subagent
# Returns structured findings
# Main agent incorporates and responds
```

### As agent-team teammates (parallel execution)

With `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`:
```bash
> /start-phase-team 1
```

Spawns 3-5 agents working in parallel with non-overlapping file domains. Each agent is its own Claude Code process with a fresh context window.

**Requirements:**
- Claude Code v2.1.32+
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in env
- Non-overlapping file domains assigned to each agent

**What NOT to do in agent frontmatter:**
```markdown
# DON'T add these — they're ignored when used as team teammates:
skills:
  - some-skill
mcpServers:
  - some-server
```

Only `tools`, `model`, and the body are honored for team teammates.

### Dual residency (the right installation pattern)

Install agents at **both** the project level and user level:

```bash
# Project level (generated by ai-project-scaffold):
.claude/agents/security-architect.md

# User level (also install here — improvements propagate):
~/.claude/agents/security-architect.md
```

Per-project overrides win when both exist. Unmodified projects pick up upstream improvements from user-level.

---

## The Right Time to Invoke Each Agent

```
New feature idea
  → product-manager (does it solve a real problem for a real persona?)

Feature approved
  → solution-architect (how to build it? ADRs needed?)
  → security-architect (if auth/tenancy/storage/LLM involved)
  → domain-expert (if regulated domain)

Implementation
  → backend-engineer (schema, API, worker)
  → frontend-engineer (UI, components)
  → ai-engineer (if AI feature)
  → devops-engineer (if infra change)

Testing
  → qa-engineer (test strategy, adversarial cases)

End of phase
  → product-owner-reviewer (exec summary, go/no-go)

Documentation
  → technical-writer (README, runbook, CLAUDE.md)
```

---

## Generating Custom Agents with `/write-an-agent`

The `domain-expert.md` in the base kit is a placeholder — it says "Replace this opening with your domain expertise." Use `/write-an-agent` to fill it in properly:

```
> /write-an-agent
```

The skill interviews you on:
- Domain name and problem space
- Applicable regulations / standards (e.g., RBI, SEBI, HIPAA, GDPR, PCI-DSS)
- 5–10 key terms that need precise definitions
- Authoritative sources to cite
- Professional claims to never make

It then generates a fully filled `domain-expert.md` and offers to install it at project and/or user level.

`/write-an-agent` also handles **custom specialists** not in the base 11 — `mobile-engineer` (Expo/React Native), `data-analyst`, `growth-engineer`, or any narrow workflow agent.

---

## Customizing Agents for Your Domain

The agents in `starter-kit/reference/agents/` are generic. After scaffolding a project, edit them to reflect your domain:

**For fintech:**
```markdown
# security-architect.md additions:
- Every financial calculation must be decimal-safe (no float arithmetic)
- KYC data requires separate encrypted storage
- Transaction state machines must be append-only
- All amounts stored in minor currency units (paise, not rupees)
```

**For healthcare:**
```markdown
# domain-expert.md additions:
- PHI handling: always cite HIPAA section
- Any user-facing health claim: flag for medical professional review
- De-identification required before any analytics
```

**For multi-region:**
```markdown
# security-architect.md additions:
- Data residency: EU user data stays in EU region
- GDPR: right-to-erasure must be implementable (no immutable event logs without GDPR exemption)
```

**Naming and splitting domain experts.** `domain-expert.md` is a placeholder — **rename it** to your
actual domain (`fintech-expert.md`, `health-expert.md`, `legal-expert.md`, …). A mature project often
grows *several* named specialists rather than one generic expert — e.g. a compliance expert, a
platform-infra expert, an audit/observability expert — each with a sharp `description:` so Claude
auto-delegates correctly. The 11-agent roster is the floor, not the ceiling: add named experts as the
domain demands. (Agent `name:` values double as the `agentType` the workflow recipes route to.)

---

*See also: `starter-kit/reference/agents/` for the actual agent definitions, `docs/SWARM-ORCHESTRATION.md` for parallel execution patterns.*
