# Changelog — ai-project-scaffold

All notable changes to this skill, newest first. Each entry pairs with an ADR-style rationale in the workspace's `COMPARISON-mattpocock-vs-ours.md`.

---

## [2.1] — 2026-07-18

**Theme:** Local RAG + cross-project module reuse (repo v3.1). See `docs/adr/0004-local-rag-leann.md` and `docs/LOCAL-RAG.md`.

### Added

- **`reference/scripts/rag-reindex.sh`** (10th guardrail script) — PostToolUse Write|Edit hook: debounced background incremental rebuild of the project's local LEANN index; dormant until `/rag-init`.
- **`reference/commands/rag-init.md` + `rag-status.md`** — build/retrofit the index (graceful degradation, never blocks) and read-only health check.
- **`reference/commands/extract-pattern.md` + `write-adr.md`** — the pattern library (`~/.claude/patterns/`, indexed for reuse search, vault-mirrored when module on) and per-file ADR skill. Command count 18 → 22.
- **Scaffold Q12 + Step 6.5** — "Local RAG index?" (default yes, opt-out); build usually defers to `/rag-init` after the first commit.
- **Reuse loop** — `/plan-feature` Step 0.6 searches pattern library + all project indexes before scoping a new module; `/build-feature` pre-flight reuse guard; CLAUDE.md example ships the "search before you grep" rule.
- **`session-start.sh`** — RAG-index freshness warning (behind HEAD / not initialized).
- **`.gitignore.template`** — `.leann/` (machine-local, rebuildable).
- **`reference/settings.json.template`** — rag-reindex PostToolUse hook entry.

## [2.0] — 2026-07-18

**Theme:** Public/private split (repo v3.0) — the kit is now fully generic and portable. See `docs/adr/0003-public-private-overlay-split.md`.

### Changed

- **All agent `model:` frontmatter and workflow-recipe model constants** switched from pinned IDs (`claude-sonnet-4-6`, `claude-opus-4-8`, `claude-haiku-4-5-20251001`) to tier aliases (`sonnet`, `opus`, `haiku`) — retired-model hard-failures are structurally eliminated.
- **`fast-dag-build.js`** commit trailer is now model-neutral (`Co-Authored-By: Claude`).
- **`commands/vault-update.md` and `commands/start-session.md`** — vault steps now gate on the optional vault module (`VAULT_PATH` in `~/.claude/solo-builder.config`) and use `$VAULT_PATH` instead of a hardcoded Obsidian path; `start-session` now reads `docs/adr/` (per-file ADRs) instead of the retired `DECISIONS.md`.

### Removed

- **`platform-scripts/`** — the personal automation scripts (kg-reindex, vault-write-hook, ccc launcher, fleet digest) moved to the author's private overlay repo. The two generic session-check scripts moved to the repo's top-level `scripts/`, install to `~/.claude/scripts/`, and are parameterized via `solo-builder.config`.

**Theme:** Agent quality pass — model routing, proactive trigger language, tool access bug fixes, and `/write-an-agent` skill for domain customisation.

### Added

- **`reference/commands/write-an-agent.md`** — New skill that interactively generates a filled-in `domain-expert.md` for any domain (interviews on regulations, terminology, sources, prohibited claims) and can also generate custom specialist agents not in the base 11 (e.g., `mobile-engineer`, `data-analyst`). Installs to project and/or user level.
- **`model:` frontmatter on all 11 agents** — Opus for `security-architect` + `solution-architect` (high-stakes, hard-to-reverse decisions); Haiku for `product-manager` + `technical-writer` (structured output, lightweight reasoning, 10-20× cheaper); Sonnet for the remaining 7.
- **Proactive trigger + SKIP clauses on all 9 passive agents** — `description:` fields now include "Invoke proactively when…" and "SKIP for…" language so Claude's auto-invocation logic has clear signals. Previously only `security-architect` had this.
- **`docs/AGENTS-GUIDE.md` — Model routing table** — Documents which model runs each agent and why.
- **`docs/AGENTS-GUIDE.md` — `/write-an-agent` section** — Explains when and how to use the new skill.

### Added (continued)

- **`reference/commands/sync-project.md`** — Single entry-point command unifying all three project onboarding flows. Probes cwd, classifies as NEW / SYNC / RETROFIT, confirms with the user, executes the right subset of steps. Replaces the need to know which manual procedure to run.
  - **NEW** → delegates to `/ai-project-scaffold`
  - **SYNC** → overwrites `.claude/agents/` from `~/.claude/agents/`; optionally syncs commands; offers `/write-an-agent`
  - **RETROFIT** → asks project bucket (active-build / validate / stabilize / keep-as-is); installs the correct agent/command/hook/doc subset; runs `/vault-update`
- **`docs/EXISTING-PROJECT.md`** — Added TL;DR section at top pointing to `/sync-project`.

### Fixed

- **`security-architect` tool access bug** — Had `tools: Read, Grep, Glob, Bash` but its output format says "save to `docs/adr/NNNN.md`" — impossible without Write. Added `Write, Edit`.
- **`product-owner-reviewer` tool access bug** — Same issue: output format says "save to `docs/phase-reviews/phase-N.md`" but had no Write access. Added `Write, Edit`.

### Deferred

- `ai-engineer.md` Python→TypeScript file layout fix (planned for next phase — the file currently references `.py` paths which don't match the `~/builds/` Next.js + TypeScript stack).

---

## [1.1] — 2026-05-16

**Theme:** Merge with `mattpocock/skills` patterns. Cribbed atomic-skill ergonomics without giving up our specialized-agent / phase-gate discipline.

### Added

- **`examples/CONTEXT.md.example`** — DDD ubiquitous-language glossary template. Distinct from `PROJECT_CONTEXT.md` (which is the "why"). Has three sections: `Language` (canonical terms with `*Avoid*` synonyms), `Relationships` (entity cardinality), `Flagged ambiguities` (resolved historical confusions). Agents read it on every non-trivial response and challenge drift.
- **`examples/ADR-NNNN-template.md.example`** — Per-file ADR template with the 3-test threshold (`hard-to-reverse + surprising-without-context + result-of-real-trade-off`). Numbering monotonic, never reused. Old wrong ADRs get superseded by a new ADR, not edited.
- **Grilling phase (Step 0) in `commands/plan-feature.md`** — Embedded `/grill-with-docs` protocol that runs before PM scoping: one question at a time with recommended answers, sharpens `CONTEXT.md` inline, drafts ADRs sparingly. Falls back to Matt Pocock's `/grill-with-docs` user-level skill if installed.
- **TDD anti-pattern callout in `commands/build-feature.md`** — Explicit warning against horizontal test-batching (write all tests, then all code). Requires vertical tracer-bullet cycles per layer (one failing test → minimal impl → next test) with a per-cycle checklist (behavior-not-implementation, public-interface-only, would-survive-refactor, minimal-code, no-speculative-features). Cribbed from Matt Pocock's `tdd` skill.
- **Dual-residency installation** in `README.md` and `SKILL.md` — instructs users to also copy `reference/agents/*` and `reference/commands/*` to `~/.claude/agents/` and `~/.claude/commands/` so upstream improvements propagate to unmodified projects automatically. Per-project overrides win when both exist.
- **Companion-skill recommendation** — `npx skills@latest add mattpocock/skills`, picking `grill-with-docs`, `diagnose`, `zoom-out`, `improve-codebase-architecture`, `handoff` (plus optionally `caveman`, `prototype`). The kit owns the project layer; these own the session layer.

### Changed

- **`reference/agents/solution-architect.md`** — Now reads `CONTEXT.md` first. Writes per-file ADRs at `docs/adr/NNNN-<slug>.md` instead of appending to a single `DECISIONS.md`. Applies the 3-test threshold to decide whether to ADR at all. Output format updated to reference the per-file ADR template.
- **`reference/agents/product-manager.md`** — Reads `CONTEXT.md` before scoping. Writes all acceptance criteria using canonical glossary terms. Calls out stakeholder drift from defined terms.
- **`reference/agents/domain-expert.md`** — Now owns `CONTEXT.md` for its domain. Proposes new terms; resolves ambiguities by adding to `## Flagged ambiguities` (never silent overwrites).
- **`SKILL.md` Step 4 (planning docs table)** — Added `CONTEXT.md` row; replaced `DECISIONS.md` row with `docs/adr/NNNN-<slug>.md + docs/adr/INDEX.md` row. Updated descriptions to call out v1.1 changes inline.
- **`SKILL.md` Step 7 (verification)** — Added checks for `CONTEXT.md` exists and `docs/adr/INDEX.md` exists.
- **`SKILL.md` `After the scaffold runs`** — Added dual-residency and companion-skill subsections.
- **`README.md` Install section** — Now a 3-step install: skill itself, dual-residency copy, companion atomic skills via npx.
- **`README.md` Versioning table** — Bumped to 1.1 with merge notes.

### Removed

- Nothing yet. The single `DECISIONS.md` doc is *conceptually* replaced by `docs/adr/`, but the SKILL.md generation step now emits the new layout — projects scaffolded under v1.0 keep their `DECISIONS.md` until migrated (manual move: split each section into its own `docs/adr/NNNN-<slug>.md`, build an `INDEX.md`).

### Migration for v1.0-scaffolded projects (optional)

If you have projects scaffolded under v1.0 and want to adopt v1.1 doctrine without re-scaffolding:

1. Run the dual-residency install (above) so future agent improvements propagate.
2. Create `CONTEXT.md` at project root — start with 1 term, grow lazily.
3. Convert `DECISIONS.md`:
   ```
   mkdir -p docs/adr
   # for each ADR section in DECISIONS.md, create docs/adr/NNNN-<slug>.md
   # then create docs/adr/INDEX.md with one-liners pointing to each
   # then remove DECISIONS.md (or git-mv it to docs/adr/ARCHIVED-decisions.md)
   ```
4. Update your project's `CLAUDE.md` to reference `CONTEXT.md` and `docs/adr/` instead of `DECISIONS.md`.

---

## [1.0] — 2026-05-16

Initial release. 11 agents, 9 commands, 6 hook scripts, agent-teams support (Claude Code v2.1.32+), settings.json deny/ask/allow perimeter, phase-gate discipline, vertical-slice feature build, ADR-every-decision, security-architect with 10-point checklist, qa-engineer with 10-item adversarial catalog, product-owner-reviewer end-of-phase sign-off, two bounded parallelism modes (autopilot + agent-team).
