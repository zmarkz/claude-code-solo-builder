---
description: Run a focused security review on the current branch or a specific path. Invokes security-architect.
argument-hint: <optional path or "branch" for whole-branch review>
---

Run a security review.

Scope:
- If `$ARGUMENTS` is empty or "branch": review the full diff between the current branch and the default branch (`git diff main...HEAD` or `master...HEAD`).
- If `$ARGUMENTS` is a path: review changes to that path only.

Workflow:

1. Read `SECURITY_MODEL.md`.
2. Gather the diff and the list of changed files.
3. Launch `security-architect` subagent. Give it:
   - The diff.
   - The list of files.
   - The relevant SECURITY_MODEL.md sections.
   - The summary of the change (from the most recent commit messages).

4. The subagent walks through the 10-point checklist in its system prompt (tenant isolation, authN, authZ, document/input safety, restricted endpoints, audit log, secrets, network, prompt-injection if AI, data residency / privacy).

5. The subagent produces its standard output:
   - Touch points.
   - Findings with severity (CRITICAL / HIGH / MEDIUM / LOW / INFO).
   - Must-fix-before-merge list.
   - Should-fix-before-release list.
   - Recommendation.

6. Save the review to `docs/security-reviews/<YYYY-MM-DD>-<branch-or-path-slug>.md`.

7. If any CRITICAL or HIGH findings: do not allow the change to merge. Print the must-fix list and stop.

8. If only MEDIUM and below: print the review, ask the human whether to address before merge or file for later.

Always run automated checks alongside the human review:
- `bash scripts/secret-scan.sh`
- `pytest tests/security/` (or equivalent for the stack)
- The RBAC / authorization coverage test for the project

Report any automated check failures separately from the human review findings.
