---
description: Re-load project context at the start of every Claude Code session. Run this first, every time.
---

You are starting a new session on this project. Before doing anything else:

1. Read `CLAUDE.md` (the project's session-start preamble).
2. Read the **"Current phase"** section of `ROADMAP.md` and the **non-completed** items under that phase in `TASKS.md`.
3. Skim `DECISIONS.md` for any ADR from the last 7 days.
4. Run `bash scripts/session-start.sh` — it prints the current phase, key env flags, and whether there are uncommitted changes.
5. Check `docs/phase-reviews/` for the latest review and any "must-fix" items still open.

Then briefly report (≤ 10 lines):

- Which phase we're in.
- The next 1-3 tasks you'd recommend tackling and why.
- Any open blockers from prior `product-owner-reviewer` sign-offs.
- Confirmation that the project's safety env flags are set.

Do not begin implementation until I confirm the next task.
