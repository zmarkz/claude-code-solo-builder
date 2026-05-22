---
description: Full design-first cycle for any UI feature — establish design system, generate distinctive UI direction, plan-review, build, and visual QA. Single entry point for UI work. Use instead of /build-feature when starting a new page, major component, or visual redesign.
argument-hint: <feature name or short description>
---

Run the full design-first cycle for: **$ARGUMENTS**

This command orchestrates the complete design → build → review pipeline so you don't have to manually chain skills. Work through each stage in order. Do not skip stages.

---

## Stage 1 — Design system check

Check if `DESIGN.md` exists at the project root.

- **Missing**: Tell the user: "No DESIGN.md found. Running `/design-consultation` now to establish the project's design system before we build anything." Invoke `/design-consultation`. It will interview you and produce `DESIGN.md` as the design source of truth. Do not proceed to Stage 2 until DESIGN.md exists.
- **Present**: Read it fully. Summarise the key decisions (typeface, palette, spacing, motion style) in one short paragraph — this is the constraint envelope for everything that follows.

If a Figma URL appears in `PROJECT_CONTEXT.md` or `CONTEXT.md`, note it — it will be used in Stage 4.

---

## Stage 2 — Aesthetic direction (frontend-design skill)

Invoke the `frontend-design` skill with:
1. The feature description: **$ARGUMENTS**
2. The DESIGN.md constraint summary from Stage 1.
3. The target audience / tone (pull from `PROJECT_CONTEXT.md` if available).

The skill will commit to a bold, distinctive aesthetic direction — typography choice, color application, layout approach, motion style. It is the creative brief for everything built in Stage 4.

**Do not skip this stage for new pages or major components.** For minor additions (single field, label tweak), you may skip Stage 2 and proceed directly to Stage 4.

---

## Stage 3 — Variant exploration (optional, high-value)

If the user wants to see options before committing:

> "Would you like to see multiple design variants before locking in one direction? If yes, I'll run `/design-shotgun` to generate a comparison board."

- **Yes**: Invoke `/design-shotgun`. Present variants. Ask the user to pick one. Use the selected variant's direction as the brief for Stage 4, overriding Stage 2's output if needed.
- **No / skip**: Proceed with the Stage 2 direction.

---

## Stage 4 — Plan review (plan-design-review)

Before any code is written, invoke `/plan-design-review` on the feature spec (from `docs/specs/$ARGUMENTS.md` or the Stage 2 brief if no formal spec exists).

It rates each design dimension 0–10 and rewrites the plan to reach higher scores. Incorporate its output into the implementation brief before proceeding.

If no formal spec exists, create a one-page brief at `docs/specs/<slug>-design-brief.md` with:
- User story
- Aesthetic direction (from Stage 2 or 3)
- DESIGN.md constraints
- Component inventory (what needs to be built)

---

## Stage 5 — Build

Invoke `/build-feature <slug>` with the design brief pre-loaded.

The `frontend-engineer` agent will:
- Build from the aesthetic direction established in Stages 2–4
- Use Figma MCP if a Figma URL was identified in Stage 1
- Apply TDD tracer-bullet cycles (per build-feature rules)
- Cover all four render states: loading, empty, error, success

---

## Stage 6 — Visual QA (design-review)

After implementation, invoke `/design-review` on the new page/component.

It will:
- Screenshot the current state
- Find visual inconsistencies, spacing errors, AI-slop patterns, hierarchy problems
- Fix each issue atomically with a commit per fix
- Produce a before/after comparison

Do not mark this feature done until `/design-review` has completed and its fixes are committed.

---

## Stage 7 — Accessibility check

Verify:
- [ ] All interactive elements have ARIA labels or visible text labels
- [ ] Keyboard navigation works (Tab order, Enter/Space on buttons)
- [ ] Focus rings are visible
- [ ] Color contrast meets WCAG AA (4.5:1 for normal text, 3:1 for large text)
- [ ] Skeletons/loading states don't cause layout shift

---

## Finishing

Report:
- `DESIGN.md` created or existing (and whether it was updated)
- Aesthetic direction chosen (one sentence)
- Files created / modified
- `/design-review` issues found and fixed (count)
- Accessibility issues found and fixed
- Spec file written to `docs/specs/`

Output: "Design-feature cycle complete for **$ARGUMENTS**. Ready for human review before ship."
