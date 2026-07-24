# Claude Code Solo Builder — Complete Setup & Playbook

> An operating system for solo developers building a multi-app portfolio with AI agents.
> Token-efficient, vault-grounded, security-first, and compounding over time.

**Version 3.2 — July 2026**

> **What's new** · **v3.2** — "Opus at the gates" model retune (Opus runs only on gate lanes; near-Opus Sonnet 5 takes synthesis / proposal / discovery) + Mode-3 substrate re-scope + mattpocock skills migrated to the plugin marketplace. · **v3.1** — per-project local RAG (LEANN) + cross-project module reuse. · **v3.0** — public/private overlay split (fully generic, portable kit). Full rationale in `docs/adr/INDEX.md`.

---

## What is this?

This repository is the **complete, shareable setup** that lets a solo developer run like a 10-person team using Claude Code. It includes:

- **The Playbook** — a 13-part operating manual covering mental model, AI swarm patterns, knowledge vault, portfolio management, and daily cadences
- **The Starter Kit** — a Claude Code skill that scaffolds any new project with 11 agents, 22 slash commands, 7 workflow recipes, 10 guardrail scripts, and all planning docs in ~10 minutes
- **Local RAG + module reuse** — per-project LEANN semantic index built at init (one retrieval call instead of grep loops), plus a cross-project pattern library so modules get reused, not rewritten — see `docs/LOCAL-RAG.md`
- **The Knowledge Stack (optional module)** — Obsidian vault + Context7 + knowledge-graph MCP working together to ground every AI call in your prior decisions (see `docs/VAULT.md`)
- **Token Efficiency Guide** — how to get 85%+ cost savings through model routing, context management, and vault-first queries
- **Settings & Agents** — production-grade Claude Code settings, 11 specialist subagents, 22 slash commands, 7 profile-aware workflow recipes, and guardrail scripts
- **Comparison with mattpocock/skills** — the best-of-both hybrid workflow

## The Core Insight

> Code generation is no longer the bottleneck. The real limits are: picking what to build, specifying clearly, reviewing and deciding, distribution, and operations. Optimize for *those*, not raw code throughput.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  PORTFOLIO LAYER                                            │
│  What to build, kill, double down on                        │
│  → You + one strategist agent                               │
├─────────────────────────────────────────────────────────────┤
│  BUILD LAYER                                                │
│  Code generation, testing, deployment                       │
│  → Claude Code swarm (mostly AI, you approve PRs)           │
├─────────────────────────────────────────────────────────────┤
│  KNOWLEDGE LAYER                                            │
│  Central Obsidian vault — PRDs, ADRs, postmortems,          │
│  patterns, customer research, build logs                    │
│  → Karpathy LLM Wiki pattern + Context7 for fresh docs      │
├─────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                             │
│  Templates, skills, observability, deploy infra             │
│  → Built once, used by every app (the compounding asset)    │
└─────────────────────────────────────────────────────────────┘
```

**Platform** makes each new app cheaper. **Knowledge** makes each new app smarter. Most solo builders skip both — that gap is the moat.

---

## Quick Start

Three steps to a working setup.

### Prerequisites
- [Claude Code](https://claude.ai/code) installed
- `gh` CLI authenticated (`gh auth login`)
- `node` 22+, `pnpm`, `git`

### Step 1 — Clone this repo
```bash
git clone https://github.com/zmarkz/claude-code-solo-builder.git
cd claude-code-solo-builder
```

### Step 2 — Install into your live Claude Code setup (`~/.claude`)
```bash
make install     # idempotent — safe to re-run after every `git pull`
```
This syncs the scaffold skill, all 11 agents, 22 commands, 7 workflow recipes, and the two generic
hook scripts into `~/.claude` (`agents/`, `commands/`, `workflows/`, `skills/`, and
`~/.claude/scripts/`). It deliberately does **not** touch your `~/.claude/settings.json` or
`~/.claude/CLAUDE.md` — those stay yours. Run `make check` any time for a read-only, content-based
drift report.

> **First run:** also copy the settings and standing-instructions templates —
> `settings/settings.json.template`, `settings/CLAUDE.md.template`, and (optional)
> `settings/solo-builder.config.template`. `make install` never touches your live settings; the full
> walkthrough is in `docs/INSTALL.md`.

### Step 3 — Wire up any project (new or existing)

In any project directory, launch Claude Code and run:

```
> /sync-project          # existing project → retrofit, or update agents to latest
> /ai-project-scaffold   # empty dir → scaffold a new project from scratch
```

`/sync-project` is the single entry point: it probes the directory, classifies the scenario (new /
retrofit / update), confirms with one question, and executes the right steps — delegating to
`/ai-project-scaffold` when the directory is empty. See `docs/NEW-PROJECT.md` and
`docs/EXISTING-PROJECT.md` for what each path does.

---

## Optional modules

The core setup above is fully self-contained. These modules are opt-in — turn on the ones you want.

- **Vault / knowledge layer** — ground every AI call in your prior decisions (Obsidian vault +
  Context7 + optional knowledge-graph). Dormant until enabled: set `VAULT_PATH` in
  `~/.claude/solo-builder.config` (template at `settings/solo-builder.config.template`). Guide:
  `docs/VAULT.md`.
- **Third-party skill suites** — gstack (~30 shipping / QA / review / SEO skills) and
  mattpocock/skills (atomic daily-workflow session skills, installed via the Claude Code
  plugin marketplace — `mattpocock-skills@mattpocock`). Install only what you use. Guide:
  `docs/SKILLS-ECOSYSTEM.md`.
- **Local-model routing** — send simple AI calls to a free local model (e.g. Qwen via Ollama) and
  reserve Claude for complex work. A recommended generic pattern, written up in `PLAYBOOK.md` §3.10.

---

## What's Inside

```
claude-code-solo-builder/
├── README.md                         ← You are here
├── PLAYBOOK.md                       ← The full 13-part operating manual
├── install.sh                        ← Propagate repo → ~/.claude (run after every git pull)
├── Makefile                          ← make install (sync) · make check (drift report)
├── scripts/                          ← Generic hook scripts → installed to ~/.claude/scripts/
│   ├── vault-session-check.sh        ← SessionStart hook: vault freshness (dormant until VAULT_PATH set)
│   └── solo-builder-session-check.sh ← SessionStart hook: repo → ~/.claude drift reminder
├── docs/
│   ├── INSTALL.md                    ← Detailed installation guide (start here)
│   ├── BEST-PRACTICES.md             ← Daily operating discipline (propagation, profiles, recipes)
│   ├── VAULT.md                      ← Optional vault/knowledge module (Obsidian + Context7 + kg)
│   ├── TOKEN-EFFICIENCY.md           ← 85%+ cost savings strategies
│   ├── NEW-PROJECT.md                ← How to scaffold a new project
│   ├── EXISTING-PROJECT.md           ← Retrofitting existing projects
│   ├── AGENTS-GUIDE.md               ← The 11 specialist agents explained
│   ├── SKILLS-ECOSYSTEM.md           ← Skills: gstack + mattpocock + custom
│   ├── SWARM-ORCHESTRATION.md        ← 3 parallelism modes + the saved recipe library, durability + domain enforcement
│   ├── SETTINGS-AND-THEMES.md        ← Claude Code config, dark theme, hooks
│   ├── COMPARISON-mattpocock.md      ← Best-of-both hybrid analysis
│   ├── COMPARISON-karpathy.md        ← Karpathy CLAUDE.md benchmark + what we adopted
│   └── adr/                          ← ADRs 0001–0006 (workflow substrate · recipe library · public/private split · local RAG · Opus-at-the-gates · Mode-3 re-scope)
├── starter-kit/                      ← The ai-project-scaffold skill
│   ├── SKILL.md                      ← Skill specification (invoke with /ai-project-scaffold)
│   ├── CHANGELOG.md                  ← Version history
│   ├── examples/                     ← Template files for generated docs
│   └── reference/
│       ├── agents/                   ← 11 specialist subagent definitions (incl. upgraded frontend-engineer)
│       ├── commands/                 ← 22 slash commands (incl. /design-feature, /mode, /review-exhaustive)
│       ├── workflows/                ← 7 profile-aware Workflow() recipes (incl. fast-dag-build, exhaustive-review)
│       ├── scripts/                  ← 10 guardrail hook scripts (incl. design-lint.sh)
│       └── settings.json.template    ← Per-project Claude Code settings (all guardrails wired)
├── skills/
│   └── sync-skills/                  ← /sync-skills command (install to ~/.claude/skills/sync-skills/)
│       ├── SKILL.md                  ← Skill workflow: auto-discover + sync all third-party sources
│       └── sources.json              ← Registry of tracked sources (gstack, mattpocock, Karpathy, MCPs)
└── settings/
    ├── settings.json.template        ← Claude Code settings with hooks wired
    ├── settings.local.json.template  ← Per-machine permission allowlist template
    ├── CLAUDE.md.template            ← Personal L1 standing instructions template
    └── solo-builder.config.template  ← Optional module config (VAULT_PATH, VAULT_REINDEX_CMD)
```

---

## The Daily Workflow

```bash
# Launch Claude Code
claude

# First time in a project (or to update agents)
> /sync-project                       # detect + scaffold / retrofit / sync in one command

# Start every session
> /start-session                      # re-loads CLAUDE.md + active phase + vault freshness check

# Before every change
> /grill-with-docs <vague idea>       # sharpens CONTEXT.md, avoids misalignment

# Plan a feature
> /plan-feature <name>                # PM + architect + security spec
                                      # (auto: checks DESIGN.md, runs /plan-design-review for UI)

# Build it
> /build-feature <slug>              # vertical-slice TDD
                                      # (auto: frontend-design brief + /design-review exit gate for UI)

# Build UI specifically — full design-first cycle
> /design-consultation               # ONCE per project — establishes DESIGN.md
> /design-feature <name>             # design→build→review in one command (replaces /build-feature for UI)

# When something breaks
> /diagnose                          # structured debug: reproduce → minimize → fix

# End of session
> /vault-update                      # (vault module) write/update vault INDEX.md + trigger re-index
> /handoff                           # human-readable doc for tomorrow

# Weekly
> /improve-codebase-architecture     # catch drift before it becomes a rewrite

# Monthly
> /sync-skills                       # pull latest gstack, mattpocock, Karpathy — apply best changes

# End of phase
> /phase-review N                    # product-owner review + human sign-off
```

---

## Workflow Recipes (parallel, profile-aware)

Saved `Workflow()` recipes in `.claude/workflows/` fan work across many agents for jobs too big for one context — committed and shipped with every project (propagated like agents and commands). Each auto-registers as a `/<name>` slash command and is **profile-aware**: pass `args.mode` = `best` (default — max quality + speed) or `saver` (token-optimised), or flip the whole session with `/mode best|saver`.

| Recipe | `/command` | Quality pattern | Use for |
|--------|-----------|-----------------|---------|
| `exhaustive-review` | `/review-exhaustive` | diverse lenses + adversarial verify | deep multi-lens review of the current diff |
| `codebase-map` | `/map-codebase` | multi-modal sweep + completeness critic | understand an unfamiliar repo |
| `security-sweep` | `/audit-security` | loop-until-dry + adversarial verify | whole-repo security audit |
| `design-panel` | *(by name)* | judge panel | choose between design approaches → ADR draft |
| `safe-migration` | *(by name)* | worktree-isolated transform → verify | one big codemod (never self-merges) |
| `release-readiness` | *(by name)* | parallel lenses + completeness critic | pre-release go/no-go gate |
| `fast-dag-build` | *(by name)* | DAG fan-out + self-verify + review lane | build a multi-domain feature, quality-first |

**"Opus at the gates" (v3.2):** on Max plans the binding constraint is the weekly Opus cap, not token cost — so even Best runs Opus only on *gate* lanes (security lenses, integration reviewer, go/no-go, final verdict) and routes synthesis / proposal / discovery lanes to near-Opus Sonnet 5. See `docs/adr/0005-opus-at-the-gates-model-retune.md`, `starter-kit/reference/workflows/README.md`, and `docs/SWARM-ORCHESTRATION.md`.

---

## Token Efficiency at a Glance

| Strategy | Savings |
|----------|---------|
| COMPLEX → Claude, SIMPLE → local Qwen | 85-93% of calls are free |
| CLAUDE.md ≤200 lines | Load cost capped every session |
| Vault-first (kg_search before writing) | Avoids re-explaining past decisions |
| /caveman for long sessions | ~75% token compression |
| Swarms vs monolith sessions | Each worker has isolated small context |
| PreCompact session snapshot | State survives compaction |
| Haiku 4.5 for repetitive tasks | 10-20x cheaper than Sonnet |

See `docs/TOKEN-EFFICIENCY.md` for the complete strategy.

---

## Three Operating Principles

1. **Same stack discipline.** Pick one stack and refuse to deviate until you have PMF.
2. **Killable apps.** Every app must be cheap to start *and cheap to kill*. Pre-commit to kill criteria.
3. **Compounding knowledge.** Every app makes the next one faster. By app five, half of the new app is already written.

---

## The Hybrid Approach

This playbook merges two approaches:
- **Ours** — project scaffold (one-time per project) with 11 specialized agents, phase gates, security posture
- **Matt Pocock's skills** — atomic daily workflow skills (grill-with-docs, diagnosing-bugs, handoff, etc.), installed as a plugin (`mattpocock-skills@mattpocock`)

Neither approach alone is sufficient. The details are in `docs/COMPARISON-mattpocock.md`.

---

## Who This Is For

- Solo developers or small teams (1-3 people) building multiple apps
- Builders who want AI to do most of the implementation while they keep decision-making control
- Anyone who has experienced context bloat, token waste, or AI-generated messes
- Developers shipping B2B SaaS, fintech, or any product where security matters

## Who This Is NOT For

- Teams with dedicated PMs, architects, and QA engineers (you already have the humans)
- Pure prototypers or vibe coders (too much structure)
- Single-app, single-session, throw-it-away projects (use `/prototype` instead)

---

## Contributing

This is a living document. The refinement loop is in Part D of the playbook:
- When something doesn't work, document the failure in `04-Archive/`
- When something works surprisingly well, extract it as a pattern in `05-Patterns/`
- Cut a PR with the updated playbook section + an ADR

---

## License

MIT — use freely, adapt to your context, share improvements.

---

*Built by [Markandey Singh](https://markandey.in) with Claude as co-author. v3.2, July 2026.*
