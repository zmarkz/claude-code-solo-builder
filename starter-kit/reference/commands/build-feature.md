---
description: Implement a feature from an approved spec in docs/specs/. TDD by default. Vertical slice.
argument-hint: <feature slug from docs/specs/>
---

Implement the feature spec at **docs/specs/$ARGUMENTS.md**.

Pre-flight:

1. Read the spec. If it isn't marked `status: approved`, stop and ask the human to approve it.
2. Read CLAUDE.md, the relevant section of ARCHITECTURE.md, and SECURITY_MODEL.md if the spec touches auth/tenancy/storage/model.
3. Verify any project-specific safety env flags are set per `.claude/settings.json`.

## Two different "vertical slices" — don't confuse them

This file enforces two orthogonal kinds of vertical slicing. Both matter.

1. **Feature-level vertical slice (across layers).** Schema → Model → Schema (request/response) → Service → Router → Worker → UI → Docs. Don't ship one layer half-built. Order below.
2. **Test-level vertical slice (within a layer) — TDD tracer bullets.** When writing tests for any layer, do them **one at a time** with red-green between each. **NEVER write all tests first, then all implementation.** That's horizontal slicing of TDD and it produces crap tests (cribbed from mattpocock/skills `tdd`).

> WRONG (horizontal): RED [test1, test2, test3, test4, test5] → GREEN [impl1, impl2, impl3, impl4, impl5]
> RIGHT (vertical):   RED→GREEN test1→impl1 → RED→GREEN test2→impl2 → ...

Each test responds to what you learned from the previous cycle. You catch design problems early. Tests become resilient to refactor because each one targets observable behavior, not the shape of imagined APIs.

## TDD per-cycle checklist (apply at every RED→GREEN)

- [ ] Test describes behavior, not implementation.
- [ ] Test uses public interface only — no peeking at private methods or internal state.
- [ ] Test would survive renaming any internal function.
- [ ] Code is minimal for *this* test (no speculative features).
- [ ] Don't refactor while RED — get to GREEN first, then refactor with a green safety net.

## Build sequence (feature-level vertical slice, in this order — no skipping layers)

1. **Schema** — Database migration. Run upgrade and rollback to verify reversibility.
2. **Model** — ORM model. Verify any tenant/auth requirements.
3. **Schema (request/response)** — Pydantic / Zod / equivalent in the project's chosen validation library. Shared types in `packages/shared/` if needed by frontend.
4. **Service** — Business logic. **Apply TDD tracer-bullet cycles** (above): one failing test → minimal impl → next failing test. Each test focuses on one observable behavior. Don't draft all tests upfront.
5. **Router** — API endpoint with the proper authorization decorator and audit-log entry. **Same tracer-bullet rule** for integration tests: one integration test → impl → next.
6. **Worker** — Async task if the feature needs background work. Test with a stub broker. Tracer-bullet cycles.
7. **UI** — Data-fetching hook, page/component, form (if any). Add an end-to-end test (one tracer bullet for happy path, then one per critical edge case).
8. **Docs** — Update README if user-facing; update API docs if endpoint is new; update relevant `docs/` page. If the feature introduced a new domain term, update `CONTEXT.md` (canonical glossary).

After each layer, run `make quality` (lint + typecheck + tests + security). Don't proceed to the next layer if it's red. Don't refactor while RED inside a tracer-bullet cycle either — first get to GREEN, then refactor with the green tests as your safety net.

For each LLM call in the feature (if any), engage `ai-engineer`:
- Typed schema for output.
- System prompt + user prompt template.
- Retry-repair flow.
- Eval cases added to `ai/evals/`.

For each security-sensitive change, engage `security-architect`:
- Authorization test updated.
- Cross-tenant test still passes (if multi-tenant).
- No secrets in diff.
- Audit-log entry added.

Finishing:

1. Run the full `make quality` one more time. All green.
2. Run the relevant eval suite if you touched any AI-related path.
3. Update TASKS.md — mark the feature complete.
4. Update the spec status to `done`.
5. Generate a single commit message (Conventional Commits):
   - `feat(<scope>): <one-line summary>`
   - body lists what changed and references the spec slug.
6. Report:
   - Files changed.
   - Tests added.
   - ADRs added (if any).
   - Eval results (if applicable).
   - Any deferred follow-ups, with new TASKS.md entries created for them.

Do NOT push to a remote. Do NOT open a PR yourself. Wait for the human to review and run `gh pr create` themselves.
