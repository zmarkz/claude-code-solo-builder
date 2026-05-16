---
description: End-of-phase gate review. Invokes product-owner-reviewer to produce a one-page exec summary, risk callouts, and a go/no-go for the next phase.
argument-hint: <phase number, e.g. 1, 2, 3>
---

Run the product-owner review for phase: **$ARGUMENTS**

Workflow:

1. **Sanity check.** Confirm `$ARGUMENTS` is a valid phase number in `ROADMAP.md` and that all of its deliverables are claimed done in `TASKS.md`. If not, stop and report what's still open.

2. **Gather context.**
   - The phase's goal and exit criteria from `ROADMAP.md`.
   - The list of completed tasks for this phase from `TASKS.md`.
   - Commits since the start of the phase (`git log --since=...`).
   - New ADRs added during the phase (`grep "Date:" DECISIONS.md`).
   - The most recent QA report from `docs/qa-reports/`.
   - The most recent security review from `docs/security-reviews/`.
   - Any prior phase reviews under `docs/phase-reviews/`.

3. **Run the full quality gate** (don't trust prior runs).
   - `make quality`.
   - Eval suite if AI is involved.
   - Phase exit criteria from ROADMAP.md — verify each, one by one.

4. **Launch `product-owner-reviewer` subagent.** Hand it:
   - The phase goal and exit criteria.
   - The completed tasks list.
   - The quality-gate results.
   - The eval results (if applicable).
   - The list of new ADRs.
   - The QA + security review summaries.

5. **The subagent produces** the one-page review using its template, saved to `docs/phase-reviews/phase-$ARGUMENTS.md`.

6. **Verify the recommendation lands.**
   - If "Proceed": print the recommendation and tag the next phase as ready in TASKS.md.
   - If "Proceed with fixes": list the fixes as new TASKS.md entries blocked-by the phase, but allow the next phase to start.
   - If "Stop and remediate": list the remediations as P0 tasks. Block any new phase work in TASKS.md.

7. **Capture human signature.**
   - Add a placeholder for the human to fill: `Signed by <name> on <date>`.
   - Print: "Human review required. Open `docs/phase-reviews/phase-$ARGUMENTS.md` and sign before starting Phase $ARGUMENTS+1."

8. **Update ROADMAP.md** — check off the phase. If recommendation is "Stop and remediate," mark the phase as "in remediation" instead.

Don't proceed to Phase $ARGUMENTS+1 work in the same session. Phase boundaries are a deliberate human checkpoint.
