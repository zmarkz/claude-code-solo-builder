---
description: Sync or scaffold the current project into the claude-code-solo-builder setup. Detects whether this is a new project, an existing project needing a retrofit, or an existing project that just needs its agents updated. Run this from any project directory.
---

You are wiring up the current project into the claude-code-solo-builder setup. Work from the current working directory.

---

## Step 1 — Probe the directory

Run these checks silently before asking anything:

```bash
# Count files at root
ls -la

# Check for source code indicators
ls package.json pom.xml go.mod pyproject.toml Cargo.toml 2>/dev/null

# Check for existing setup
ls .claude/agents/*.md 2>/dev/null
ls CLAUDE.md CONTEXT.md ARCHITECTURE.md ROADMAP.md 2>/dev/null
```

Classify the project into one of three modes:

- **NEW** — directory has ≤3 files, no source code markers (package.json, pom.xml, go.mod, pyproject.toml, Cargo.toml), no `.claude/`, no planning docs. This is a greenfield project.
- **SYNC** — directory has `.claude/agents/*.md` already. Agents exist; they need refreshing from the user-level store.
- **RETROFIT** — directory has source code OR existing planning docs but is missing `.claude/agents/` OR is missing ≥2 of the four planning docs (CLAUDE.md, CONTEXT.md, ARCHITECTURE.md, ROADMAP.md). This is an existing project that hasn't been fully wired up.

---

## Step 2 — Confirm with the user

Present your finding in one line, then ask for confirmation or an override:

> Detected: **[NEW / SYNC / RETROFIT]** — project `<basename of cwd>`.
> Action: [one-sentence description of what will happen].
> Proceed, or override? (`new` / `sync` / `retrofit`)

Wait for their reply before continuing.

---

## Step 3a — NEW path

Say: "Handing off to `/ai-project-scaffold`…"

Invoke the `ai-project-scaffold` skill. It handles everything from here (interviews, planning docs, agents, commands, hooks, settings). Do not continue with any further steps — the scaffold skill owns the rest of this session.

---

## Step 3b — SYNC path

The project already has agents. Refresh them from the user-level store and optionally sync commands.

**3b-1. Sync agents**

```bash
mkdir -p .claude/agents
cp ~/.claude/agents/*.md .claude/agents/
```

List the agents that were copied.

**3b-2. Offer command sync**

Ask: "Also sync commands from `~/.claude/commands/`? (`all` / list specific names / `no`)"

- `all` → `mkdir -p .claude/commands && cp ~/.claude/commands/*.md .claude/commands/`
- Specific names → copy only those files
- `no` → skip

**3b-3. Offer domain-expert fill-in**

Ask: "Run `/write-an-agent` to fill in `domain-expert.md` for this project's domain? (`yes` / `skip`)"

If yes, invoke `/write-an-agent`.

Go to Step 4.

---

## Step 3c — RETROFIT path

The project has code but is missing setup. Apply the correct subset based on project status.

**3c-1. Ask the project bucket**

> "What is this project's current status?
> - `active-build` — actively building features (full retrofit ~2-3 hours)
> - `validate` — shipped MVP, checking product-market fit (partial retrofit ~45 min)
> - `stabilize` — has real users, maintenance mode (minimal ~20 min)
> - `keep-as-is` — low priority, personal tool, legacy (vault entry only ~5 min)"

Wait for their answer, then apply the matching procedure below.

---

### active-build — full retrofit

```bash
mkdir -p .claude/agents .claude/commands scripts docs/adr
```

**Agents — all 11:**
```bash
cp ~/.claude/agents/*.md .claude/agents/
```

**Commands — 5 core:**
```bash
cp ~/.claude/commands/start-session.md .claude/commands/
cp ~/.claude/commands/plan-feature.md .claude/commands/
cp ~/.claude/commands/build-feature.md .claude/commands/
cp ~/.claude/commands/review-security.md .claude/commands/
cp ~/.claude/commands/phase-review.md .claude/commands/
```

**Hooks — 2 core:**
```bash
cp ~/.claude/skills/ai-project-scaffold/reference/scripts/check-secrets-staged.sh scripts/
cp ~/.claude/skills/ai-project-scaffold/reference/scripts/session-snapshot.sh scripts/
chmod +x scripts/*.sh
```

**Planning docs — scaffold stubs for any that are missing:**

For each missing doc, create a stub (do not overwrite existing files):

`CLAUDE.md` (if missing):
```markdown
# <project-name>

## What this is
[One paragraph — purpose, users, core value]

## Stack
[Your actual stack — be specific]

## Key conventions
[Naming patterns, auth pattern, DB pattern]

## Never do
[Project-specific non-negotiables]

## Test commands
[How to run tests locally]

## Current phase
Phase 1 — [goal]
```

`CONTEXT.md` (if missing):
```markdown
# <project-name> — Ubiquitous Language

## Language
**<Term>**: <precise definition>
*Avoid*: <synonyms that cause confusion>

## Relationships
- A **<Entity>** has many **<Entity>**.

## Flagged ambiguities
[None yet — add when terms collide]
```

`ARCHITECTURE.md` (if missing):
```markdown
# <project-name> — Architecture

## Overview
[One paragraph describing the system]

## Components
[List services, DBs, queues with one-line descriptions]

## Data flow
[How a request flows through the system]

## Key decisions
[Link to docs/adr/]
```

`ROADMAP.md` (if missing):
```markdown
# <project-name> — Roadmap

## Phase 1 — [Goal]
**Exit criteria:**
- [ ] ...

**Tasks:** see TASKS.md

## Phase 2 — [Goal]
[TBD]
```

Then run `/vault-update` to create the vault INDEX.md entry.

Then ask: "Run `/write-an-agent` to fill in `domain-expert.md` for this project's domain? (`yes` / `skip`)"

---

### validate — partial retrofit

**Agents — 3:**
```bash
mkdir -p .claude/agents
cp ~/.claude/agents/security-architect.md .claude/agents/
cp ~/.claude/agents/solution-architect.md .claude/agents/
cp ~/.claude/agents/product-manager.md .claude/agents/
```

**Commands — 2:**
```bash
mkdir -p .claude/commands
cp ~/.claude/commands/start-session.md .claude/commands/
cp ~/.claude/commands/review-security.md .claude/commands/
```

**Hooks — 1:**
```bash
mkdir -p scripts
cp ~/.claude/skills/ai-project-scaffold/reference/scripts/check-secrets-staged.sh scripts/
chmod +x scripts/check-secrets-staged.sh
```

Scaffold `CLAUDE.md` and `CONTEXT.md` stubs if missing (same templates as above).

Run `/vault-update` (status: VALIDATE).

---

### stabilize — minimal retrofit

**Agent — 1:**
```bash
mkdir -p .claude/agents
cp ~/.claude/agents/security-architect.md .claude/agents/
```

**Hook — 1:**
```bash
mkdir -p scripts
cp ~/.claude/skills/ai-project-scaffold/reference/scripts/check-secrets-staged.sh scripts/
chmod +x scripts/check-secrets-staged.sh
```

Scaffold a brief `CLAUDE.md` (~50 lines) if missing:
```markdown
# <project-name>

## What this is
[One paragraph]

## Stack
[Actual stack]

## Never do
[Critical non-negotiables only]

## Status
STABILIZE — maintenance mode. No new features without an ADR.
```

Run `/vault-update` (status: STABILIZE).

---

### keep-as-is — vault only

Run `/vault-update` with status: KEEP-AS-IS. Nothing else is installed.

---

## Step 4 — Summary report

Always end with this report block:

```
## sync-project complete

Project:   <basename of cwd>
Mode:      <new | sync | retrofit>
Bucket:    <active-build | validate | stabilize | keep-as-is | n/a>

Agents installed:        <N> — <names>
Commands installed:      <list or "none">
Hooks installed:         <list or "none">
Planning docs created:   <list or "none">
Vault:                   <created | updated | skipped>

Next: <one recommended next step>
```

Recommended "Next" by mode:
- **new** → "Answer the scaffold questions to generate your planning docs."
- **sync** → "Run `/start-session` to reload context."
- **retrofit / active-build** → "Fill in the stubs: CLAUDE.md first, then CONTEXT.md."
- **retrofit / validate** → "Run `/review-security` on the existing codebase."
- **retrofit / stabilize** → "Verify the pre-commit hook fires: `git commit --allow-empty -m 'test hook'`."
- **retrofit / keep-as-is** → "Vault entry created. No further action needed."
