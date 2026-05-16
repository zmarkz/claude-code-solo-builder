---
description: Pre-release checklist. Use before tagging a release or deploying to staging/prod.
argument-hint: <target environment: staging | prod>
---

Prepare release for: **$ARGUMENTS**

Workflow:

1. **Confirm clean state.**
   - `git status` clean.
   - On a release branch (not directly on main if prod).
   - All commits referenced in CHANGELOG (or commit log) since the last tag.

2. **Run full quality gate.**
   - `make quality` — lint + typecheck + tests + security.
   - `make security` — secret scan + project's security test suite.
   - AI eval suite if applicable.
   - `make build` — production Docker images build.

3. **Migration check.**
   - List all schema migrations since the last release.
   - For each: is it backwards-compatible? Can prod run the old code while the migration is applied? Document any blue-green gotchas.
   - Test downgrade on a copy of staging data.

4. **Security review.**
   - Invoke `security-architect` for a final review against the pre-release must-fix list in `SECURITY_MODEL.md`.
   - For prod: all items must be green. For staging: best-effort, but no CRITICAL/HIGH open.

5. **Policy / env check.**
   - Verify project-specific safety env flags are correctly set in the target env config.
   - Verify no test or seed data references a forbidden endpoint or region.

6. **Audit log check** (if applicable).
   - Verify the chain on the most recent 1000 audit entries.
   - Verify `audit_log` has no UPDATE/DELETE grants for the application role.

7. **Backup / rollback dry-run.**
   - Confirm latest backup is < 24h old and restorable.
   - Confirm rollback path (`make rollback`) is documented and tested.

8. **Stakeholder confirmation.**
   - For prod: human approval (project owner + security lead) recorded in `docs/releases/<version>.md`.

9. **Generate release notes.**
   - Features (from commit messages).
   - Migrations (with backwards-compat notes).
   - ADRs added.
   - Eval changes.
   - Known issues.

10. **Tag and document.**
    - Save the full checklist outcome to `docs/releases/<version>.md`.
    - If all green: print the `git tag` command for the human to run.
    - If anything red: print blockers and stop.

Do NOT push the tag or run the deployment yourself. Output the commands the human needs to run.
