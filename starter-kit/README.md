# ai-project-scaffold — Claude Code skill

A reusable scaffold-generator for Claude Code projects. Installs once at user level, then bootstraps every future project with the same disciplined structure: phase gates, vertical-slice TDD, 11-agent team, 9 slash commands, 6 guardrail scripts, planning docs, and safety hooks.

> Distilled from a real project build. The infrastructure (agents, commands, scripts, settings template) is generic; the planning docs (CLAUDE.md, ROADMAP.md, SECURITY_MODEL.md, etc.) are generated per-project from your answers.

---

## What you get on every new project

```
your-new-project/
├── CLAUDE.md                          # ≤200 lines, loaded every session
├── PROJECT_CONTEXT.md
├── ARCHITECTURE.md
├── ROADMAP.md                         # phases with exit criteria + human gates
├── SECURITY_MODEL.md                  # (skipped for personal-project profile)
├── TASKS.md                           # live task list
├── DECISIONS.md                       # ADR log
├── README.md
├── HANDOFF.md
├── .claude/
│   ├── settings.json                  # permissions, hooks, env
│   ├── agents/                        # 11 subagents (reusable as agent-team teammates)
│   ├── commands/                      # 9 slash commands
│   └── README.md
├── apps/, packages/, ai/, infra/, compliance/, docs/, tests/, scripts/  # per stack
├── Makefile                           # make help, make dev, make quality
├── docker-compose.yml
├── .pre-commit-config.yaml
├── .gitignore, .env.example, .editorconfig
└── scripts/                           # 6 hook scripts (session-start, secret-scan, ...)
```

## Install (user-level, once)

```bash
# 1. The skill itself
mkdir -p ~/.claude/skills
mv ai-project-scaffold ~/.claude/skills/ai-project-scaffold
ls ~/.claude/skills/ai-project-scaffold/SKILL.md   # confirm discoverable

# 2. v1.1 — Dual-residency: also install the kit's components at user level
# so upstream improvements propagate to unmodified projects automatically.
mkdir -p ~/.claude/agents ~/.claude/commands
cp ~/.claude/skills/ai-project-scaffold/reference/agents/*.md   ~/.claude/agents/
cp ~/.claude/skills/ai-project-scaffold/reference/commands/*.md ~/.claude/commands/

# 3. v1.1 — Install Matt Pocock's atomic skills for daily session work
npx skills@latest add mattpocock/skills
# Pick at minimum: grill-with-docs, diagnose, zoom-out,
#                  improve-codebase-architecture, handoff
```

Claude Code auto-discovers skills, agents, and commands under `~/.claude/`. Per-project overrides win when both exist; unmodified projects inherit upstream improvements.

## Use on a new project

```bash
mkdir ~/projects/your-new-project && cd ~/projects/your-new-project
claude
```

Inside the Claude Code session:

> "Scaffold this project using the ai-project-scaffold skill. It's a [one-line description of what you're building]."

Or simply: "Start a new project here." If Claude Code's skill discovery is working, it should pick up the description and route to this skill.

Claude Code will then:

1. Confirm the directory is empty or near-empty.
2. Ask you ~11 short questions (project name, tech stack, security profile, AI involvement, deployment target, Phase 1 tasks).
3. Copy the reusable infrastructure from this skill's `reference/`.
4. Generate the planning docs customized to your answers.
5. Generate the monorepo skeleton based on your tech stack.
6. Verify the scaffold (JSON valid, scripts parse, CLAUDE.md ≤ 200 lines).
7. Print the first 5 commands for you to run.

The whole process takes 10-20 minutes of Claude Code time plus 5 minutes of your input.

## Updating the skill

When you learn something new about how you like to work, edit the relevant file under `~/.claude/skills/ai-project-scaffold/`. New projects will pick up the change immediately.

For changes that should apply to *existing* projects too, you'll need to copy the updated file into each project's `.claude/agents/` (or `.claude/commands/` or `scripts/`) — the scaffold is a one-time generator, not a live link.

## What's in `reference/`

```
reference/
├── settings.json.template           # Claude Code settings: permissions, hooks, env
├── .gitignore.template
├── .editorconfig.template
├── .env.example.template
├── agents/                          # 11 generic subagent definitions
│   ├── product-manager.md
│   ├── solution-architect.md
│   ├── security-architect.md
│   ├── backend-engineer.md
│   ├── frontend-engineer.md
│   ├── ai-engineer.md               # only relevant for AI/RAG projects
│   ├── devops-engineer.md
│   ├── qa-engineer.md
│   ├── domain-expert.md             # placeholder; rename per domain
│   ├── technical-writer.md
│   └── product-owner-reviewer.md    # end-of-phase reviewer
├── commands/                        # 9 generic slash commands
│   ├── start-session.md
│   ├── plan-feature.md
│   ├── build-feature.md
│   ├── review-security.md
│   ├── run-qa.md
│   ├── prepare-release.md
│   ├── phase-review.md
│   ├── start-phase-team.md          # parallel agent team (v2.1.32+)
│   └── build-phase-autopilot.md     # bounded chained autonomy
├── scripts/                         # 6 hook + utility scripts
│   ├── session-start.sh             # SessionStart
│   ├── guard-dangerous-command.sh   # PreToolUse Bash
│   ├── check-secrets-staged.sh     # PreToolUse Write/Edit
│   ├── secret-scan.sh               # pre-commit + CI
│   ├── run-quality-checks.sh        # PostToolUse Write/Edit
│   └── session-snapshot.sh          # PreCompact
└── examples/                        # reference shapes for the planning docs
    ├── CLAUDE.md.example
    └── ROADMAP.md.example
```

## Patterns this enforces

The skill enforces eight patterns. Read `SKILL.md` for the full list:

1. **Phase gates** with human checkpoints — no autopilot self-approves a phase.
2. **Vertical slices** — schema → API → worker → UI → test → docs, no horizontal stubs.
3. **Tests are mandatory** — pre-commit, CI, `/run-qa` all enforce.
4. **ADR every non-trivial decision** — `DECISIONS.md` is the canonical record.
5. **Subagents double as agent-team teammates** — per Claude Code docs.
6. **Hooks for safety, not cleverness** — fail loud, fail early.
7. **Context-window management built in** — CLAUDE.md (200 lines), `/start-session`, `PreCompact` snapshot.
8. **Two bounded parallelism modes** — `/start-phase-team` and `/build-phase-autopilot`, both Phase-1-by-default.

## When NOT to use this

- One-off scripts / hobby code (overkill).
- Adding to an existing project (this is a fresh-scaffold tool).
- Projects where you don't want phase gates or test-mandatory discipline.

For those, write `CLAUDE.md` by hand. Faster.

## Customizing for your domain

The `domain-expert.md` subagent and `compliance/frameworks/` directory are placeholders. After scaffolding:

- Rename `domain-expert.md` to `<your-domain>-expert.md` (e.g., `fintech-expert.md`, `health-expert.md`, `legal-expert.md`).
- Replace its body with domain-specific working rules and citation requirements.
- If your domain is regulated, populate `compliance/frameworks/` with the relevant control corpora.

This skill is opinionated about **how to build**, not about **what to build**. The domain layer is yours to fill in.

## Versioning

Track this skill's version in this README:

| Version | Date       | Notes |
|---------|------------|-------|
| 1.0     | 2026-05-16 | Initial: 11 agents, 9 commands, 6 scripts, agent-teams support. |
| 1.1     | 2026-05-16 | **Merge with mattpocock/skills patterns.** New `CONTEXT.md` (DDD ubiquitous-language glossary, distinct from `PROJECT_CONTEXT.md`). Per-file ADRs at `docs/adr/NNNN-<slug>.md` (replaces single `DECISIONS.md`) with the 3-test threshold. `/plan-feature` gains an embedded grilling phase (Step 0) before PM scoping. `/build-feature` gains TDD anti-pattern callout (vertical tracer-bullet cycles, not horizontal test-batching). Agents updated to read `CONTEXT.md`. Dual-residency installation pattern documented (components also installable at user level so upstream improvements propagate). |

Bump and date when you make non-trivial changes.

## License

Use freely, modify freely, redistribute freely. No warranty.
