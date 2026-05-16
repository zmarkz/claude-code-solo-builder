# Starting a New Project

> From zero to a scaffolded, production-ready project structure in ~10 minutes.

---

## The Two-App Rule

Before starting a new app: **enforce the two-app rule**.

You should have ≤2 apps in `ACTIVE-BUILD` status at any time. If both slots are taken:
1. Check if one can move to `STABILIZE` (MVP shipped, just maintenance)
2. If one must die, run the kill ritual first (see PLAYBOOK.md Part 5)
3. Only then open a new `ACTIVE-BUILD` slot

**Why:** Context-switching tax is real. Three active builds means three sets of mental state to load. Quality degrades, nothing ships.

---

## Step 1 — Validate Before Scaffolding

Run these validation gates before writing a single line of code:

```
□ Can you name the problem in one sentence? ("X people can't do Y because Z")
□ Can you name 3 real people who would pay for it?
□ Does it fit your tech stack (no new tech = no new learning curve)?
□ Is it killable? Can you define kill criteria right now?
□ Can you ship an MVP in ≤14 days?
□ No-landing-page anti-pattern check: can you ship a landing + waitlist by Day 3?
```

If any gate fails: idea goes to `00-Inbox/` in the vault as a capture note. Not a project yet.

---

## Step 2 — Choose the Right Stack

### Greenfield apps (default)
```
Frontend: Next.js 15 + TypeScript + Tailwind CSS + shadcn/ui
Backend:  Next.js route handlers or Hono on Cloudflare Workers
DB:       Supabase (Postgres + Auth + Storage + Realtime)
Jobs:     Trigger.dev or Inngest
Payments: Stripe (global) / Razorpay (India)
Email:    Resend
Hosting:  Vercel + Cloudflare Workers
```

### When to deviate from the stack

Write an ADR first. The ADR must answer:
- What does this tech provide that the standard stack can't?
- What is the migration cost if this turns out to be wrong?
- Is this a one-way door or can we switch?

Don't deviate for taste. Deviate only when there's a forcing function (Java ecosystem requirement, existing infra dependency, compliance mandate).

---

## Step 3 — Scaffold with ai-project-scaffold

```bash
mkdir ~/builds/my-app && cd ~/builds/my-app
claude
```

Then in Claude Code:
```
> /ai-project-scaffold
```

The skill asks 11 questions. Answer them all before it starts generating:

1. **Project name** — one short string (used in filenames and docs)
2. **One-line product description** — "What is this?" in one sentence
3. **Primary users / personas** — free text, who uses it?
4. **Tech stack profile** — pick from list or describe custom
5. **Number of phases** — default 4-7, each 5-10 days
6. **Security profile** — `production-grade` / `internal-tool` / `personal-project`
7. **Regulatory involvement?** — GDPR, HIPAA, SOC 2, PCI DSS, RBI, etc.
8. **Multi-tenant or single-tenant?**
9. **AI/LLM in the product?** If yes: local-only, hosted-only, or hybrid?
10. **Deployment target** — Docker / Vercel / AWS / GCP / etc.
11. **Phase 1 task list** — 5-10 specific tasks or describe the goal

After ~10 minutes, you have:

### Generated planning docs
```
CLAUDE.md                     ≤200 lines, loaded every session
PROJECT_CONTEXT.md            The "why": personas, market, non-goals
CONTEXT.md                    DDD ubiquitous-language glossary
ARCHITECTURE.md               System design + data model
ROADMAP.md                    Phases with exit criteria
SECURITY_MODEL.md             Threat model, trust boundaries, authN/authZ
TASKS.md                      Phase 1 task list
docs/adr/0000-template.md     ADR template
docs/adr/INDEX.md             ADR index
README.md                     Quick start + repo map
HANDOFF.md                    First-session instructions
```

### Generated infrastructure
```
.claude/
├── agents/              ← 11 specialist subagents
├── commands/            ← 9 slash commands
└── settings.json        ← deny/ask/allow permissions perimeter

scripts/
├── session-start.sh     ← SessionStart hook
├── guard-dangerous-command.sh  ← PreToolUse Bash hook
├── check-secrets-staged.sh     ← PreToolUse Write hook
├── secret-scan.sh              ← Full secret scanner
├── run-quality-checks.sh       ← PostToolUse quality gate
└── session-snapshot.sh         ← PreCompact hook

Makefile
docker-compose.yml
.pre-commit-config.yaml
.gitignore
.editorconfig
.env.example
```

---

## Step 4 — Run the First Session

```bash
chmod +x scripts/*.sh
git init -b main
git add . && git commit -m "chore: phase 0 scaffold"
pre-commit install    # if pre-commit is available
claude
```

In Claude Code:
```
> /start-session
```

This reads:
- Active phase from ROADMAP.md
- Phase 1 tasks from TASKS.md
- Relevant vault notes (via kg_search)
- Current ADR index

Output: "You're in Phase 1. Next 3 tasks: [list]. No blockers."

---

## Step 5 — The First Feature

```
> /grill-with-docs user authentication
```

The grilling phase:
- Asks one question at a time about the feature
- Provides recommended answers based on CONTEXT.md
- Sharpens the glossary inline
- Drafts any needed ADRs (applies 3-test threshold)
- Takes 5-15 minutes

Then:
```
> /plan-feature auth-signup
```

This invokes:
1. product-manager → vertical-slice scoping
2. solution-architect → design + ADRs
3. security-architect → auth/tenancy review
4. Output: `docs/specs/auth-signup.md`

Human reviews and approves the spec. Then:
```
> /build-feature auth-signup
```

Vertical-slice implementation: schema → API → worker → UI → test → docs.

---

## Step 6 — First Week Cadence

| Day | Work |
|-----|------|
| 1 | Scaffold + landing page (waitlist CTA — no-landing-page anti-pattern check) |
| 2-3 | Phase 1 core features (auth, primary flow) |
| 4-5 | Phase 1 secondary features |
| 6 | `/run-qa phase` — full adversarial testing |
| 7 | `/phase-review 1` — product-owner review + human sign-off |

---

## Vault Entry (Create Before First Commit)

Before starting any real work, create the vault note:

```bash
# In Obsidian: New note at 01-Projects/my-app/STATUS.md
```

```markdown
---
type: entity
name: my-app
status: ACTIVE-BUILD
created_by: markandey
last_edited_by: markandey
---
# my-app
[One-line product description]
Started: [date]
Kill criteria: [what must happen for this to be killed]
Target: [ship MVP by date]
[[Related prior projects if any]]
```

---

## Anti-Patterns to Avoid from Day 1

1. **No landing page** — Ship a landing page with waitlist before writing backend code. If you can't describe the app to a stranger, you can't build it.
2. **Horizontal slicing** — Don't write all schema first, then all routes, then all UI. Vertical slices (one full feature end-to-end) or nothing.
3. **Stack deviation without ADR** — Any new tech requires an ADR before writing code.
4. **Direct model calls** — Never call Claude/OpenAI/Ollama directly. Always through Agent Farm classifier.
5. **Secrets in code** — The `check-secrets-staged.sh` hook catches this. Never commit secrets.
6. **ADR for everything** — Apply the 3-test threshold. 5-10 ADRs per project, not 50.
7. **Scaffold overwriting** — Never run the scaffold on a project that already has code. It overwrites.
8. **CLAUDE.md > 200 lines** — Every extra line costs tokens forever.

---

## Directory Layout for Multiple Projects

```
~/builds/                      ← greenfield apps
├── _platform/                 ← shared components, helpers
├── _templates/                ← bootstrap templates
├── _starter-kit/              ← this kit
├── my-saas-app/               ← ACTIVE-BUILD
├── my-other-app/              ← VALIDATE
└── _archive/                  ← killed apps (keep forever)

~/Obsidian/Builds/             ← the vault
```

---

*See also: `docs/EXISTING-PROJECT.md` for retrofitting, `PLAYBOOK.md` Part 7 for the full per-app build cycle.*
