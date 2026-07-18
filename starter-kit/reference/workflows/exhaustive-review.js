/**
 * exhaustive-review — multi-lens review of the current diff with adversarial verification.
 *
 * One reviewer per lens (parallel) → every finding is attacked by N skeptics who try to refute it
 * (killed on majority refute) → survivors are synthesized and severity-ranked. Heavier and broader
 * than /review-security (single agent, one lens); use that for a fast per-diff pass.
 *
 * Invoke:  /review-exhaustive   ·   or  Workflow({ name:'exhaustive-review', args:{ mode:'best'|'saver' } })
 * Profile (args.mode, default 'best'):
 *   best  — 6 lenses, 5 Sonnet skeptics/finding, Opus synthesis (max quality+speed; cap-aware)
 *   saver — 3 lenses, 2 Haiku  skeptics/finding, Sonnet synthesis (token-optimised)
 * Config reaches this script ONLY via `args` (the runtime has no fs/env access).
 */

export const meta = {
  name: 'exhaustive-review',
  description: 'Multi-lens review of the current diff: parallel reviewers each on a distinct lens, every finding adversarially verified by skeptics (killed on majority refute), survivors synthesized and severity-ranked.',
  phases: [
    { title: 'Review' },
    { title: 'Verify' },
    { title: 'Synthesize' },
  ],
}

let A = args // name-invocation delivers args as a JSON string; normalize to an object
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
const MODE = A.mode || 'best'
const SAVER = MODE === 'saver'

const LENSES = SAVER
  ? ['correctness', 'security', 'tests']
  : ['correctness', 'security', 'performance', 'tests', 'api-contract', 'readability']
const LENS_AGENT = {
  correctness: 'backend-engineer',
  security: 'security-architect',
  performance: 'backend-engineer',
  tests: 'qa-engineer',
  'api-contract': 'solution-architect',
  readability: 'frontend-engineer',
}
const SKEPTICS = SAVER ? 2 : 5
const SKEPTIC_MODEL = SAVER ? 'haiku' : 'sonnet'
const SYNTH_MODEL = 'sonnet'  // v3.2: Sonnet 5 is near-Opus — synthesis is not a gate lane (ADR 0005)

const FINDING = {
  type: 'object', additionalProperties: false,
  required: ['title', 'severity', 'file', 'evidence', 'fix'],
  properties: {
    title: { type: 'string' },
    severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'info'] },
    file: { type: 'string' },
    line: { type: ['integer', 'null'] },
    dimension: { type: 'string' },
    evidence: { type: 'string' },
    fix: { type: 'string' },
    confidence: { type: 'number' },
  },
}
const FINDINGS_SCHEMA = { type: 'object', additionalProperties: false, required: ['findings'], properties: { findings: { type: 'array', items: FINDING } } }
const VERDICT_SCHEMA = { type: 'object', additionalProperties: false, required: ['verdict', 'reason'], properties: { verdict: { type: 'string', enum: ['real', 'false_positive', 'wrong_severity'] }, reason: { type: 'string' } } }
const REPORT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['verdict', 'summary', 'mustFix', 'shouldFix', 'nits'],
  properties: {
    verdict: { type: 'string', enum: ['pass', 'changes-requested', 'block'] },
    summary: { type: 'string' },
    mustFix: { type: 'array', items: FINDING },
    shouldFix: { type: 'array', items: FINDING },
    nits: { type: 'array', items: FINDING },
  },
}

const DIFF = 'Review ONLY the changes on the current branch: run `git diff main...HEAD` plus the uncommitted working tree (`git status --porcelain`, `git diff`). If there is no diff vs main, review the working tree as-is.'

phase('Review')
log(`exhaustive-review [${MODE}]: ${LENSES.length} lenses, ${SKEPTICS} skeptics/finding`)
const reviews = (await parallel(LENSES.map(lens => () => agent(
  `${DIFF}\nYou are the **${lens}** reviewer. Inspect the diff strictly through the ${lens} lens. Be adversarial — default an unclear ${lens} concern to a finding. For each issue return a finding (title, severity, file, line, dimension="${lens}", evidence, concrete fix, confidence 0-1). Return an empty array if the diff is clean on ${lens}.`,
  { label: `review:${lens}`, phase: 'Review', agentType: LENS_AGENT[lens] || 'backend-engineer', model: lens === 'security' ? 'opus' : 'sonnet', schema: FINDINGS_SCHEMA },
)))).filter(Boolean)

const findings = reviews.flatMap(r => (r && r.findings) || [])
if (!findings.length) {
  log('No findings from any lens — diff is clean.')
  return { mode: MODE, lenses: LENSES, candidates: 0, confirmed: 0, report: { verdict: 'pass', summary: 'No findings; diff is clean across all lenses.', mustFix: [], shouldFix: [], nits: [] } }
}

phase('Verify')
log(`Adversarially verifying ${findings.length} candidate finding(s)`)
const verified = await parallel(findings.map((f, i) => () =>
  parallel(Array.from({ length: SKEPTICS }, (_, k) => () => agent(
    `A reviewer raised this finding on the current diff:\nTitle: ${f.title}\nSeverity: ${f.severity}\nFile: ${f.file}${f.line ? ':' + f.line : ''}\nEvidence: ${f.evidence}\nProposed fix: ${f.fix}\n\nYou are skeptic #${k + 1}. Try to REFUTE it: read the actual code (\`git diff main...HEAD\`, open the file) and judge whether it is real, a false_positive, or has the wrong_severity. Default to false_positive if you cannot confirm it from the code itself. Return verdict + a one-line reason.`,
    { label: `verify#${i}.${k}`, phase: 'Verify', model: SKEPTIC_MODEL, schema: VERDICT_SCHEMA },
  ))).then(raw => {
    const v = raw.filter(Boolean)
    const refuted = v.filter(x => x.verdict === 'false_positive').length
    const real = v.length > 0 && refuted < Math.ceil(v.length / 2) // killed on majority refute
    const downgrade = v.filter(x => x.verdict === 'wrong_severity').length > v.length / 2
    return { ...f, real, skeptics: v.length, refuted, severity: downgrade ? 'low' : f.severity }
  }),
))
const survivors = verified.filter(v => v && v.real)

phase('Synthesize')
log(`${survivors.length}/${findings.length} findings survived verification`)
const report = await agent(
  `Synthesize this verified-findings list into a reviewer's report for the current diff. Dedup overlapping findings, rank by severity, and group into mustFix (critical/high) / shouldFix (medium) / nits (low/info). Cite file:line. Set verdict: block if any critical, changes-requested if any high/medium, else pass.\n\nVERIFIED FINDINGS:\n${JSON.stringify(survivors.map(({ real, skeptics, refuted, ...f }) => f), null, 2)}`,
  { label: 'synthesize', phase: 'Synthesize', agentType: 'solution-architect', model: SYNTH_MODEL, schema: REPORT_SCHEMA },
)

return { mode: MODE, lenses: LENSES, candidates: findings.length, confirmed: survivors.length, report }
