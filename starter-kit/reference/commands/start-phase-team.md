---
description: Launch a parallel agent team for a Phase 1 (or other early, low-risk-of-collision phase) workload. Requires Claude Code v2.1.32+ and CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1. Default team size 3-5; teammates own non-overlapping file domains.
argument-hint: <phase number, default 1>
---

# Start a Phase $ARGUMENTS agent team

Before doing anything else, run preflight checks. If any fails, fix it and re-run this command.

## Preflight

1. **Claude Code version:** confirm `claude --version` reports v2.1.32 or later. If not, stop and instruct the user to upgrade (or use `/build-phase-autopilot` instead).
2. **Experimental flag:** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` must be set (it should be in `.claude/settings.json` env).
3. **Clean working tree:** `git status --porcelain` must be empty.
4. **Feature branch:** must NOT be on `main` / `master`. If on main, instruct the user to:
   ```
   git checkout -b feature/phase-$ARGUMENTS-team
   ```
5. **Phase check:** `ROADMAP.md` must show Phase $ARGUMENTS as the active phase. Refuse to launch a team for a phase already complete or not yet started.
6. **No active team:** only one team at a time per the Claude Code docs. If `~/.claude/teams/` already has an active team for this project, instruct cleanup first.
7. **Default to Phase 1 only.** If `$ARGUMENTS` is unset or 1, proceed. If $ARGUMENTS >= 2, refuse unless an ADR in `DECISIONS.md` from the last 30 days explicitly extends team-pattern coverage to that phase. The reasoning: phases 2+ usually touch auth, citations, RBAC, external APIs — coordination friction outweighs parallelism gains.

## Spawn the team

After preflight, issue the following team-creation prompt. Adjust the teammate count and roles based on what `TASKS.md` shows for Phase $ARGUMENTS:

> Create an agent team to complete Phase $ARGUMENTS of this project. Spawn teammates owning **non-overlapping file domains**. Use `in-process` display mode (set in `.claude/settings.json` via `teammateMode`).
>
> **Recommended teammate composition for a fullstack Phase 1:**
>
> 1. **Backend** (`backend-engineer` subagent type) — owns the backend source directory. Implements backend-tagged tasks from `TASKS.md`. Vertical-slice TDD per the agent definition. Conventional Commits, one commit per task.
>
> 2. **Frontend** (`frontend-engineer` subagent type) — owns the frontend source directory. Implements frontend-tagged tasks from `TASKS.md`.
>
> 3. **Infra** (`devops-engineer` subagent type) — owns `infra/`, `.github/workflows/`, the top-level `Makefile`, and `docker-compose.yml`. Implements infra/tooling tasks. **Must not touch** application source.
>
> 4. **Security reviewer** (`security-architect` subagent type) — cross-cutting. After each teammate commits, runs the 10-point security checklist on the diff. Posts findings into the shared mailbox. **Read-only** on application code; allowed to add tests under `tests/security/` and to file blocking findings.
>
> Adjust this composition if the project is API-only (drop frontend), AI-involved (add an `ai-engineer` teammate for `ai/` work), or single-developer (drop the security reviewer in favor of using `/review-security` between tasks).
>
> **Shared task list:** use the Phase $ARGUMENTS entries from `TASKS.md` as the seed tasks. Each task lists its acceptance criterion.
>
> **Coordination rules — enforce strictly:**
> - **No file-edit overlap.** If a teammate needs to touch a file outside its domain, it sends a message to the owning teammate.
> - **Plan approval required.** All teammates submit a one-paragraph plan before implementation; the lead approves with the criterion "produces a passing `make quality` for the affected scope." Plans without tests are rejected.
> - **Quality gate per commit.** Each teammate runs `make quality` before committing. Red = no commit; fix and re-run.
> - **Security reviewer has veto.** A `CRITICAL` or `HIGH` finding from the reviewer blocks the merging teammate from committing further until resolved.
> - **Shared files are single-threaded** — `TASKS.md`, `DECISIONS.md`, and shared-schema directories are edited by one teammate at a time; the lead arbitrates.
>
> **Hooks already wired:** the team inherits the lead's `.claude/settings.json` permissions and hooks. The doc confirms: "Teammates start with the lead's permission settings."
>
> **Lead duties:**
> - Synthesize findings.
> - Block on the security reviewer's veto.
> - Do NOT start implementing tasks itself — wait for teammates (per the doc's guidance).
> - When all Phase $ARGUMENTS acceptance criteria in `ROADMAP.md` are green, STOP. Print the hand-off block below. Do NOT invoke `/phase-review` — that's a human gate.
>
> **Termination:**
> When all Phase $ARGUMENTS tasks in `TASKS.md` are marked `[x]` AND `make quality` is green AND the security reviewer reports no open findings, print:
>
> ```
> Phase $ARGUMENTS team work complete.
>
> Commits this run: <list>
> Open follow-ups (created by the team): <list>
> Security review: <count of findings, severities, any open>
>
> NEXT — HUMAN ACTIONS REQUIRED:
> 1. Read the diff: git log --since=<team-start-time> --stat
> 2. Spot-review one commit per teammate domain.
> 3. If satisfied: ask the lead to "Clean up the team" (per the docs).
> 4. Run /phase-review $ARGUMENTS in a fresh session afterward.
>    Sign docs/phase-reviews/phase-$ARGUMENTS.md by hand.
> ```

## Important reminders during the run

- **Shift+Down** cycles through teammates and lets you message them directly (in-process mode).
- **Ctrl+T** toggles the task list view.
- If a teammate appears stuck, message it directly. If still stuck after a nudge, spawn a replacement.
- To abort, tell the lead "Clean up the team" — do not run cleanup from teammates.

## Known limitations (per the Claude Code docs)

- No session resumption with in-process teammates.
- Task status can lag — the lead may need to nudge.
- Shutdown can be slow.
- Single team at a time; no nested teams; lead is fixed.
