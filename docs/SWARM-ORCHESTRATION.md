# Swarm Orchestration — Paperclip, Teams, and Autopilot

> How to run parallel AI workers safely, when to use each mode, and how Paperclip fits in.

---

## The Swarm Pattern

```
                  Paperclip / Scheduler
                          │
                          ▼
                   ┌─────────────┐
                   │ Team Lead   │  (Opus 4.7 — planning, decomposition)
                   └──────┬──────┘
                          │ decomposes into DAG
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
   ┌─────────┐      ┌─────────┐      ┌─────────┐
   │Worker A │      │Worker B │      │Worker C │     (Sonnet 4.6 / Haiku 4.5)
   │worktree │      │worktree │      │worktree │
   └────┬────┘      └────┬────┘      └────┬────┘
        └────────────────┼────────────────┘
                         ▼
                   ┌─────────────┐
                   │ Reviewer    │  (Opus 4.7 — quality gate)
                   └──────┬──────┘
                          ▼
                  Human (you) — final approve & merge
```

### What Paperclip is

Paperclip is an external scheduler/orchestrator that sits above Claude Code. It can:
- Trigger Claude Code sessions on a schedule (nightly, on git push, on CI event)
- Route work to the right Claude Code instance based on project
- Maintain a 24/7 fleet on a Mac Mini that accepts work via Telegram/API
- Bridge between external event sources (GitHub webhooks, cron jobs) and Claude Code sessions

For mobile control of a 24/7 fleet, also consider **Hermes Agent** (Nous Research) for Telegram-based orchestration.

**What to skip:**
- OpenClaw (470+ security advisories Jan–Apr 2026)
- Custom orchestrators (too much maintenance)
- Plugin maximalism (cap at 3–5 active plugins)

---

## Two Parallelism Modes

### Mode 1 — `/start-phase-team` (Parallel Teammates)

Launches 3-5 agents working simultaneously in non-overlapping file domains.

**Use when:**
- Multiple independent features to build simultaneously
- Wall-clock time matters more than total token cost
- File domains are clearly separable

**Requirements:**
```bash
# Requires Claude Code v2.1.32+
# Enable in settings:
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

**How it works:**
1. Team Lead (Opus 4.7) decomposes the phase into independent sub-tasks
2. Each worker gets exclusive ownership of specific files/directories
3. Workers run in parallel with separate git worktrees (no conflicts)
4. Reviewer (Opus 4.7) gates each worker's output before merge
5. Human approves the final merge

**Example team assignment:**
```
Worker A: apps/api/ (backend routes, DB migrations)
Worker B: apps/web/ (UI components, pages)
Worker C: packages/shared/ (types, validation schemas)
Security Reviewer: .claude/review — gates Workers A+C outputs
```

**Cost:** Higher total token usage (parallel contexts) but faster wall-clock time.

### Mode 2 — `/build-phase-autopilot` (Sequential Chained Autonomy)

Runs plan→build→commit for a list of feature slugs, one after another in a single session.

**Use when:**
- Features are sequential (B depends on A)
- Token economy matters more than speed
- Working alone, no time-pressure

**How it works:**
1. You provide a comma-separated list of Phase 1 feature slugs
2. For each slug: plan → build → commit (no spec-approval gate between slugs)
3. Stops at the phase review gate (never self-approves a phase)
4. Creates a commit log with one commit per feature slug

**Safeguards:**
- Allowlist: only Phase 1 slugs run by default
- To extend to Phase 2+: write an ADR with explicit reasoning
- Phase review gate cannot be bypassed (human signs off)

**Example:**
```bash
> /build-phase-autopilot auth-signup,auth-login,user-profile
# Builds auth-signup → commits → builds auth-login → commits → builds user-profile → commits
# → halts at /phase-review 1
```

---

## Git Worktrees for Safe Parallel Work

Each worker gets its own git worktree — a separate checkout of the same repo at a different path, sharing the same git history.

```bash
# Team Lead creates worktrees for workers
git worktree add ../worktrees/worker-a feature/api-layer
git worktree add ../worktrees/worker-b feature/ui-layer
git worktree add ../worktrees/worker-c feature/shared-types

# Workers operate independently, no file conflicts
# After review, merge back to main branch
git worktree remove ../worktrees/worker-a
```

**Why this matters:** Without worktrees, parallel agents either conflict on files or need lock files. With worktrees, each agent has exclusive ownership of its branch — zero conflicts until the explicit merge step.

---

## The Reviewer Role

The Reviewer agent (Opus 4.7) applies:
1. Security-architect checklist (any auth/storage/LLM changes)
2. QA-engineer adversarial catalog (edge cases, permissions)
3. Code style consistency (follows CONTEXT.md ubiquitous language)
4. Test coverage check (no new code without tests)
5. ADR check (any architectural decision → ADR filed)

The Reviewer can **veto** a worker's output. This is the last automated gate before human review.

---

## Mac Mini M4 Pro as 24/7 Fleet Host

For running a persistent swarm:

```bash
# Prevent sleep
sudo pmset -a sleep 0 displaysleep 10 disksleep 0

# Keep caffeinate running as a launchd service
caffeinate -dimsu &

# Essential tools
brew install tmux node git gh rclone
npm install -g @anthropic-ai/claude-code

# Persistent swarm session
tmux new-session -d -s swarm
# Workers attach to this session from any device
```

**Remote access stack:**
- Tailscale (zero-config VPN between devices)
- Cloudflare Tunnel (public endpoints for webhook receivers)
- SSH key-only (password auth disabled)
- Termux/Blink Shell for terminal from phone
- GitHub Mobile for PR review
- Telegram bot for build notifications

---

## When to Use Each Mode

| Situation | Mode |
|-----------|------|
| 3+ independent features, time pressure | `/start-phase-team` |
| Sequential features, token economy | `/build-phase-autopilot` |
| Single focused feature | Manual session |
| Scheduled nightly jobs (cleanup, reports) | Paperclip / cron trigger |
| Exploratory work before committing | `/prototype` (throwaway, no scaffold) |

---

## The Human Review Checkpoints

**Non-negotiable.** No automation bypasses these:

1. **Spec approval** — Before `/build-feature`, human reads and approves the spec in `docs/specs/<slug>.md`
2. **PR review** — Human reviews the diff before merging (GitHub mobile works for this)
3. **Phase review** — `/phase-review N` → product-owner-reviewer summary → human signs markdown
4. **Security review** — Any change touching auth/tenancy → `/review-security` before merge

The goal isn't to prevent AI from working — it's to keep decision-making under human control while automating implementation.

---

## Common Failure Modes

**File domain overlap:** Two workers modifying the same file → conflicts on merge. Assign exclusive ownership per file/directory before spawning.

**Context too large for Team Lead:** If the phase has >10 features, decompose into sub-phases first. Team Lead with a 100K+ context window planning 15 features produces mediocre decompositions.

**Reviewer approval creep:** If the Reviewer approves everything without substantive feedback, it's not actually reviewing. Add specific criteria to the Reviewer's system prompt for your domain.

**Phase gate bypass:** Never let autopilot self-approve a phase review. The `product-owner-reviewer` agent is the gate. Human signature is required. No exceptions.

---

*See also: `docs/AGENTS-GUIDE.md` for agent roles, `starter-kit/reference/commands/start-phase-team.md` for the command implementation.*
