/**
 * fast-dag-build — reusable fast, quality-first build workflow.
 *
 * Encodes the STRUCTURE that makes a multi-domain build fast WITHOUT cutting quality:
 *   Wave 0 (foundation, barrier) → Wave 1 (wide implementation fan-out, self-verifying)
 *   → Reviews (parallel adversarial lane) → QA (parallel) → Final (full verify + code review + product-owner).
 * Speed comes from the DAG + self-verifying implementers + a parallel review lane — NOT from shrinking
 * prompts. Every agent reads the FULL plan files (quality-first).
 *
 * Invoke:  Workflow({ name:'fast-dag-build', args:{ ...see shape below... } })
 *
 * args (all optional except wave1):
 * {
 *   slug, branch,                 // labels (you should already be on the branch)
 *   repoPath: '.',                // repo root passed to agents (the runtime has no cwd)
 *   mode: 'best'|'saver',         // 'best' (default) → Opus final review; 'saver' → Sonnet
 *   planFiles: ['/abs/plan.md'],  // read IN FULL by every agent — do not trim
 *   brief: 'one-paragraph what & why',
 *   commit: true,
 *   finalVerify: 'make quality',  // full verify run once at the end
 *   wave0:     [ { label, agentType, prompt } ],   // migrations + shared types (parallel; barrier before wave1)
 *   wave1:     [ { label, agentType, prompt } ],   // implementation across DISJOINT domains (parallel, self-verify)
 *   reviewers: [ { key, agentType, prompt } ],     // parallel review lane (read-only); blockers→one fix pass
 *   qa:        [ { label, agentType, prompt, review } ],
 *   final:     true               // run full code-review + product-owner verdict
 * }
 *
 * Quality gates that must NOT be removed: adversarial security review on write/secret paths,
 * role-matrix QA, fail-closed verification, no-merge-without-review.
 */

export const meta = {
  name: 'fast-dag-build',
  description: 'Reusable fast-DAG build: foundation → wide self-verifying implementation → parallel adversarial reviews → QA → final review + product-owner verdict.',
  phases: [
    { title: 'Wave 0 — Foundation' },
    { title: 'Wave 1 — Implement' },
    { title: 'Reviews' },
    { title: 'QA' },
    { title: 'Final' },
  ],
}

let A = args
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
const SLUG = A.slug || 'build'
const REPO = A.repoPath || '.'
const MODE = A.mode || 'best'
const SAVER = MODE === 'saver'
const PLAN_FILES = Array.isArray(A.planFiles) ? A.planFiles : []
const WAVE0 = Array.isArray(A.wave0) ? A.wave0 : []
const WAVE1 = Array.isArray(A.wave1) ? A.wave1 : []
const REVIEWERS = Array.isArray(A.reviewers) ? A.reviewers : []
const QA = Array.isArray(A.qa) ? A.qa : []
const DO_FINAL = A.final !== false
const FINAL_VERIFY = A.finalVerify || 'make quality'
const FINAL_MODEL = SAVER ? 'claude-sonnet-4-6' : 'claude-opus-4-8'

const REVIEW_SCHEMA = { type: 'object', additionalProperties: false, required: ['verdict', 'findings', 'summary'], properties: {
  verdict: { type: 'string', enum: ['pass', 'changes', 'block'] },
  findings: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['severity', 'area', 'detail'], properties: {
    severity: { type: 'string', enum: ['blocker', 'major', 'minor'] }, area: { type: 'string' }, detail: { type: 'string' }, file: { type: 'string' } } } },
  summary: { type: 'string' } } }
const IMPL_SCHEMA = { type: 'object', additionalProperties: false, required: ['summary', 'filesChanged', 'typecheckedOk', 'followups'], properties: {
  summary: { type: 'string' }, filesChanged: { type: 'array', items: { type: 'string' } },
  testsAdded: { type: 'array', items: { type: 'string' } }, typecheckedOk: { type: 'boolean' }, followups: { type: 'array', items: { type: 'string' } } } }
const FINAL_SCHEMA = { type: 'object', additionalProperties: false, required: ['recommendation', 'greenTypecheck', 'phaseStatus', 'remainingGaps', 'execSummary'], properties: {
  recommendation: { type: 'string' }, greenTypecheck: { type: 'boolean' }, greenTests: { type: 'string' },
  phaseStatus: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['area', 'status'], properties: { area: { type: 'string' }, status: { type: 'string' }, note: { type: 'string' } } } },
  remainingGaps: { type: 'array', items: { type: 'string' } }, execSummary: { type: 'string' } } }

// Full-context base prepended to EVERY agent prompt (quality-first: read the whole plan).
const CTX = [
  `Repo: ${REPO}.${A.branch ? ` You are on branch ${A.branch} (already checked out) — do NOT switch branches; do NOT commit (a dedicated step commits).` : ' Do NOT switch branches or commit unless told.'}`,
  PLAN_FILES.length ? `BEFORE editing, READ IN FULL (do not skim — the verified facts and locked decisions matter): ${PLAN_FILES.join(', ')}.` : '',
  A.brief ? `Brief: ${A.brief}` : '',
  `Follow the project's CLAUDE.md conventions (root and any package-level CLAUDE.md). CRITICAL: edit ONLY files in YOUR assigned domain — sibling agents run concurrently on the same tree, so collisions corrupt the build.`,
].filter(Boolean).join('\n')

const SELF_VERIFY = '\nWhen done editing: run the typecheck for YOUR package (e.g. `pnpm --filter <pkg> typecheck`, or the project equivalent) and fix any type errors you introduced. Do NOT return until your package typechecks clean — own your own correctness.'

function implThunks(items, phaseName) {
  return items.map((t, i) => () => agent(
    `${CTX}\n${t.prompt}${SELF_VERIFY}`,
    { label: t.label || `${SLUG}:${phaseName}:${i}`, phase: phaseName, agentType: t.agentType, schema: IMPL_SCHEMA }))
}

async function reviewLane(items, phaseName, fixPhaseName) {
  if (!items.length) return { reviews: [], must: 0 }
  const reviews = (await parallel(items.map(r => () => agent(
    `${CTX}\n${r.prompt}\nReview ONLY the changes on this branch (\`git diff main...HEAD\` + uncommitted working tree). Be adversarial; default unclear security/consent/write paths to a finding. Return verdict + findings (blocker|major|minor).`,
    { label: `review:${r.key || r.label || phaseName}`, phase: phaseName, agentType: r.agentType, schema: REVIEW_SCHEMA })))).filter(Boolean)
  const must = reviews.flatMap(rv => (rv.findings || []).filter(f => f.severity === 'blocker' || f.severity === 'major'))
  if (must.length) {
    await agent(`${CTX}\nADDRESS these blocking/major review findings:\n${must.map(b => `[${b.severity}] ${b.area}: ${b.detail} ${b.file || ''}`).join('\n')}\nFix surgically; keep affected packages' typecheck green.${SELF_VERIFY}`,
      { label: `review-fix:${fixPhaseName || phaseName}`, phase: fixPhaseName || phaseName })
  }
  return { reviews, must: must.length }
}

async function commitWave(name, msg) {
  if (!A.commit) return null
  return agent(`Repo ${REPO}${A.branch ? ` on branch ${A.branch}` : ''}. COMMIT "${name}". Run: \`git add -A && git reset -q -- .claude 2>/dev/null; git commit -m "<<<MSG>>>"\` where the message is exactly:\n${msg}\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>\nDo NOT stage .claude or any *.temp. If a pre-commit hook blocks (secret-scan/typecheck), report what blocked; do NOT use --no-verify. Return a one-line status.`,
    { label: `commit:${name}`, phase: name })
}

if (!WAVE1.length) {
  log('fast-dag-build: no `wave1` tasks in args — nothing to build. Pass args per the header doc-block.')
  return { error: 'no wave1 tasks provided', usage: "Workflow({ name:'fast-dag-build', args:{ wave1:[...], ... } })" }
}

// ---- Wave 0: foundation (migrations + shared types). Barrier — consumers depend on these. ----
if (WAVE0.length) {
  phase('Wave 0 — Foundation')
  log(`Wave 0: ${WAVE0.length} foundation task(s) in parallel`)
  await parallel(implThunks(WAVE0, 'Wave 0 — Foundation'))
  await commitWave('Wave 0 — Foundation', `chore(${SLUG}): foundation — migrations + shared types`)
}

// ---- Wave 1: wide implementation fan-out across disjoint domains, each self-verifying. ----
phase('Wave 1 — Implement')
log(`Wave 1: ${WAVE1.length} implementation task(s) fanned out (self-verifying)`)
await parallel(implThunks(WAVE1, 'Wave 1 — Implement'))
await commitWave('Wave 1 — Implement', `feat(${SLUG}): implementation across domains`)

// ---- Reviews: parallel adversarial lane (after wave 1; blockers → one fix pass). ----
let reviewResult = { reviews: [], must: 0 }
if (REVIEWERS.length) {
  phase('Reviews')
  log(`Reviews: ${REVIEWERS.length} specialist reviewer(s) in parallel`)
  reviewResult = await reviewLane(REVIEWERS, 'Reviews')
  await commitWave('Reviews', `fix(${SLUG}): address review findings`)
}

// ---- QA: role-matrix tests + verification (parallel). review:true items feed a fix pass. ----
let qaResult = { reviews: [], must: 0 }
if (QA.length) {
  phase('QA')
  const qaImpl = QA.filter(q => !q.review)
  const qaRev = QA.filter(q => q.review)
  log(`QA: ${qaImpl.length} test-authoring + ${qaRev.length} verification task(s)`)
  if (qaImpl.length) await parallel(implThunks(qaImpl, 'QA'))
  if (qaRev.length) qaResult = await reviewLane(qaRev, 'QA', 'QA')
  await commitWave('QA', `test(${SLUG}): role-matrix tests + verification`)
}

// ---- Final: full verify once + full-diff code review + product-owner verdict. ----
if (!DO_FINAL) {
  return { mode: MODE, reviewBlockersFixed: reviewResult.must, qaBlockersFixed: qaResult.must }
}
phase('Final')
log('Final: full-diff code review + product-owner verdict + full verify')
const cr = await agent(`${CTX}\nFULL-DIFF CODE REVIEW (\`git diff main...HEAD\`). Hunt correctness bugs, fail-open security/consent paths, SQL/RLS issues, reuse/simplification misses, and any 'any' without justification. Return verdict + findings.`,
  { label: 'final:code-review', phase: 'Final', model: FINAL_MODEL, schema: REVIEW_SCHEMA })
const crMust = (cr && cr.findings ? cr.findings.filter(f => f.severity === 'blocker' || f.severity === 'major') : [])
if (crMust.length) {
  await agent(`${CTX}\nFIX these final code-review blocking/major findings:\n${crMust.map(b => `[${b.severity}] ${b.area}: ${b.detail} ${b.file || ''}`).join('\n')}\nSurgical fixes only.${SELF_VERIFY}`,
    { label: 'final:fix', phase: 'Final' })
  await commitWave('Final', `fix(${SLUG}): address final code-review findings`)
}
const po = await agent(`${CTX}\nPRODUCT-OWNER FINAL REVIEW. Read the plan DoD${PLAN_FILES.length ? ` (${PLAN_FILES.join(', ')})` : ''}, the full \`git diff main...HEAD\`, and RUN \`${FINAL_VERIFY}\`. Produce: recommendation (PROCEED / PROCEED-WITH-FIXES / STOP), greenTypecheck boolean, greenTests summary, per-area status, remainingGaps (what still needs a human — live creds, branch protection, migration apply, etc.), and a phone-readable exec summary.`,
  { label: 'final:product-owner', phase: 'Final', agentType: 'product-owner-reviewer', model: FINAL_MODEL, schema: FINAL_SCHEMA })

return { mode: MODE, final: po, codeReview: { verdict: cr ? cr.verdict : 'n/a', mustFix: crMust.length }, reviewBlockersFixed: reviewResult.must, qaBlockersFixed: qaResult.must }
