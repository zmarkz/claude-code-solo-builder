# Architecture — claude-code-solo-builder

> Seeded from the kit's own `/map-codebase` run (saver mode), 2026-07-19 —
> eating our own dog food per the workflow's completeness critic.

This repo is a **meta-framework for Claude Code, not a runtime application**:
no compiler, no database, no test suite of its own. It is a versioned bundle of
agent personas, slash-command prompts, `Workflow()` recipes, and shell hook
scripts. All internal wiring is **by string name** (agent `name:` frontmatter,
`Workflow({name})`, hook paths in settings templates); the only mechanical
checks are `node --check` on recipes and `make check` for repo↔`~/.claude`
drift.

## Propagation (the data flow)

```
this repo (generic, public)
  │  install.sh / make install — rsync; additive for shared dirs,
  │  full-ownership for skills/; never touches settings.json/CLAUDE.md
  ▼
~/.claude (live global config: agents/ commands/ workflows/ skills/ scripts/)
  │  optional: solo-builder-private installer runs AFTER (ADR 0003 —
  │  install order is the entire layering mechanism)
  ▼
per project: /sync-project (retrofit) or ai-project-scaffold (new)
  ▼
<project>/.claude/ + planning docs + guardrail scripts + local RAG index
  ▼
runtime: slash command → agent, or Workflow({name}) → recipe fans out
  agents at ADR-0005 model tiers, hooks gate every write
  ▼
human review gate (nothing self-merges)
```

## Components

| Component | Paths | Role |
|---|---|---|
| Propagation entrypoint | `install.sh`, `Makefile` | Only code that touches `~/.claude`; `--check` = drift report |
| Scaffold kit | `starter-kit/SKILL.md`, `starter-kit/reference/` | The payload: 11 agents, 22 commands, 7 recipes, 10 guardrail scripts, templates |
| Workflow recipes | `starter-kit/reference/workflows/*.js` | Profile-aware (Best/Saver) multi-agent recipes; only `safe-migration`/`fast-dag-build` write, via isolated worktrees; none self-merge |
| Global session hooks | `scripts/*.sh` | SessionStart drift + vault checks, installed to `~/.claude/scripts/` |
| Config templates | `settings/*.template` | Copied by hand once; never overwritten by the installer |
| sync-skills | `skills/sync-skills/` | Third-party-suite freshness; merges private `sources.local.json` (local wins) |
| Local RAG module | `docs/LOCAL-RAG.md` + per-project `.leann/` | One retrieval call instead of grep loops (ADR 0004); reuse loop via `~/.claude/patterns/` |
| Doctrine docs | `PLAYBOOK.md`, `docs/*.md` | The operating manual (4-layer model: Portfolio/Build/Knowledge/Platform) |
| Decision record | `docs/adr/` + `INDEX.md` | ADRs 0001–0006 govern the kit's own construction |

## Key invariants

- **The public repo stays generic** — personal content lives only in the
  private overlay (ADR 0003). The sweep grep in PR verification enforces it.
- **String-name wiring means renames are breaking changes** — grep for the old
  name across agents/commands/workflows/docs before renaming anything.
- **Opus only at gates** in recipes (ADR 0005); tier aliases only, never
  pinned model IDs (ADR 0003).
- **Nothing automated self-approves** — phase reviews, recipe outputs, and
  migrations all stop at a human gate.
