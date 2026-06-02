/**
 * release-readiness — pre-release gate that runs every readiness lens in parallel + a completeness critic.
 *
 * Parallel lenses (tests/QA, security, perf, docs-drift, changelog, breaking-changes) assess the
 * release concurrently → a completeness critic confirms every prepare-release checklist item was
 * addressed → a single go/no-go brief. Pre-computes the evidence /prepare-release would gather serially.
 *
 * Invoke:  Workflow({ name:'release-readiness', args:{ mode, repoPath } })
 * Profile (args.mode, default 'best'): best = 6 lenses + Opus verdict; saver = 4 lenses + Sonnet.
 */

export const meta = {
  name: 'release-readiness',
  description: 'Pre-release gate: parallel lenses (QA, security, perf, docs-drift, changelog, breaking-changes) assessed concurrently, a completeness critic verifies the release checklist was covered, output is one go/no-go brief.',
  phases: [
    { title: 'Assess' },
    { title: 'Critique' },
    { title: 'Verdict' },
  ],
}

const MODE = (args && args.mode) || 'best'
const SAVER = MODE === 'saver'
const REPO = (args && args.repoPath) || '.'
const SYNTH_MODEL = SAVER ? 'claude-sonnet-4-6' : 'claude-opus-4-8'

const LENSES = [
  { key: 'qa', agent: 'qa-engineer', desc: 'run/inspect the test suite; coverage of new code; flaky or skipped tests' },
  { key: 'security', agent: 'security-architect', desc: 'auth/tenancy/secret regressions, new attack surface, dependency advisories' },
  { key: 'performance', agent: 'backend-engineer', desc: 'obvious perf regressions, N+1s, unbounded queries, bundle bloat' },
  { key: 'docs-drift', agent: 'technical-writer', desc: 'README / API docs / env-var docs out of sync with what shipped' },
  { key: 'changelog', agent: 'technical-writer', desc: 'CHANGELOG completeness and version-bump correctness' },
  { key: 'breaking-changes', agent: 'solution-architect', desc: 'API/schema/contract breaks, migration safety, backward compatibility' },
]
const lenses = SAVER ? LENSES.filter(l => ['qa', 'security', 'docs-drift', 'breaking-changes'].includes(l.key)) : LENSES

const LENS_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['lens', 'status', 'notes'],
  properties: {
    lens: { type: 'string' },
    status: { type: 'string', enum: ['pass', 'warn', 'fail'] },
    notes: { type: 'string' },
    blockers: { type: 'array', items: { type: 'string' } },
  },
}
const CRITIC_SCHEMA = { type: 'object', additionalProperties: false, required: ['covered', 'missing'], properties: { covered: { type: 'boolean' }, missing: { type: 'array', items: { type: 'string' } } } }
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['recommendation', 'summary', 'blockers'],
  properties: {
    recommendation: { type: 'string', enum: ['GO', 'GO-WITH-FIXES', 'NO-GO'] },
    summary: { type: 'string' },
    blockers: { type: 'array', items: { type: 'string' } },
    byLens: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['lens', 'status'], properties: { lens: { type: 'string' }, status: { type: 'string' } } } },
  },
}

phase('Assess')
log(`release-readiness [${MODE}]: ${lenses.length} lenses on ${REPO}`)
const assessed = (await parallel(lenses.map(l => () => agent(
  `Repo root: ${REPO}. You are the **${l.key}** release-readiness lens. Assess the release-candidate state for: ${l.desc}. Inspect the code/diff/tree as needed. Return status (pass/warn/fail), notes, and any blockers.`,
  { label: `assess:${l.key}`, phase: 'Assess', agentType: l.agent, model: 'claude-sonnet-4-6', schema: LENS_SCHEMA },
)))).filter(Boolean)

phase('Critique')
const critic = await agent(
  `Repo root: ${REPO}. The pre-release checklist lives in the project's prepare-release command (.claude/commands/prepare-release.md if present). Given the lens assessments below, confirm every checklist item was actually addressed; list anything missing.\n\nASSESSMENTS:\n${JSON.stringify(assessed, null, 2)}`,
  { label: 'critic', phase: 'Critique', agentType: 'product-owner-reviewer', model: SYNTH_MODEL, schema: CRITIC_SCHEMA },
)

phase('Verdict')
const missing = (critic && critic.missing) || []
log(`Lenses done; ${missing.length} checklist gap(s)`)
const verdict = await agent(
  `Produce a release go/no-go brief. NO-GO if any lens failed or any blocker exists; GO-WITH-FIXES if only warnings/missing checklist items; GO if all clean. Include a phone-readable summary, the consolidated blocker list, and per-lens status.\n\nLENS ASSESSMENTS:\n${JSON.stringify(assessed, null, 2)}\n\nCHECKLIST GAPS:\n${JSON.stringify(missing, null, 2)}`,
  { label: 'verdict', phase: 'Verdict', agentType: 'product-owner-reviewer', model: SYNTH_MODEL, schema: VERDICT_SCHEMA },
)

return { mode: MODE, lenses: lenses.map(l => l.key), checklistGaps: missing.length, verdict }
