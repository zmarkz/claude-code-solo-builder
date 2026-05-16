# Matt Pocock's `skills` vs Our `ai-project-scaffold` — Comparison + Best-of-Both Recommendation

May 2026 — companion to FINAL-PLAYBOOK.md v2.1

---

## TL;DR (the recommendation)

These two approaches are **complementary, not competing**. Use ours as the *project skeleton* (one-time per project), and adopt Matt's atomic skills as the *daily workflow* (every session, every project). The pivotal additions: **CONTEXT.md as a DDD ubiquitous-language glossary** (not the same as our PROJECT_CONTEXT.md), **grill-with-docs before every change**, **per-file ADRs under `docs/adr/`** (replace our single DECISIONS.md), and **TDD as vertical tracer-bullet cycles, not horizontal "all tests then all code."**

Drop one of our patterns: the monolithic `DECISIONS.md` file. Add five of Matt's: `/grill-with-docs`, `/diagnose`, `/zoom-out`, `/improve-codebase-architecture`, `/handoff`. Keep our 11 specialized subagents and phase gates — Matt's approach has nothing equivalent and they earn their keep for serious work.

---

## What Matt's repo actually is

82,100 stars. The product of a senior TypeScript educator (Matt Pocock, Total TypeScript) who works inside Claude Code daily. Tagline: **"Skills for Real Engineers — not vibe coding."** His critique of GSD/BMAD/Spec-Kit/scaffold-generators (which includes ours): *they own the process and make bugs in the process hard to resolve*. His solution: small, composable, easy-to-adapt skills that work with any model.

**Skill inventory** (engineering bucket): `diagnose`, `grill-with-docs`, `triage`, `improve-codebase-architecture`, `setup-matt-pocock-skills`, `tdd`, `to-issues`, `to-prd`, `zoom-out`, `prototype`. **Productivity**: `caveman` (compress ~75% tokens), `grill-me`, `handoff`, `write-a-skill`. **Misc**: git-guardrails, pre-commit setup, two TS-specific tools.

**The four problems he addresses, each named with a citation:**
1. Misalignment (Pragmatic Programmer) → **grilling sessions**
2. Verbosity (Domain-Driven Design's "ubiquitous language") → **CONTEXT.md glossary**
3. Code doesn't work (Pragmatic Programmer's "small deliberate steps") → **TDD + diagnose**
4. Ball of mud (Beck, Ousterhout) → **`improve-codebase-architecture` weekly**

This is a senior engineer's framework, with every claim grounded in a canonical book.

---

## Head-to-head comparison

| Dimension | Matt Pocock's `skills` | Ours (`ai-project-scaffold`) |
|-----------|----------------------|------------------------------|
| **Philosophy** | Small composable atoms. You drive. | Comprehensive scaffold. The skill drives. |
| **Skill count** | ~15 atomic skills | 1 mega-skill that generates 11 agents + 9 commands + 6 hooks + 9 planning docs |
| **Granularity** | One skill = one task | One skill = a whole project's discipline |
| **Process ownership** | Explicitly rejects "owning the process" | Owns the process (phase gates, vertical-slice TDD, ADR-every-decision) |
| **Context strategy** | `CONTEXT.md` = DDD ubiquitous language (terms, "avoid" synonyms, relationships, flagged ambiguities) | `CLAUDE.md` (≤200 lines) + `PROJECT_CONTEXT.md` (the "why") — no glossary doc |
| **ADRs** | `docs/adr/NNN-<topic>.md` per file. Strict 3-test criterion: hard-to-reverse + surprising-without-context + real-trade-off | Single `DECISIONS.md` file. Threshold = "non-trivial decision" (looser) |
| **TDD** | `/tdd` skill: vertical tracer bullets (one test → one impl → repeat). Explicit anti-pattern callout against horizontal slicing. References "deep modules" (Ousterhout) | `/build-feature` enforces vertical slice schema→API→worker→UI→test→docs. Tests mandatory but "test-first or test-after" not specified per layer |
| **Specialized agents** | None. Claude is just Claude. | 11 agents (PM, solution-architect, security-architect, backend, frontend, ai, devops, qa, domain-expert, technical-writer, product-owner-reviewer) |
| **Phase model** | None. Work flows. | Strict phase gates with `/phase-review N` + human sign-off |
| **Pre-implementation discipline** | `/grill-me` or `/grill-with-docs` — relentless one-question-at-a-time interview, agent provides recommended answers, explores codebase, sharpens CONTEXT.md inline | `/plan-feature` — PM scopes → architect designs → security/domain if relevant → spec written |
| **Debugging** | `/diagnose` — explicit loop (reproduce → minimise → hypothesise → instrument → fix → regression-test) | No dedicated debug skill |
| **Architecture upkeep** | `/improve-codebase-architecture` — periodic refactor command using CONTEXT.md + ADRs | `solution-architect` agent reviews per change; no scheduled refactor pass |
| **Issue tracker integration** | Built-in (`/setup-matt-pocock-skills` picks GitHub/Linear/local; `/to-issues` and `/triage` use it) | TASKS.md only; no external tracker hook |
| **Bug-fix as feature** | `/to-prd` synthesizes current conversation into a PRD → GitHub issue | `/plan-feature` produces `docs/specs/<slug>.md`; no auto-PRD-to-issue |
| **Context compaction** | `/handoff` skill — human-readable handoff doc | `session-snapshot.sh` hook — machine-readable state dump on PreCompact |
| **Communication style** | `/caveman` skill (compress ~75% tokens) | Not addressed |
| **Codebase navigation** | `/zoom-out` — broader/higher-level explanation when in unfamiliar territory | No equivalent |
| **Prototyping** | `/prototype` — explicit "throwaway" mode (terminal app or multi-variant UI) | No equivalent (everything is a "real" project from Day 0) |
| **Meta-tooling** | `/write-a-skill` — meta-skill to author new skills | Implicit; no first-class skill-authoring command |
| **Security posture** | Light. `/git-guardrails-claude-code` blocks dangerous git commands. `/setup-pre-commit` for hygiene | Heavy. `security-architect` agent + `/review-security` + 10-point checklist + secret-scan hooks + deny/ask/allow perimeters + tenant-isolation + audit-log discipline |
| **Multi-tenancy / regulated work** | Not addressed | First-class (security profile = production-grade vs internal-tool vs personal-project; regulated → compliance/frameworks/) |
| **Parallelism** | Not addressed | Two bounded modes (`/build-phase-autopilot` sequential, `/start-phase-team` parallel teammates) |
| **Onboarding** | `npx skills@latest add mattpocock/skills` + `/setup-matt-pocock-skills` | Manual `mv` to `~/.claude/skills/` + invoke skill |
| **Validation** | 82k stars, public, community-tested | Custom-built, not yet field-tested |
| **Sweet spot** | Any project, any stack, daily workflow | Greenfield projects where discipline pays off (B2B SaaS, fintech, regulated) |

---

## Where each is clearly better

### Matt is better at:

1. **Atomic-skill granularity.** When something in your workflow breaks (the grill is too aggressive, the diagnose loop misses a step), you fix one tiny file. With our mega-scaffold, if `/build-feature` has a bug, you fix it once in the kit and 0 existing projects pick up the change (the kit is "one-time generator, not a live link" — by design). Matt's user-level skills update everywhere instantly.

2. **Grilling-before-doing as a habit.** `/grill-with-docs` is structured: one question at a time, with recommended answer, exploring the codebase as it goes, sharpening the glossary inline. Our `/plan-feature` jumps straight to PM scoping with no relentless-interview phase. We have an agent (`product-manager`) but not the grilling protocol.

3. **CONTEXT.md as DDD glossary.** This is the technique he says might be "the single coolest in the repo." It's not the same as our `PROJECT_CONTEXT.md`:
   - Ours: "the why — personas, market, non-goals, risks." A pitch deck in prose.
   - His: a glossary. "Issue tracker: the tool that hosts a repo's issues — GitHub Issues, Linear, .scratch/. *Avoid*: backlog manager, backlog backend." Plus relationships (cardinality) and flagged ambiguities (resolved historical confusion). A *dictionary* that the agent uses to challenge the user when they drift into fuzzy terms.
   
   This is genuinely missing from our approach and would help a lot.

4. **Per-file ADRs under `docs/adr/`.** ADRs are referenced by number forever; having them as one big file makes them hard to find, hard to link to, hard to supersede cleanly. Matt's convention (`0001-event-sourced-orders.md`, `0002-postgres-for-write-model.md`) is the industry default for a reason.

5. **The 3-test ADR threshold.** Our `solution-architect` is told to ADR "every non-trivial decision" — which is too loose. Matt's threshold: **hard-to-reverse + surprising-without-context + result-of-real-trade-off**. All three must be true. This produces 5–10 ADRs in a real project, not 50.

6. **TDD anti-pattern callout.** Our `/build-feature` says "write tests" but doesn't warn against horizontal slicing (write all tests, then all code). Matt's `/tdd` explicitly names this anti-pattern. Vertical tracer-bullet cycles produce dramatically better tests because each test responds to what you learned from the previous one.

7. **`/diagnose` as a structured debug loop.** When something's broken, you don't want general "fix it" prompts. You want: reproduce → minimise → hypothesise → instrument → fix → regression-test. We have no equivalent.

8. **`/improve-codebase-architecture` as a periodic ritual.** Codebases drift. A weekly refactor pass that references CONTEXT.md + ADRs catches deepening opportunities before they become rewrites.

9. **`/handoff` for human-readable continuity.** Our `session-snapshot.sh` dumps machine state (branch, HEAD, uncommitted, recent commits). That's the *log*, not the *handoff doc*. A handoff doc says "we're trying to fix the race in OrderService — Approach A failed because…; trying Approach B next." Resumable by a fresh session in seconds.

10. **`/caveman` for token economy.** Long sessions degrade. Compressing communication when not in a sensitive phase saves real money and keeps the context window healthy.

### We are better at:

1. **Specialized subagents with codified working rules.** Matt has zero. We have `security-architect` with a 10-point security checklist, `qa-engineer` with a 10-item adversarial test catalog, `product-owner-reviewer` with the demoability check. These are *force multipliers* on day-to-day work — the equivalent of having a specialist on the team. Matt's approach assumes you'll bring that expertise yourself.

2. **Phase gates with explicit human checkpoints.** No autopilot self-approves a phase. The `product-owner-reviewer` produces a one-page exec summary; you sign by editing the markdown. Matt's approach is more "trust the engineer" — fine for solo TS work, dangerous for B2B SaaS where regressions hurt customers.

3. **Production-grade security posture by default.** Settings.json deny/ask/allow perimeter; secret-scan as PreToolUse hook; security-architect agent reviews any auth/tenancy/storage/LLM-touch change. Matt's repo has `/git-guardrails-claude-code` but it's a narrower scope (just git).

4. **Multi-tenancy and audit-log discipline baked in.** Every model has `tenant_id`. Every state change writes an `audit_log` row (actor, tenant, resource, action, before/after hash). Cross-tenant test is mandatory. These are non-negotiables for B2B SaaS that Matt's repo doesn't touch.

5. **Bounded parallelism.** `/build-phase-autopilot` for sequential chained autonomy with a per-slug commit log; `/start-phase-team` for parallel teammates with non-overlapping file domains and security-reviewer veto. Matt's repo doesn't address parallelism at all.

6. **Domain-expert agent with citation requirements** for regulated work (fintech, healthcare, legal). "Aligned with X" not "certified by X." Version every corpus entry. Don't answer professional-advice questions.

7. **Settings.json as a first-class security perimeter.** Three layers (deny / ask / allow) tuned for production-grade. Matt's repo doesn't ship a settings template — every project is on its own.

---

## Where Matt's critique applies to us (acknowledged)

Matt's main critique of "frameworks that own the process" is fair against our `ai-project-scaffold`. Two real issues:

1. **One-shot generation, no live link.** Our README says "the scaffold is a one-time generator, not a live link" — explicitly. If we improve a hook script in the kit, no existing project picks it up. Matt's user-level skills update everywhere instantly. **This is a real downside that we should address.**

2. **Hard to debug when the process is wrong.** With 11 agents + 9 commands + 6 hooks generated at once, a bug in any of them is a bug in every project scaffolded from that point on. Matt's small composable atoms are debuggable in isolation.

The fix is *not* to throw away our scaffold-generator. The fix is to ship the kit AND ship its components as user-level atomic skills, so:
- New projects use the scaffold for a fast 0→1.
- The scaffold's components (the 11 agents, the 6 hooks) also live as user-level skills, so improvements propagate to every project that uses them.

---

## The recommended hybrid approach (7 actionable changes)

### 1. Adopt CONTEXT.md as a first-class doc, distinct from PROJECT_CONTEXT.md

Add `CONTEXT.md` to the planning docs the scaffold generates. Body is a DDD ubiquitous-language glossary with three sections (cribbed from Matt's repo):

```markdown
# <project-name>

## Language
**<term>**: <definition>. <one-line example use>.
*Avoid*: <ambiguous synonyms>

## Relationships
- A **<term-A>** has many **<term-B>**.
- A **<term-B>** belongs to one **<term-A>**.

## Flagged ambiguities
- "<old-term>" was previously used to mean X and Y — resolved: <decision>.
```

PROJECT_CONTEXT.md stays as the "why and personas" doc. CONTEXT.md is the glossary. The two complement each other.

Update the `solution-architect`, `product-manager`, and `domain-expert` agents to read CONTEXT.md before any non-trivial response and to call out drift from it ("Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?").

### 2. Replace `DECISIONS.md` with `docs/adr/NNN-<topic>.md`

Single file → one file per ADR. Pros: searchable by number, easy to supersede ("Superseded by ADR-0014"), easy to link to from code comments, cleaner git history per decision. Update `solution-architect` agent's job description and the `/write-adr` workflow.

Also adopt Matt's 3-test threshold for *when* to ADR:
- **Hard to reverse** — the cost of changing your mind later is meaningful, AND
- **Surprising without context** — a future reader will wonder "why did they do it this way?", AND
- **Result of a real trade-off** — there were genuine alternatives.

If any is missing, skip the ADR. Today our agents over-ADR; this fixes it.

### 3. Add `/grill-with-docs` as the front door of `/plan-feature`

Currently `/plan-feature` jumps to PM scoping. Restructure:

```
/plan-feature <name>
  → /grill-with-docs (relentless interview, sharpens CONTEXT.md, drafts ADRs sparingly)
  → product-manager (vertical-slice scoping)
  → solution-architect (design review + ADRs if warranted)
  → security-architect (if auth/tenancy/storage/LLM)
  → domain-expert (if regulated)
  → consolidate into docs/specs/<slug>.md
```

The grilling phase is small (~80 lines of prompt) and dramatically improves every downstream step. We get this benefit at very low cost.

### 4. Adopt Matt's TDD philosophy in `/build-feature`

Two specific changes to our `/build-feature` command:

(a) Add an anti-pattern callout: **never write all tests then all code**. Vertical tracer-bullet cycles: one test → minimal impl → next test. Each test responds to what you learned from the previous cycle.

(b) For the service-layer step (currently "Write the test first, then the implementation"), expand to a full red-green-refactor with the "checklist per cycle":
- Test describes behavior, not implementation.
- Test uses public interface only.
- Test would survive internal refactor.
- Code is minimal for this test.
- No speculative features added.

This makes our tests more durable (don't break on refactor) and our implementations leaner.

### 5. Add 5 atomic skills as user-level (`~/.claude/skills/`)

Install these from Matt's repo verbatim, no changes:

- `/grill-with-docs` — pre-implementation interview
- `/diagnose` — debug loop
- `/zoom-out` — unfamiliar-code orientation
- `/improve-codebase-architecture` — weekly refactor pass
- `/handoff` — human-readable session compaction
- (optional) `/caveman` — token compression mode

These augment our project-level commands. The split is principled: **project-level commands operate on this project**; **user-level skills operate on whatever I'm doing right now**.

### 6. Add `/prototype` to the kit (or as a user-level skill)

Currently every scaffolded project is a "real" project. Sometimes you want to explore an idea before committing to the scaffold. Matt's `/prototype` (throwaway runnable terminal app for state/logic, or several radically different UI variations) is the right tool for that.

Add it as a user-level skill. Don't generate it into every project (the discipline of phase gates doesn't apply to throwaways).

### 7. Make the scaffold's components dual-resident

Today: `~/.claude/skills/ai-project-scaffold/reference/agents/security-architect.md` → copied at scaffold time into `<project>/.claude/agents/security-architect.md`. No link.

Better: ALSO install the agents as user-level (`~/.claude/agents/security-architect.md`). Per-project overrides win when both exist, but unmodified projects pick up upstream improvements. The kit becomes a starter snapshot, not a permanent fork.

Do the same for the 6 hook scripts. Per-project overrides win; default behavior comes from upstream.

This single change addresses Matt's "one-shot generator, not a live link" critique without throwing away the scaffold-generator approach.

---

## What NOT to adopt from Matt

Three of Matt's positions don't apply to our context:

1. **"Reject specialized agents."** Matt assumes you bring senior-engineer judgment. If you're solo and the product is B2B SaaS with auth/payments/multi-tenancy, you can't be a security architect, a QA engineer, AND a backend engineer simultaneously. Our specialized agents codify those roles' working rules — they're cheap to invoke and they catch what generalists miss. Keep them.

2. **"Reject phase gates."** Matt's flow assumes continuous incremental delivery. Our phase gates exist because a solo builder needs an explicit "stop and demo / sign off" rhythm — otherwise scope creeps until the project drowns. Keep `/phase-review` with human signature.

3. **"Issue tracker as central state."** Matt's `/to-issues` and `/triage` assume issues are the source of truth. For solo builders managing multiple projects, the **portfolio tracker** (one Supabase row per app) is the source of truth at the portfolio level; TASKS.md at the project level. GitHub Issues are noise unless you have collaborators. Don't adopt his issue-tracker-centric flow unless you're collaborating.

---

## The merged daily workflow (what it looks like)

**Starting a new app:**
```
mkdir ~/projects/voice-notes && cd ~/projects/voice-notes
claude
> "Scaffold this with ai-project-scaffold. It's <one-liner>."
# 11 questions, 10 minutes — kit generates planning docs + agents + commands + hooks
```

**Daily, inside the project:**
```
claude
> /start-session                      # our skill — re-loads CLAUDE.md + active phase
> /grill-with-docs <vague idea>       # Matt's — sharpens CONTEXT.md, drafts ADRs sparingly
> /plan-feature <slug>                 # our skill — PM + architect + security + spec
# human approves spec
> /build-feature <slug>                # our skill — vertical-slice TDD (with Matt's tracer-bullet philosophy)
# bug appears
> /diagnose                            # Matt's — reproduce → minimise → hypothesise → fix
# end of day
> /handoff                             # Matt's — human-readable doc for tomorrow's session
```

**Weekly:**
```
> /improve-codebase-architecture       # Matt's — finds deepening opportunities
> /run-qa phase                        # our skill — full eval + adversarial cases
```

**End of phase:**
```
> /phase-review N                      # our skill — product-owner-reviewer + human sign-off
```

That's the merged shape. We keep our discipline (phase gates, specialized agents, security posture); we add Matt's per-task atomicity (grill, diagnose, zoom-out, handoff, improve-architecture); we adopt his two best documentation patterns (CONTEXT.md as glossary, per-file ADRs).

---

## Migration plan (concrete next moves)

In the order I'd do them:

1. **Add a `CONTEXT.md` template** to `_starter-kit/examples/CONTEXT.md.example`. Reference Matt's repo's `CONTEXT.md` as the canonical example.
2. **Update `SKILL.md` Step 4** to generate `CONTEXT.md` alongside the other planning docs.
3. **Update agents** (`product-manager`, `solution-architect`, `domain-expert`) to read CONTEXT.md and call out drift.
4. **Replace `DECISIONS.md`** in `SKILL.md` Step 4 with `docs/adr/0000-template.md`. Update `solution-architect`'s ADR template + 3-test threshold.
5. **Restructure `/plan-feature`** to invoke `/grill-with-docs` first. (Either embed the grilling logic or call out to the skill if installed.)
6. **Add the TDD anti-pattern callout** to `/build-feature` (Matt's vertical-tracer-bullet warning + per-cycle checklist).
7. **Install 5 of Matt's skills user-wide** via `npx skills@latest add mattpocock/skills`, picking: grill-with-docs, diagnose, zoom-out, improve-codebase-architecture, handoff.
8. **Add `/prototype`** as a user-level skill from Matt's repo (don't bundle into project scaffolds).
9. **Make scaffold components dual-resident** — also install the 11 agents + 6 scripts at user level so future kit improvements propagate.
10. **Update FINAL-PLAYBOOK.md** with these decisions as an ADR in the playbook's own changelog. Version bump to v2.2.

Estimated effort: 4–6 hours of editing + 30 min installing Matt's skills. Net result: the discipline of our kit + the daily ergonomics of Matt's atoms + the two best documentation patterns from DDD.

---

## Closing thought

Matt is right that frameworks owning the process is a real cost. We're right that solo builders shipping B2B SaaS need codified specialist judgment (security-architect, qa-engineer, product-owner-reviewer) that Matt's repo doesn't provide. The merge isn't a compromise — it's a strictly larger toolkit, because the two approaches operate at different layers:

- **Matt operates at the session/task layer** — what to do *right now*.
- **Ours operates at the project layer** — what to set up *once, so right-now works*.

Add CONTEXT.md as a glossary, switch to per-file ADRs, and you have what neither approach has alone: a scaffolded production-grade project where every daily action is supported by a small composable skill the agent can invoke without instructions.

That's the system worth running.

---

## References

- mattpocock/skills repository — https://github.com/mattpocock/skills (82.1k stars, MIT)
- Matt's `CONTEXT.md` — concrete example of DDD ubiquitous-language doc — https://github.com/mattpocock/skills/blob/main/CONTEXT.md
- `grill-with-docs/SKILL.md` — the grilling protocol — https://github.com/mattpocock/skills/blob/main/skills/engineering/grill-with-docs/SKILL.md
- `tdd/SKILL.md` — vertical tracer-bullet TDD with anti-patterns — https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md
- Evans, "Domain-Driven Design" — ubiquitous language pattern
- Ousterhout, "A Philosophy of Software Design" — deep modules
- Beck, "Extreme Programming Explained" — "invest in design every day"
- Thomas & Hunt, "The Pragmatic Programmer" — small deliberate steps, tracer bullets
- Our FINAL-PLAYBOOK.md v2.1 — `~/Documents/claude/Projects/solo-ai/FINAL-PLAYBOOK.md`
