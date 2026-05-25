# Retrofitting Existing Projects

> How to bring an existing codebase into this setup without starting over.

---

## TL;DR — just run `/sync-project`

From any project directory:
```
> /sync-project
```
It probes the directory, detects whether this is a new project, an existing project needing a retrofit, or an existing project that just needs agents updated — then executes the right steps and asks only what it must. The rest of this doc explains what it does under the hood.

---

## The Core Principle: Don't Rebuild, Retrofit

The scaffold is a one-time generator for new projects. For existing projects, you retrofit the parts that add value — selectively, without disrupting what works.

**Do NOT:**
- Run `/ai-project-scaffold` on a project with existing code (it may overwrite)
- Migrate the stack just to match the standard (stack-hopping is failure mode #1)
- Add all 11 agents at once to a project that doesn't need them

**DO:**
- Add the planning docs (CLAUDE.md, CONTEXT.md, ARCHITECTURE.md) — high value, zero risk
- Add the agents you'll actually use — start with security-architect and solution-architect
- Add the hooks you need — start with `check-secrets-staged.sh` and `session-snapshot.sh`
- Ingest the project into the vault

---

## The Four Project Buckets

Before retrofitting, classify the project:

| Bucket | Meaning | Action |
|--------|---------|--------|
| `ACTIVE-BUILD` | Currently building, shipping features | Full retrofit — worth the investment |
| `VALIDATE` | Shipped MVP, checking product-market fit | Partial retrofit — docs + vault entry |
| `STABILIZE` | Has real users, maintenance mode | Minimal retrofit — vault entry + security hooks |
| `KEEP-AS-IS` | Personal tool / legacy / low priority | Vault entry only |

Apply the two-app rule: ≤2 projects in `ACTIVE-BUILD` simultaneously.

### Bucket transition rules

Moving `VALIDATE → ACTIVE-BUILD` requires:
- [ ] ≥5 paying users OR ≥50 active daily users
- [ ] Positive unit economics (LTV > 3× CAC)
- [ ] An open `ACTIVE-BUILD` slot

Moving `ACTIVE-BUILD → STABILIZE` requires:
- [ ] MVP shipped and validated
- [ ] No critical bugs open
- [ ] Handoff doc written

Kill criteria (if met, move to `ARCHIVE`):
- 3 months with no new paying users
- Negative unit economics with no clear path to fix
- Stack cost > monthly revenue

---

## Retrofit Procedure by Bucket

### ACTIVE-BUILD: Full Retrofit (~2-3 hours)

#### Step 1 — Create the planning docs

```bash
cd ~/your-existing-project
mkdir -p docs/adr .claude/agents .claude/commands scripts
```

Create `CLAUDE.md` (write it from scratch — ≤200 lines):
```markdown
# <project-name>

## What this is
[One paragraph]

## Stack
[Your actual stack — don't lie]

## Key conventions
[Naming patterns, auth flow, DB pattern]

## Never do
[Your project-specific non-negotiables]

## Test commands
[How to run tests]

## Current phase
Phase X — [goal]
```

Create `CONTEXT.md` (DDD glossary):
```markdown
# <project-name>

## Language
**Order**: A customer's purchase intent, from cart to fulfillment.
*Avoid*: "purchase", "transaction" (ambiguous with payment transactions)

**Fulfillment**: The process of delivering an order.
*Avoid*: "shipping", "delivery" (partial)

## Relationships
- An **Order** has many **LineItems**.
- A **LineItem** belongs to one **Product** and one **Order**.

## Flagged ambiguities
- "payment" was used to mean both "order payment" and "subscription payment" — resolved: use "order_payment" and "subscription_charge"
```

Create `ARCHITECTURE.md` — describe your actual system. Pull from existing docs or code comments.

#### Step 2 — Install agents (start with 3)

```bash
cp ~/.claude/agents/security-architect.md .claude/agents/
cp ~/.claude/agents/solution-architect.md .claude/agents/
cp ~/.claude/agents/product-manager.md .claude/agents/
```

Add others as you need them. Don't install all 11 upfront.

#### Step 3 — Install commands (start with 5)

```bash
# Core workflow commands
cp ~/.claude/commands/start-session.md .claude/commands/
cp ~/.claude/commands/plan-feature.md .claude/commands/
cp ~/.claude/commands/build-feature.md .claude/commands/
cp ~/.claude/commands/review-security.md .claude/commands/
cp ~/.claude/commands/phase-review.md .claude/commands/
```

#### Step 4 — Install hooks (start with 2)

```bash
cp ~/.claude/skills/ai-project-scaffold/reference/scripts/check-secrets-staged.sh scripts/
cp ~/.claude/skills/ai-project-scaffold/reference/scripts/session-snapshot.sh scripts/
chmod +x scripts/*.sh
```

The secret-scan hook prevents accidental credential commits. The session-snapshot hook saves state before context compaction.

#### Step 5 — Create basic settings.json

```bash
cp ~/.claude/skills/ai-project-scaffold/reference/settings.json.template .claude/settings.json
# Edit: set your actual allow list for this project
```

#### Step 6 — (ACTIVE-BUILD only) Enable durable parallel loops

To run `/orchestrate-loops` (Mode 3 — durable, headless parallel builds), add the substrate +
enforcement hook:

```bash
cp ~/.claude/commands/orchestrate-loops.md .claude/commands/
cp ~/.claude/skills/ai-project-scaffold/reference/scripts/guard-file-domain.sh scripts/
cp ~/.claude/skills/ai-project-scaffold/reference/scripts/tasks-sync.sh scripts/
chmod +x scripts/*.sh
# Wire guard-file-domain into .claude/settings.json PreToolUse(Write|Edit) — see settings.json.template.
# Then tag TASKS.md lines with @domain: globs and generate the queue:
bash scripts/tasks-sync.sh
```

`guard-file-domain.sh` is a no-op until a durable leaf sets `LEAF_DOMAIN_GLOBS`, so it won't affect
your normal sessions. See `docs/SWARM-ORCHESTRATION.md` for the full Mode 3 flow.

#### Step 6 — Ingest into vault

Create `~/Obsidian/Builds/01-Projects/<project-name>/STATUS.md`:
```markdown
---
type: entity
name: <project-name>
status: ACTIVE-BUILD
last_edited_by: markandey
---
# <project-name>
[What it does]
[Tech stack]
[Kill criteria]
[[Related projects if any]]
```

Create retrospective ADRs for key past decisions:
```markdown
---
number: 0001
title: stack selection
status: accepted
---
# ADR-0001: Stack Selection
Context: [why this stack was chosen]
Decision: [what was chosen]
...
```

These are your institutional memory. Even if the decisions were made months ago, capturing them now means future you (or Claude) won't re-derive them from scratch.

---

### VALIDATE: Partial Retrofit (~45 minutes)

1. **CLAUDE.md** — critical, write it (≤200 lines)
2. **CONTEXT.md** — write the glossary
3. **Vault entry** — `STATUS.md` in `01-Projects/`
4. **security-architect** agent only
5. **check-secrets-staged.sh** hook only
6. **ADRs** — at minimum, one ADR for the stack choice and one for the auth model

Skip the full command set for now. Add when you start building features again.

---

### STABILIZE: Minimal Retrofit (~20 minutes)

1. **Vault entry** with status, stack, kill criteria
2. **check-secrets-staged.sh** hook (prevents future credential leaks)
3. **Brief CLAUDE.md** (~50 lines) — just the critical conventions

No agents, no full command set needed.

---

### KEEP-AS-IS: Vault Entry Only (5 minutes)

Just the vault note:
```markdown
---
type: entity
name: <project-name>
status: KEEP-AS-IS
---
# <project-name>
[What it does, one paragraph]
[Why it's keep-as-is]
[Last touched: date]
```

---

## Retrofitting the AI Routing Pattern

If your existing app calls Claude/OpenAI directly, retrofit the routing pattern:

**Before (costly and brittle):**
```typescript
const response = await anthropic.messages.create({
  model: "claude-sonnet-4-6",
  messages: [{ role: "user", content: userMessage }]
})
```

**After (routed and cost-optimized):**
```typescript
const complexity = classifyQuery(userMessage)  // "COMPLEX" | "SIMPLE"
if (complexity === "SIMPLE") {
  // Route to local Qwen via Ollama
  return await ollamaClient.generate({ model: "qwen2.5-coder:14b", prompt: userMessage })
} else {
  // Route to Claude for complex analysis
  return await agentFarm.execute(TEMPLATE_COMPLEX, userMessage)
}
```

Add the classification keywords from `docs/AI-ROUTING.md`. The 85% cost reduction is the fastest payoff in this entire setup.

---

## Two-Stack Reality

If you're running two stacks (e.g., legacy Java + greenfield Next.js), follow these rules:

1. **Do NOT rewrite** a working legacy app just to "consolidate stacks" — that's stack-hopping in disguise
2. **Do NOT share library code** across stacks — it creates coupling that's worse than the duplication
3. **DO** define contracts at the boundary: HTTP/SSE/MCP, never shared libraries
4. **DO** route new apps to greenfield unless there's an explicit ADR reasoning

The two-stack regime stays as long as: legacy still ships value AND rewrite cost > 30 days AND no security forcing function.

---

## Common Mistakes When Retrofitting

**CLAUDE.md > 200 lines** — You tried to document everything. Cut it to conventions + non-negotiables only.

**Adding all 11 agents** — You don't need the domain-expert agent if your project has no regulated domain. Start with 3: security-architect, solution-architect, product-manager.

**Retrospective ADRs for trivial decisions** — Apply the 3-test threshold. Not everything needs an ADR. Target 5-10 total per project.

**Installing all 9 commands** — You don't need `/start-phase-team` for a solo maintenance-mode project. Install what you'll actually use.

**Not creating CONTEXT.md** — This is the highest-value addition for existing projects. The glossary catches term drift that costs hours of "wait, what did you mean by X?" conversations.

---

*See also: `PLAYBOOK.md` Part B for the full Project Consolidation Procedure, `docs/NEW-PROJECT.md` for greenfield setup.*
