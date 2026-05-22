# Claude Code Solo Builder — Complete Setup & Playbook

> An operating system for solo developers building a multi-app portfolio with AI agents.
> Token-efficient, vault-grounded, security-first, and compounding over time.

**Version 2.3 — May 2026**

---

## What is this?

This repository is the **complete, shareable setup** that lets a solo developer run like a 10-person team using Claude Code. It includes:

- **The Playbook** — a 16-part operating manual covering mental model, AI swarm patterns, knowledge vault, portfolio management, and daily cadences
- **The Starter Kit** — a Claude Code skill that scaffolds any new project with 11 agents, 9 slash commands, 6 safety hooks, and all planning docs in ~10 minutes
- **The Knowledge Stack** — Obsidian vault + Context7 + knowledge-graph MCP working together to ground every AI call in your prior decisions
- **Token Efficiency Guide** — how to get 85%+ cost savings through model routing, context management, and vault-first queries
- **Settings & Agents** — production-grade Claude Code settings, 11 specialist subagents, 9 workflow commands, and guardrail scripts
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

### Step 2 — Install the starter kit skill (user-level)
```bash
mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/commands
cp -r starter-kit ~/.claude/skills/ai-project-scaffold

# Dual-residency: install components at user level too (improvements propagate)
cp starter-kit/reference/agents/*.md ~/.claude/agents/
cp starter-kit/reference/commands/*.md ~/.claude/commands/
```

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
├── PLAYBOOK.md                       ← The full 16-part operating manual
├── docs/
│   ├── INSTALL.md                    ← Detailed installation guide (start here)
│   ├── VAULT-AUTOMATION.md           ← Auto-indexing: hooks, ccc wrapper, cron
│   ├── TOKEN-EFFICIENCY.md           ← 85%+ cost savings strategies
│   ├── OBSIDIAN-CONTEXT7.md          ← Knowledge vault + MCP setup + project ingestion
│   ├── AI-ROUTING.md                 ← Model routing pattern (COMPLEX vs SIMPLE)
│   ├── NEW-PROJECT.md                ← How to scaffold a new project
│   ├── EXISTING-PROJECT.md           ← Retrofitting existing projects
│   ├── AGENTS-GUIDE.md               ← The 11 specialist agents explained
│   ├── SKILLS-ECOSYSTEM.md           ← Skills: gstack + mattpocock + custom
│   ├── SWARM-ORCHESTRATION.md        ← Parallel teams, autopilot, swarm patterns
│   ├── SETTINGS-AND-THEMES.md        ← Claude Code config, dark theme, hooks
│   ├── COMPARISON-mattpocock.md      ← Best-of-both hybrid analysis
│   └── COMPARISON-karpathy.md        ← Karpathy CLAUDE.md benchmark + what we adopted
├── starter-kit/                      ← The ai-project-scaffold skill
│   ├── SKILL.md                      ← Skill specification (invoke with /ai-project-scaffold)
│   ├── CHANGELOG.md                  ← Version history
│   ├── examples/                     ← Template files for generated docs
│   ├── platform-scripts/             ← Automation scripts (copy to ~/builds/_platform/scripts/)
│   │   ├── kg-reindex.sh             ← Rebuild knowledge-graph index
│   │   ├── vault-session-check.sh    ← SessionStart hook: vault freshness check
│   │   ├── vault-write-hook.sh       ← PostToolUse hook: auto re-index on vault write
│   │   └── ccc.fish                  ← Fish shell launcher (re-index on session close)
│   └── reference/
│       ├── agents/                   ← 11 specialist subagent definitions (incl. upgraded frontend-engineer)
│       ├── commands/                 ← 11 slash commands (incl. /design-feature)
│       └── scripts/                  ← 7 guardrail hook scripts (incl. design-lint.sh)
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

*Built by [Markandey Singh](https://markandey.in) with Claude as co-author. v2.3, May 2026.*
