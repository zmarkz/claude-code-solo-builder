# Claude Code Solo Builder — Complete Setup & Playbook

> An operating system for solo developers building a multi-app portfolio with AI agents.
> Token-efficient, vault-grounded, security-first, and compounding over time.

**Version 2.4 — June 2026**

---

## What is this?

This repository is the **complete, shareable setup** that lets a solo developer run like a 10-person team using Claude Code. It includes:

- **The Playbook** — a 13-part operating manual covering mental model, AI swarm patterns, knowledge vault, portfolio management, and daily cadences
- **The Starter Kit** — a Claude Code skill that scaffolds any new project with 11 agents, 18 slash commands, 7 workflow recipes, 9 guardrail scripts, and all planning docs in ~10 minutes
- **The Knowledge Stack** — Obsidian vault + Context7 + knowledge-graph MCP working together to ground every AI call in your prior decisions
- **Token Efficiency Guide** — how to get 85%+ cost savings through model routing, context management, and vault-first queries
- **Settings & Agents** — production-grade Claude Code settings, 11 specialist subagents, 18 slash commands, 7 profile-aware workflow recipes, and guardrail scripts
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

## Quick Start (30 minutes to full setup)

### Prerequisites
- [Claude Code](https://claude.ai/code) installed
- [Obsidian](https://obsidian.md/) installed
- `gh` CLI authenticated (`gh auth login`)
- `node` 18+, `pnpm`, `git`

### Step 1 — Clone this repo
```bash
git clone https://github.com/zmarkz/claude-code-solo-builder.git
cd claude-code-solo-builder
```

### Step 2 — Install into your live Claude Code setup (`~/.claude`)
```bash
make install     # idempotent — safe to re-run after every `git pull`
```
This syncs the scaffold skill, all 11 agents, 18 commands, 7 workflow recipes, and the platform
scripts into `~/.claude` (and `~/builds/_platform/scripts`). It deliberately does **not** touch your
`~/.claude/settings.json` or `~/.claude/CLAUDE.md` — those stay yours (Steps 5 and 7). Run
`make check` any time for a read-only, content-based drift report.

### Step 3 — Install gstack
```bash
# gstack is a comprehensive skill ecosystem (~30 skills)
# See docs/SKILLS-ECOSYSTEM.md for the full list
npx skills@latest add gstack  # or follow gstack install docs
```

### Step 4 — Install mattpocock/skills (atomic daily workflow skills)
```bash
npx skills@latest add mattpocock/skills
# Select: grill-with-docs, diagnose, zoom-out, improve-codebase-architecture, handoff, caveman
```

### Step 5 — Configure Claude Code settings
```bash
cp settings/settings.json.template ~/.claude/settings.json
# Edit to customize your notification channel, model preference, etc.
```

### Step 6 — Set up Obsidian vault
Follow `docs/OBSIDIAN-CONTEXT7.md` — takes ~20 minutes. Creates the vault at `~/Obsidian/Builds/`.

### Step 7 — Set up your personal CLAUDE.md
```bash
cp settings/CLAUDE.md.template ~/.claude/CLAUDE.md
# Edit: fill in your stack, your projects, your non-negotiables
```

### Step 8 — Install the `ccc` launcher

`ccc` wraps your normal Claude Code launch command and auto-re-indexes the knowledge-graph when you close the session.

**fish shell:**
```bash
# Copy and edit — replace /YOUR_HOME with your actual home path
cp starter-kit/platform-scripts/ccc.fish ~/.config/fish/functions/ccc.fish
# Edit the file to replace /YOUR_HOME and adjust launch flags
```

**zsh / bash** — add to `~/.zshrc`:
```bash
function ccc() {
  caffeinate -s claude --dangerously-skip-permissions "$@"
  bash /YOUR_HOME/builds/_platform/scripts/kg-reindex.sh
}
```

See `docs/VAULT-AUTOMATION.md` for full details.

### Step 9 — Wire up any project (new or existing)

`/sync-project` is the single entry point for all three cases:

```bash
# New project
mkdir ~/builds/my-app && cd ~/builds/my-app
ccc
> /sync-project          # detects empty dir → delegates to /ai-project-scaffold

# Existing project — no setup yet
cd ~/builds/existing-app
ccc
> /sync-project          # detects code, no .claude/ → retrofit flow, asks bucket

# Existing project — update agents to latest
cd ~/builds/any-app
ccc
> /sync-project          # detects .claude/agents/ → syncs from ~/.claude/agents/
```

It probes the directory, classifies the scenario, confirms with one question, and executes the right steps. See `docs/EXISTING-PROJECT.md` for what each path does.

---

## What's Inside

```
claude-code-solo-builder/
├── README.md                         ← You are here
├── PLAYBOOK.md                       ← The full 13-part operating manual
├── install.sh                        ← Propagate repo → ~/.claude (run after every git pull)
├── Makefile                          ← make install (sync) · make check (drift report)
├── docs/
│   ├── INSTALL.md                    ← Detailed installation guide (start here)
│   ├── BEST-PRACTICES.md             ← Daily operating discipline (propagation, profiles, recipes)
│   ├── VAULT-AUTOMATION.md           ← Auto-indexing: hooks, ccc wrapper, cron
│   ├── TOKEN-EFFICIENCY.md           ← 85%+ cost savings strategies
│   ├── OBSIDIAN-CONTEXT7.md          ← Knowledge vault + MCP setup + project ingestion
│   ├── AI-ROUTING.md                 ← Model routing pattern (COMPLEX vs SIMPLE)
│   ├── NEW-PROJECT.md                ← How to scaffold a new project
│   ├── EXISTING-PROJECT.md           ← Retrofitting existing projects
│   ├── AGENTS-GUIDE.md               ← The 11 specialist agents explained
│   ├── SKILLS-ECOSYSTEM.md           ← Skills: gstack + mattpocock + custom
│   ├── SWARM-ORCHESTRATION.md        ← 3 parallelism modes + the saved recipe library, durability + domain enforcement
│   ├── SETTINGS-AND-THEMES.md        ← Claude Code config, dark theme, hooks
│   ├── COMPARISON-mattpocock.md      ← Best-of-both hybrid analysis
│   ├── COMPARISON-karpathy.md        ← Karpathy CLAUDE.md benchmark + what we adopted
│   └── adr/                          ← ADRs (0001 Workflow substrate · 0002 recipe library)
├── starter-kit/                      ← The ai-project-scaffold skill
│   ├── SKILL.md                      ← Skill specification (invoke with /ai-project-scaffold)
│   ├── CHANGELOG.md                  ← Version history
│   ├── examples/                     ← Template files for generated docs
│   ├── platform-scripts/             ← Automation scripts (copy to ~/builds/_platform/scripts/)
│   │   ├── kg-reindex.sh             ← Rebuild knowledge-graph index
│   │   ├── vault-session-check.sh    ← SessionStart hook: vault freshness check
│   │   ├── vault-write-hook.sh       ← PostToolUse hook: auto re-index on vault write
│   │   ├── solo-builder-session-check.sh ← SessionStart hook: repo→~/.claude drift reminder
│   │   ├── fleet-status.sh           ← Status snapshot across ~/builds projects
│   │   └── ccc.fish                  ← Fish shell launcher (re-index on session close)
│   └── reference/
│       ├── agents/                   ← 11 specialist subagent definitions (incl. upgraded frontend-engineer)
│       ├── commands/                 ← 18 slash commands (incl. /design-feature, /mode, /review-exhaustive)
│       ├── workflows/                ← 7 profile-aware Workflow() recipes (incl. fast-dag-build, exhaustive-review)
│       ├── scripts/                  ← 9 guardrail hook scripts (incl. design-lint.sh)
│       └── settings.json.template    ← Per-project Claude Code settings (all guardrails wired)
├── skills/
│   └── sync-skills/                  ← /sync-skills command (install to ~/.claude/skills/sync-skills/)
│       ├── SKILL.md                  ← Skill workflow: auto-discover + sync all third-party sources
│       └── sources.json              ← Registry of tracked sources (gstack, mattpocock, Karpathy, MCPs)
└── settings/
    ├── settings.json.template        ← Claude Code settings with hooks wired
    ├── settings.local.json.template  ← Per-machine permission allowlist template
    └── CLAUDE.md.template            ← Personal L1 standing instructions template
```

---

## The Daily Workflow

```bash
# Launch Claude Code (auto re-indexes vault on exit)
ccc

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
> /vault-update                      # write/update vault INDEX.md + trigger re-index
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

On Max plans the binding constraint is the weekly Opus cap, not token cost — so even Best keeps bulk leaves (skeptics, grind) on Sonnet/Haiku to preserve it. See `starter-kit/reference/workflows/README.md` and `docs/SWARM-ORCHESTRATION.md`.

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
- **Matt Pocock's skills** — atomic daily workflow skills (grill-with-docs, diagnose, handoff, etc.)

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

*Built by [Markandey Singh](https://markandey.in) with Claude as co-author. v2.4, June 2026.*
