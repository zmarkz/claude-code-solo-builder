# Skills Ecosystem

> Three layers of skills: gstack (infrastructure workflows), mattpocock (daily session skills), and custom project seeds.

---

## The Three Layers

```
~/.claude/skills/
├── gstack/                    ← Infrastructure + workflow skills (30+ skills)
│   ├── browse/
│   ├── plan-ceo-review/
│   ├── plan-eng-review/
│   ├── review/
│   ├── ship/
│   └── ...
├── mattpocock-skills/         ← Atomic daily workflow skills (15 skills)
│   ├── grill-with-docs/
│   ├── diagnose/
│   ├── zoom-out/
│   ├── handoff/
│   └── ...
└── ai-project-scaffold/       ← Project scaffold (this kit)
```

**User-level commands and agents** (`~/.claude/agents/`, `~/.claude/commands/`):
- Apply to every project automatically
- Override: per-project `.claude/agents/` takes precedence

---

## Layer 1 — gstack Skills

gstack is a comprehensive skill ecosystem covering the full software development lifecycle. Key skills by category:

### Planning

| Skill | When to use |
|-------|------------|
| `/office-hours` | Async planning session — big picture review |
| `/plan-ceo-review` | CEO/founder mode — challenge scope, think bigger, kill feature |
| `/plan-eng-review` | Engineering manager mode — lock architecture, data flow, edge cases |
| `/plan-design-review` | Design mode — component structure, UX flows |
| `/autoplan` | Full auto-review pipeline — runs CEO + eng + design + DX reviews sequentially |
| `/codex` | Second opinion via OpenAI Codex — code review, challenge, consult |

### Shipping

| Skill | When to use |
|-------|------------|
| `/ship` | Deployment workflow — pre-flight, deploy, verify |
| `/land-and-deploy` | Landing page deployment |
| `/canary` | Canary deployment — gradual rollout with automated rollback |
| `/review` | Pre-landing PR review — SQL safety, trust boundary, conditional side effects |
| `/design-review` | UI/UX review before shipping |
| `/benchmark` | Performance regression detection — CWV baselines, before/after comparison |

### Quality

| Skill | When to use |
|-------|------------|
| `/qa` | Full QA cycle — test strategy + adversarial cases |
| `/qa-only` | Just run QA, no planning |
| `/investigate` | Deep-dive investigation — root cause analysis |
| `/diagnose` | Structured debug loop (also in mattpocock layer) |
| `/review-security` | Security-architect review pass |

### Context management

| Skill | When to use |
|-------|------------|
| `/careful` | Activate extra caution mode before risky operations |
| `/freeze` | Freeze a set of files from modification |
| `/guard` | Guard mode — require confirmation on every write |
| `/unfreeze` | Remove freeze |
| `/context-save` | Save current context to disk |
| `/context-restore` | Restore saved context |

### Development experience

| Skill | When to use |
|-------|------------|
| `/browse` | Web browsing — always use this instead of direct browser tools |
| `/devex-review` | Developer experience review — friction points in setup |
| `/plan-devex-review` | DX review from a planning perspective |
| `/retro` | Project retrospective — what worked, what didn't |

### SEO (25 skills)

Full SEO skill suite: `/seo`, `/seo-audit`, `/seo-plan`, `/seo-content`, `/seo-technical`, `/seo-schema`, `/seo-google`, `/seo-images`, `/seo-local`, `/seo-cluster`, `/seo-sxo`, `/seo-backlinks`, `/seo-geo`, `/seo-sitemap`, `/seo-ecommerce`, `/seo-drift`, `/seo-maps`, `/seo-dataforseo`, `/seo-image-gen`, `/seo-performance`, `/seo-visual`, `/seo-hreflang`, `/seo-firecrawl`, `/seo-programmatic`.

### Sync + automation

| Skill | When to use |
|-------|------------|
| `/sync-gbrain` | Keep knowledge base current with repo code |
| `/gstack-upgrade` | Upgrade gstack to latest version |
| `/health` | System health check — all services, disk, memory |
| `/kill-app` | Archive repo, downgrade tiers, export data, postmortem |

### Install gstack
```bash
# Follow gstack documentation for installation
# gstack is installed at ~/.claude/skills/gstack
```

---

## Layer 2 — mattpocock/skills (Atomic Daily Workflow)

Install:
```bash
npx skills@latest add mattpocock/skills
# Select: grill-with-docs, diagnose, zoom-out, improve-codebase-architecture, handoff, caveman
```

### The 6 Essential Skills

#### `/grill-with-docs` — Pre-implementation interview

**What it does:** Relentless one-question-at-a-time interview before every change. Sharpens CONTEXT.md inline. Drafts ADRs sparingly.

**Use it:** Before every non-trivial feature or change. After grilling, you have:
- Clarified requirements in CONTEXT.md
- Any needed ADRs drafted
- A much tighter spec

**Don't use it:** For trivial changes (fixing a typo, updating a constant).

#### `/diagnose` — Structured debug loop

**What it does:** Reproduce → minimize → hypothesize → instrument → fix → regression-test. Refuses to jump to a fix without completing the loop.

**Use it:** The moment something breaks and isn't immediately obvious.

**Loop steps:**
1. Reproduce the bug reliably
2. Minimize the reproduction (smallest possible failing case)
3. List 3 hypotheses ordered by probability
4. Instrument (add logging/assertions for top hypothesis)
5. Fix
6. Write a regression test that would have caught this

#### `/zoom-out` — Broader context orientation

**What it does:** Explains the codebase from a higher-level perspective. Useful when you've been deep in one file for hours and lost the bigger picture.

**Use it:** When you're about to make a change and suspect you don't understand the full context.

#### `/improve-codebase-architecture` — Weekly refactor ritual

**What it does:** References CONTEXT.md + ADRs, finds deepening opportunities in the codebase. Catches drift before it becomes a rewrite.

**Use it:** Weekly, not ad-hoc. Creates a refactoring spec before making any changes.

**Don't confuse with:** `solution-architect` which reviews individual decisions. This is the periodic health check.

#### `/handoff` — Human-readable session compaction

**What it does:** Creates a human-readable handoff doc: "We're trying to fix X, Approach A failed because Y, trying Approach B next."

**Use it:** End of every work session. Or when you know you'll be away for >24 hours.

**Compare to:** `session-snapshot.sh` which is the machine-readable state dump. Handoff is for humans to resume; snapshot is for Claude to recover context.

#### `/caveman` — Token compression mode

**What it does:** Switches communication to compressed mode: "Bug: race condition. Fix: mutex. Test: 100 concurrent." Saves ~75% tokens.

**Use it:** Long implementation sessions (>2 hours), when context is above 50%.

**Don't use it:** Planning, security review, or any time reasoning needs to be explicit.

---

## Layer 3 — Custom Project Seeds (The Five Seeds)

These are the unique-to-this-playbook skills. Install manually:

```bash
# After installing this kit, these are available as user-level skills
# (They're referenced in CLAUDE.md and can be invoked by name)
```

| Skill | Job |
|-------|-----|
| `bootstrap-new-app` | Copy template → Vercel + Supabase + GitHub + env wiring. Full greenfield setup. |
| `add-stripe-product` | Pricing plan + checkout + webhook handler. Idempotent, production-grade. |
| `add-supabase-table` | Migration + TypeScript types + RLS policies + CRUD route. Full vertical slice. |
| `ship-landing-page` | Landing page → waitlist → analytics. Deployed on day 1. |
| `kill-app` | Archive repo, downgrade cloud tiers, export data, write postmortem, vault entry. |

---

## Skill Precedence and Conflicts

When a skill is installed at both user level and project level:
- **Project level wins** — `.claude/skills/` overrides `~/.claude/skills/`
- **User level is the default** — used for any project that doesn't override

This enables "dual residency": improvements to user-level skills propagate to all projects. Project overrides are for project-specific behavior.

---

## The Complete Daily Workflow (Combined Skills)

```
Start of session:
  /start-session                      ← project command (from starter-kit)

Pre-implementation:
  /grill-with-docs <idea>             ← mattpocock layer
  /plan-feature <name>                ← project command → spawns PM + architect agents

Implementation:
  /build-feature <slug>               ← project command → vertical-slice TDD
  [if bug appears]:
  /diagnose                           ← mattpocock layer

During session (as needed):
  /zoom-out                           ← mattpocock layer (lost in the weeds)
  /careful                            ← gstack (before risky ops)
  /review-security                    ← project command (auth/tenancy changes)

End of session:
  /handoff                            ← mattpocock layer

Weekly:
  /improve-codebase-architecture      ← mattpocock layer
  /run-qa phase                       ← project command → QA agent

End of phase:
  /phase-review N                     ← project command → product-owner-reviewer

Shipping:
  /review                             ← gstack (pre-landing PR review)
  /ship                               ← gstack (deployment workflow)
  /canary                             ← gstack (gradual rollout)
```

---

## When to Add a New Skill

The test for adding any new skill:

1. **Would a senior engineer recognize this as a distinct task?** (not just a prompt variation)
2. **Will I use this at least weekly?** (otherwise it's noise in the skills list)
3. **Does it have a clear trigger condition?** ("use when X" not "use whenever")

If all three: write it. Use `/write-a-skill` (from mattpocock) as the authoring tool.

A good skill:
- Is ≤200 lines
- Has a clear trigger condition in the frontmatter description
- Produces a predictable, reviewable output
- Fails loudly if it can't complete (no silent partial results)

---

*See also: `docs/AGENTS-GUIDE.md` for the 11 specialist agents, `PLAYBOOK.md` Part 3.5 for the seed skills context.*
