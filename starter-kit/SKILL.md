---
name: ai-project-scaffold
description: Use when starting a new software project that will be built with Claude Code. Generates a complete project scaffold — planning docs (CLAUDE.md, PROJECT_CONTEXT.md, ARCHITECTURE.md, ROADMAP.md, SECURITY_MODEL.md, TASKS.md, DECISIONS.md, README.md, HANDOFF.md), `.claude/` config with permissions/hooks/11-subagent team/9 slash commands, monorepo skeleton, Makefile, docker-compose, pre-commit hooks, and 6 guardrail scripts. Establishes phase-gated, vertical-slice, test-mandatory development with human review checkpoints. Invoke when the user says "start a new project," "scaffold a project," "bootstrap with Claude Code best practices," or when the working directory is empty / near-empty and they describe a build.
---

# AI Project Scaffold — Skill

You are bootstrapping a new software project that will be built largely by Claude Code agents. The goal is to set the project up so that future sessions stay disciplined, reviewable, and safe — without you having to re-invent the structure every time.

This skill bundles **reusable infrastructure** (agent definitions, slash commands, hook scripts, settings template) under `reference/` and **patterns** that you (Claude Code) apply to generate the project-specific planning docs.

## When NOT to use this skill

- The working directory already has substantial code (don't overwrite).
- The user wants a quick prototype or one-off script (overkill).
- The user has explicitly asked you to skip the planning docs / agents / hooks.

In any of those cases, stop and confirm with the user before proceeding.

## Procedure

Follow these steps in order. Don't skip them.

### Step 1 — Sanity check the working directory

Confirm the target directory is empty or near-empty. If there are existing files, list them and ask the user whether to (a) abort, (b) scaffold alongside, or (c) scaffold into a subdirectory. Do not overwrite existing files.

### Step 2 — Ask the user for the project profile

Use `AskUserQuestion` (or equivalent) to gather these answers. Don't proceed until you have them:

1. **Project name** (one short string; used in CLAUDE.md and READMEs).
2. **One-line product description** (the "what is this" sentence).
3. **Primary users / personas** (free text — who will use it).
4. **Tech stack profile.** Pick one or describe a custom mix:
   - `python-fullstack` — FastAPI + Next.js + Postgres
   - `node-fullstack` — Next.js + Node/Express + Postgres
   - `python-api-only` — FastAPI + Postgres (no frontend)
   - `node-api-only` — Express/Hono + Postgres
   - `data-pipeline` — Python + Airflow/Dagster + warehouse
   - `cli-tool` — Python or Go CLI
   - `library` — published package, no service runtime
   - `ai-rag` — FastAPI + Next.js + Postgres+pgvector + Ollama/vLLM
   - `custom` — user describes
5. **Number of phases** (default: 4-7; help the user split scope into phases of 5-10 days each).
6. **Security profile.** Pick one:
   - `production-grade` — full security model, RBAC, audit log, secret rotation
   - `internal-tool` — auth + RBAC, lighter audit
   - `personal-project` — minimal, just secret-scan + pre-commit
7. **Regulatory / compliance involvement?** (y/n) If yes, list which frameworks (GDPR, HIPAA, SOC 2, ISO 27001, PCI DSS, RBI, etc.) — drives whether to scaffold `compliance/frameworks/`.
8. **Multi-tenant or single-tenant?** (drives whether `tenant_id` is in every table from day one).
9. **AI / LLM in the product?** (y/n) If yes, ask: local-only (Ollama/vLLM), hosted-only (Claude/OpenAI), or hybrid. Drives whether to scaffold `ai/` and the model adapter pattern.
10. **Deployment target** (Docker Compose / AWS / GCP / Azure / Vercel / Render / self-hosted).
11. **Phase 1 task list** — ask the user to enumerate the 5-10 tasks that complete Phase 1, or describe Phase 1's goal and let you propose tasks they can review.

Record the answers in a temporary scratch note; you'll embed them into the generated docs.

### Step 3 — Copy the reusable infrastructure verbatim

Copy these from this skill's `reference/` directory into the target project, with no per-project edits:

| Source | Destination |
|--------|-------------|
| `reference/agents/*.md` (11 files) | `<project>/.claude/agents/` |
| `reference/commands/*.md` (9 files) | `<project>/.claude/commands/` |
| `reference/scripts/*.sh` (6 files) | `<project>/scripts/` |
| `reference/settings.json.template` | `<project>/.claude/settings.json` |
| `reference/.gitignore.template` | `<project>/.gitignore` |
| `reference/.editorconfig.template` | `<project>/.editorconfig` |
| `reference/.env.example.template` | `<project>/.env.example` |

Then, customize `.claude/settings.json` based on the user's answers (delete the `ai-engineer` agent reference if not an AI project; set env vars appropriate to the deploy target). Make all scripts executable: `chmod +x <project>/scripts/*.sh`.

### Step 4 — Generate the planning docs

Generate each of these files in the project root, following the structure shown in `examples/CLAUDE.md.example` and `examples/ROADMAP.md.example`. Embed the user's answers from Step 2.

| File | Purpose | Hard cap |
|------|---------|----------|
| `CLAUDE.md` | Session-start preamble: rules, conventions, hard limits, current phase. | ≤200 lines (CRITICAL — gets loaded every session) |
| `PROJECT_CONTEXT.md` | The "why" — personas, market, non-goals, risks, operating principles. | ~200 lines |
| `CONTEXT.md` | **NEW (v1.1).** DDD-style ubiquitous-language glossary: canonical terms, "avoid" synonyms, entity relationships, flagged ambiguities. Distinct from `PROJECT_CONTEXT.md`. Use `examples/CONTEXT.md.example`. | ~150 lines, grows lazily |
| `ARCHITECTURE.md` | System-level design, data model summary, security architecture summary, deployment topology. | ~250 lines |
| `ROADMAP.md` | Phases 0..N with goal + deliverables + exit criteria. Phase 0 = "this scaffold." | ~200 lines |
| `SECURITY_MODEL.md` | Threat model: what to protect, trust boundaries, authN, authZ, secrets, audit, network. Skip if security profile = `personal-project`. | ~250 lines |
| `TASKS.md` | Live task list, organized by phase, with `[ ]` / `[~]` / `[x]` / `[!]` markers. | unbounded |
| `docs/adr/0000-template.md` + `docs/adr/INDEX.md` | **CHANGED in v1.1.** Per-file ADRs (one file per decision, monotonic numbering, never reused). Replaces the v1.0 single `DECISIONS.md`. Use `examples/ADR-NNNN-template.md.example`. Apply the 3-test ADR threshold: hard-to-reverse + surprising-without-context + result-of-real-trade-off. | one file per ADR, unbounded |
| `README.md` | Quick start, repo map, useful commands. | ~150 lines |
| `HANDOFF.md` | Step-by-step "what to do next" for the first Claude Code session. | ~200 lines |

For AI / regulated projects, ALSO generate:
- `compliance/frameworks/README.md` with placeholders for each chosen framework.
- `ai/README.md` describing the RAG pipeline / model adapter layout.

### Step 5 — Generate the monorepo skeleton

Based on the tech stack profile, create these directories with a brief README in each describing what goes there:

- `apps/{api,web}/` for fullstack profiles; only `apps/api/` for api-only; etc.
- `packages/shared/` for any monorepo profile that needs shared schemas.
- `ai/{prompts,evals,rag,models}/` only for `ai-rag` or AI-involved projects.
- `infra/{docker,terraform,k8s}/` for any deployable service.
- `compliance/frameworks/` only if regulated.
- `docs/{product,architecture,security,engineering,sales,phase-reviews,security-reviews,qa-reports,specs,session-snapshots}/` always.
- `tests/{fixtures,integration,security,e2e}/` always.

### Step 6 — Generate the toolchain files

- `Makefile` — targets for `setup`, `dev`, `test`, `lint`, `typecheck`, `security`, `quality`, `down`, `clean`, `help`. Stack-specific commands inside each target.
- `docker-compose.yml` — Postgres + Redis + (Ollama if AI) + (MinIO if files) bound to 127.0.0.1. App/worker/web services commented out until Phase 1 builds their Dockerfiles.
- `.pre-commit-config.yaml` — gitleaks, pre-commit-hooks hygiene, language-specific linters, and the custom scripts in `scripts/`.

### Step 7 — Verify the scaffold

Run a verification pass:

1. `python3 -c "import json; json.load(open('.claude/settings.json'))"` — must succeed.
2. `for f in scripts/*.sh; do bash -n "$f" || echo FAIL: $f; done` — no FAILs.
3. `for f in .claude/agents/*.md; do head -5 "$f" | grep -q "^name:" || echo "no frontmatter: $f"; done` — no output.
4. `wc -l CLAUDE.md` — must be ≤ 200.
5. **(v1.1)** `test -f CONTEXT.md` — must exist (DDD glossary).
6. **(v1.1)** `test -d docs/adr && test -f docs/adr/INDEX.md` — must exist (per-file ADR layout, replaces `DECISIONS.md`).

If any check fails, fix it before reporting completion.

### Step 8 — Report and hand off

Print a summary:

- File count by category (planning docs, agents, commands, scripts, infra).
- Total directories created.
- The first 5 commands the user should run (`chmod +x scripts/*.sh`, `git init`, `git commit`, `claude`, `/start-session`).
- Where the scaffold's HANDOFF.md is (with the full installation steps).
- Any user-input questions deferred to `docs/open-questions.md`.

## Core patterns this skill enforces

These are the load-bearing patterns. Generate planning docs and agents that reflect them:

### Pattern 1 — Phase gates with human checkpoints

Every phase ends with `/phase-review N`. The `product-owner-reviewer` agent (in `reference/agents/`) produces a one-page exec summary at `docs/phase-reviews/phase-N.md`. The human signs by editing the markdown. No autopilot can self-approve a phase.

### Pattern 2 — Vertical slices, not horizontal layers

A feature is end-to-end: schema → API → worker → UI → test → docs. The `build-feature` slash command enforces this order. Never ship a half-built layer.

### Pattern 3 — Tests are mandatory

No new code without tests. Pre-commit, CI, and the `/run-qa` command all enforce this. There are no "throwaway" tests.

### Pattern 4 — ADR every non-trivial decision

`DECISIONS.md` captures every architectural choice in a fixed template (Context / Decision / Alternatives / Trade-offs / Reversibility). The `solution-architect` agent's job description includes writing these.

### Pattern 5 — Subagent definitions are reusable as agent-team members

The 11 subagents in `reference/agents/` work two ways:
1. As subagents inside a session (the main agent spawns them via the Task tool).
2. As agent-team teammates (referenced by `name` when spawning a team via `/start-phase-team`).

Per Claude Code docs, only `tools`, `model`, and the body are honored when used as team teammates — not `skills` or `mcpServers` frontmatter. Don't put skill or MCP refs in agent frontmatter.

### Pattern 6 — Hooks for safety, not for cleverness

The 6 scripts wire to SessionStart, PreToolUse (Bash, Write, Edit), PostToolUse (Write, Edit), and PreCompact hooks. Their purpose is to fail loudly and early. Don't make them do anything fancy; clarity beats elegance.

### Pattern 7 — Context-window management is part of the structure

- `CLAUDE.md` is the ≤200-line preamble loaded every session.
- `/start-session` re-loads the active phase + tasks at session start.
- `PreCompact` hook → `session-snapshot.sh` dumps state to `docs/session-snapshots/` before compaction.
- Together these let "continuous Claude Code engagement" survive multi-week timelines.

### Pattern 8 — Two parallelism modes, both bounded

- `/build-phase-autopilot` runs plan→build→commit for the listed Phase 1 slugs sequentially, single-session. Skips spec-approval and per-commit review; **does NOT skip phase review**.
- `/start-phase-team` launches an agent team (experimental Claude Code feature, requires v2.1.32+) of 3-5 teammates working in parallel across non-overlapping file domains. Higher token cost; faster wall-clock time.

Both have allowlists that refuse to run outside Phase 1 by default. To extend to other phases, the user adds an explicit ADR.

## Pitfalls to avoid

1. **Don't overwrite existing files.** If the user already has a `CLAUDE.md` or `README.md`, ask before replacing.
2. **Don't generate generic boilerplate planning docs.** Embed the user's actual project name, personas, and Phase 1 tasks. Generic docs are worse than no docs.
3. **Don't add a `.claude/skills/` directory in the new project pointing back to this skill.** This skill is at user-level; projects inherit it via Claude Code's skill discovery, not via embedded reference.
4. **Don't pre-author `.claude/teams/`.** Per the Claude Code docs, team config is generated automatically at runtime; pre-authoring it breaks the experimental feature.
5. **Don't include `skills` or `mcpServers` in any subagent frontmatter.** Per the docs, those fields aren't applied when the subagent is used as an agent team teammate.
6. **Don't make CLAUDE.md > 200 lines.** It gets loaded every session; extra lines cost real tokens forever.

## After the scaffold runs

The user starts the project with:

```bash
chmod +x scripts/*.sh
git init -b main
git add . && git commit -m "chore: phase 0 scaffold"
pre-commit install     # if pre-commit is available
claude                 # then: /start-session
```

From there, normal Claude Code workflow: `/plan-feature <slug>` (Step 0 of which is the embedded grilling protocol — see the command file) → human approves spec → `/build-feature <slug>` (which applies TDD tracer-bullet cycles per layer) → human reviews commit. At the end of each phase, `/phase-review N`.

The skill's job ends when the scaffold is on disk and the user knows what to type next.

## Dual-residency: also install components at user level (v1.1)

The scaffold is a **one-shot generator** — improvements to files in `~/.claude/skills/ai-project-scaffold/reference/` do NOT propagate to projects already scaffolded. To get upstream improvements without re-scaffolding, also install the kit's atomic components at user level:

```bash
# Agents at user level — per-project overrides win when both exist
mkdir -p ~/.claude/agents
cp ~/.claude/skills/ai-project-scaffold/reference/agents/*.md ~/.claude/agents/

# Slash commands at user level
mkdir -p ~/.claude/commands
cp ~/.claude/skills/ai-project-scaffold/reference/commands/*.md ~/.claude/commands/
```

Unmodified projects inherit upstream improvements automatically. Projects that have overridden a file in their own `.claude/agents/` or `.claude/commands/` keep their override.

## Complementary atomic skills to install (v1.1)

This kit owns the *project layer* (scaffold once, get discipline). Pair it with **atomic session-layer skills from mattpocock/skills** for daily work:

```bash
npx skills@latest add mattpocock/skills
```

Pick at minimum: `grill-with-docs`, `diagnose`, `zoom-out`, `improve-codebase-architecture`, `handoff`. Optionally `caveman` (token compression) and `prototype` (throwaway exploration before scaffolding for real).

See `COMPARISON-mattpocock-vs-ours.md` in the workspace for why this division is principled, not eclectic.
