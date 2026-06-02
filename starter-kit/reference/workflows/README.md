# Workflow recipes — the committed `Workflow()` library

Reusable, **profile-aware** Dynamic Workflow scripts. They propagate like `agents/` and `commands/`:
repo → `~/.claude/workflows/` (via `install.sh`) → each project's `.claude/workflows/` (via
`/sync-project`, and the `ai-project-scaffold` skill for new projects). A saved recipe **auto-registers
as a slash command `/<name>`**; project `.claude/workflows/` beats `~/.claude/workflows/` on a name clash.

> This `README.md` is for humans — `install.sh` excludes it from the synced `~/.claude/workflows/` so it
> never loads as a runnable workflow.

## The recipes

| Recipe | `/command` | Writes? | Quality pattern | Use for |
|---|---|---|---|---|
| `exhaustive-review` | `/review-exhaustive` | no | diverse lenses + adversarial verify | deep multi-lens review of the current diff |
| `codebase-map` | `/map-codebase` | no | multi-modal sweep + completeness critic | understand an unfamiliar repo |
| `security-sweep` | `/audit-security` | no | loop-until-dry + adversarial verify | whole-repo security audit |
| `design-panel` | *(by name)* | no | judge panel | choose between design approaches → ADR draft |
| `safe-migration` | *(by name)* | **yes** | worktree-isolated transform → verify | one big codemod across many files |
| `release-readiness` | *(by name)* | no | multi-modal sweep + completeness critic | pre-release go/no-go gate |
| `fast-dag-build` | *(by name)* | **yes** | DAG fan-out + self-verify + review lane | build a multi-domain feature fast, quality-first |

`safe-migration` and `fast-dag-build` are the only recipes that modify files; the rest are read-only.

## How to invoke

- **Slash command:** `/review-exhaustive`, `/audit-security`, `/map-codebase` (thin wrappers that
  forward the session profile). Any saved recipe is also callable as `/<its-name>`.
- **By name with args:** `Workflow({ name: 'design-panel', args: { problem: '…', mode: 'best' } })`.
- **Auto:** `/effort ultracode` lets Claude decide when a task warrants a workflow.

Workflows require **explicit opt-in** (the word "workflow", `/effort ultracode`, or running a saved
recipe) and cost meaningfully more tokens than a normal turn — scope before a wide run.

## Profiles — `args.mode` (`best` default / `saver`)

Every recipe reads `const MODE = (args && args.mode) || 'best'` and scales its depth:

| | **best** (default — max quality + speed) | **saver** (token-optimised) |
|---|---|---|
| fan-out width | full | narrow |
| adversarial skeptics / finding | 5 (Sonnet) | 1–2 (Haiku) |
| reviewer lenses / proposers | all | core subset |
| synthesis / final-verdict model | Opus | Sonnet |

Bulk leaves (skeptics, mechanical grind) run on Sonnet/Haiku in **both** modes — in `best` that's to
preserve the weekly **Opus cap**, not to cut token cost. Switch with `/mode best|saver` (sets the
session profile that wrappers forward) or pass `args.mode` directly. **Optional `max`:** for a one-off
where the cap doesn't matter, run `best` and bump reviewers/synthesis to Opus by editing the launched
script — not a shipped third profile.

## Authoring a new recipe

1. Start a run, then `/workflows` → select → press `s` → save to the **project** `.claude/workflows/`
   (shared on clone). To make it part of the kit, add it here in `starter-kit/reference/workflows/`.
2. Hard rules of the `Workflow()` runtime:
   - **`meta` must be a pure literal** — no template strings, calls, spreads, or variables, or the
     loader rejects it.
     ✅ `export const meta = { name: 'x', description: '…', phases: [{ title: 'A' }] }`
     ❌ `export const meta = { name: \`${pkg}\`, phases: PHASES }`
   - **Plain JavaScript**, not TypeScript. No `Date.now()` / `Math.random()` / argless `new Date()`.
   - ▲ **No filesystem, shell, or env access from the script.** Agents read/write/run commands; the
     script only coordinates. So **all configuration arrives via `args`** — never read a file, env var,
     or `process.cwd()`. Default a repo path to `'.'` and pass it into agent prompts.
   - ▲ **`args` arrives as a JSON _string_ on name-invocation** (verified), not an object. Always
     normalize at the top before reading fields, or `args.mode`/`args.problem` will silently be
     `undefined`:
     ```js
     let A = args
     if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
     if (!A || typeof A !== 'object') A = {}
     const MODE = A.mode || 'best'   // then read everything off A, never raw `args`
     ```
   - Default to `pipeline()`; use a `parallel()` barrier only when a stage needs all prior results.
   - Pass a `schema` to `agent()` for validated structured returns; pin `model`/`agentType` per stage.
3. Validate: `node --check <file>.js`, then confirm it lists in `/workflows` (the runtime parses `meta`
   without running the body — if it lists, the literal is valid).

See `docs/SWARM-ORCHESTRATION.md` (substrates) and `docs/BEST-PRACTICES.md` §6 (when to reach for a
recipe vs a one-off workflow vs a slash command).
