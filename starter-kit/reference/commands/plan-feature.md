---
description: Plan a feature end-to-end before writing code. Step 0 grills the user, then invokes product-manager for scoping and solution-architect for design.
argument-hint: <feature name or short description>
---

Plan the following feature: **$ARGUMENTS**

Workflow:

0. **Grilling phase (embedded `/grill-with-docs` protocol).** Before invoking any subagent, interview the user about this feature *one question at a time*. Cribbed from mattpocock/skills' `grill-with-docs`. If the user has Matt's skill installed at user-level, prefer that; otherwise run this embedded protocol:

   - **Read `CONTEXT.md` first.** Use only the terms defined there. If the user says a term that conflicts with the glossary, call it out immediately: *"CONTEXT.md defines X as Y, but you seem to mean Z — which is it?"*
   - **Ask one question at a time, with your recommended answer.** Wait for feedback before continuing. Walk down each branch of the design tree, resolving dependencies one by one.
   - **If a question can be answered by exploring the codebase, explore instead.** Use Read, Grep, Glob — don't ask the user things you can verify yourself.
   - **Sharpen fuzzy language.** When the user uses vague or overloaded terms, propose a precise canonical term and offer to add it to `CONTEXT.md`.
   - **Stress-test with concrete scenarios.** Invent scenarios that probe edge cases ("what about when a User has zero Orders?"). Force precision on boundaries.
   - **Cross-reference with code.** If the user states how something works and the code disagrees, surface the contradiction.
   - **Update `CONTEXT.md` inline** as terms are resolved. Don't batch them up.
   - **Offer ADRs sparingly** — only when *hard-to-reverse + surprising-without-context + result-of-real-trade-off* (the 3-test threshold from `examples/ADR-NNNN-template.md.example`). If you offer an ADR, draft it during this phase, not later.

   The grilling phase ends when you and the user agree the design tree has no unresolved branches. Capture the resolved understanding in a one-paragraph summary you'll hand to the PM in Step 2.

1. **Read context first.** `PROJECT_CONTEXT.md`, `CONTEXT.md`, the active phase in `ROADMAP.md`, the relevant section of `TASKS.md`, and the latest few files in `docs/adr/`.

2. **Launch `product-manager` subagent.** Hand it the grilling summary from Step 0. Ask it to produce the vertical-slice scoping document using the template in its system prompt:
   - Persona served + pain addressed.
   - Phase fit (current or future).
   - Vertical slice: schema → API → worker → UI → test → docs.
   - Acceptance criteria (one sentence each, testable).
   - Non-goals.
   - Estimated effort.
   - Open questions.

3. **Launch `solution-architect` subagent.** Hand it the PM output and ask for the design review using its template:
   - Fit with current architecture.
   - Components touched.
   - Trust boundaries crossed.
   - Trade-offs.
   - Decision + ADR draft if needed.

4. **If `security-architect` review is warranted** (auth, tenancy, storage, model call, or new endpoint), launch it next.

5. **If `domain-expert` review is warranted** (anything referencing a domain rule, standard, or regulation), launch it next.

6. **Consolidate.** Produce a single feature spec at `docs/specs/<feature-slug>.md` with:
   - Title, owner, phase, status (drafted / approved / in-progress / done).
   - **Grilling summary** (from Step 0) — what was unclear at the start, how it was resolved, which CONTEXT.md terms were touched.
   - PM scope.
   - Architect design.
   - Any ADRs drafted (linked, not inlined — they live at `docs/adr/NNNN-...md`).
   - Security review (if applicable).
   - Domain review (if applicable).
   - Tasks broken down into TASKS.md-ready entries.

7. **Update TASKS.md** with the new entries, blocked-by the spec being approved.

8. **Do NOT start implementing.** Wait for human approval of the spec before invoking `/build-feature`.

Output a one-paragraph summary at the end: "Spec written to `docs/specs/<slug>.md`. <N> tasks added to TASKS.md, blocked pending review. Approve to proceed."
