---
description: Run the QA pass — tests, evals, adversarial cases, coverage review. Invokes qa-engineer.
argument-hint: <optional: feature slug or "phase">
---

Run the QA pass for: **$ARGUMENTS** (defaults to "current branch" if empty, "phase" runs the full phase QA gate).

Workflow:

1. **Run automated suites.**
   - `make test` — unit + integration.
   - The project's security test suite (`pytest tests/security/`, or equivalent).
   - End-to-end tests if applicable (`pnpm test:e2e`, Playwright, etc.).
   - The AI eval suite (`python ai/evals/runner.py`) if AI is involved.

2. **Capture results.** Pass/fail counts, eval scores, regression diffs.

3. **Launch `qa-engineer` subagent.** Give it:
   - The test results.
   - The feature spec (if applicable) or branch diff.
   - The current eval thresholds from ROADMAP.md (if applicable).

4. The subagent reviews:
   - Coverage map (unit / integration / e2e / security / eval).
   - Gaps (missing test types).
   - Flaky risk.
   - Adversarial completeness (against its 10-item catalog).

5. If `$ARGUMENTS == "phase"`, also verify the phase exit criteria from ROADMAP.md item by item. Each criterion must have a passing test or a documented manual verification.

6. Save the QA report to `docs/qa-reports/<YYYY-MM-DD>-<scope>.md`.

7. Output:
   - Pass/fail summary.
   - Eval scores vs thresholds (if applicable).
   - Gaps that block phase completion.
   - Recommended next QA actions.

Don't mark anything as "ready" if any of:
- Unit/integration suite is red.
- Eval regression (if AI involved).
- Any cross-tenant or authorization test failure (P0).
- Flaky tests in the diff (fix, don't skip).
