/**
 * security-sweep — whole-repo security audit (loop-until-dry per vuln class + adversarial verify).
 *
 * Parallel hunters, one per vulnerability class, each keep probing until N consecutive empty rounds
 * (loop-until-dry) → every candidate is attacked by skeptics (killed on majority refute) → survivors
 * are mapped to OWASP categories and severity-ranked. The heavyweight whole-repo sibling of
 * /review-security (which is a fast single-agent per-diff pass).
 *
 * Invoke:  /audit-security   ·   or  Workflow({ name:'security-sweep', args:{ mode, repoPath } })
 * Profile (args.mode, default 'best'): best = 6 classes, 2 empty-round dry threshold, 5 Sonnet
 *   skeptics, Opus report; saver = 4 classes, 1-round, 2 Haiku skeptics, Sonnet report.
 */

export const meta = {
  name: 'security-sweep',
  description: 'Whole-repo security audit: parallel hunters per vuln class loop until dry, each candidate adversarially verified, survivors mapped to OWASP and severity-ranked.',
  phases: [
    { title: 'Hunt' },
    { title: 'Verify' },
    { title: 'Report' },
  ],
}

let A = args // name-invocation delivers args as a JSON string; normalize to an object
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
const MODE = A.mode || 'best'
const SAVER = MODE === 'saver'
const REPO = A.repoPath || '.'

const CLASSES = [
  { key: 'authz', agent: 'security-architect', model: 'opus', desc: 'authentication, authorization, tenant isolation, privilege escalation, IDOR' },
  { key: 'injection', agent: 'security-architect', model: 'sonnet', desc: 'SQL/NoSQL/command injection, SSRF, XSS, path traversal' },
  { key: 'secrets', agent: 'devops-engineer', model: 'sonnet', desc: 'hardcoded secrets, credential handling, key exposure, secrets in logs' },
  { key: 'input-validation', agent: 'backend-engineer', model: 'sonnet', desc: 'unvalidated input, unsafe deserialization, mass assignment, missing schema validation' },
  { key: 'dependencies', agent: 'devops-engineer', model: 'sonnet', desc: 'vulnerable/outdated dependencies, supply-chain risk, lockfile integrity' },
  { key: 'prompt-injection', agent: 'ai-engineer', model: 'opus', desc: 'LLM trust-boundary violations, prompt injection, tool-output-as-instruction, unsafe handling of model output' },
]
const classes = SAVER ? CLASSES.slice(0, 4) : CLASSES
const DRY = SAVER ? 1 : 2          // stop a class after this many consecutive empty rounds
const MAX_ROUNDS = 5
const SKEPTICS = SAVER ? 2 : 5
const SKEPTIC_MODEL = SAVER ? 'haiku' : 'sonnet'
const SYNTH_MODEL = SAVER ? 'sonnet' : 'opus'

const FINDING = {
  type: 'object', additionalProperties: false,
  required: ['title', 'severity', 'file', 'evidence', 'fix'],
  properties: {
    title: { type: 'string' },
    severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'info'] },
    file: { type: 'string' }, line: { type: ['integer', 'null'] }, dimension: { type: 'string' },
    evidence: { type: 'string' }, fix: { type: 'string' }, confidence: { type: 'number' },
  },
}
const FINDINGS_SCHEMA = { type: 'object', additionalProperties: false, required: ['findings'], properties: { findings: { type: 'array', items: FINDING } } }
const VERDICT_SCHEMA = { type: 'object', additionalProperties: false, required: ['verdict', 'reason'], properties: { verdict: { type: 'string', enum: ['real', 'false_positive', 'wrong_severity'] }, reason: { type: 'string' } } }
const REPORT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['summary', 'findings'],
  properties: {
    summary: { type: 'string' },
    findings: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['title', 'severity', 'owasp', 'file', 'fix'], properties: { title: { type: 'string' }, severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low', 'info'] }, owasp: { type: 'string' }, file: { type: 'string' }, line: { type: ['integer', 'null'] }, evidence: { type: 'string' }, fix: { type: 'string' } } } },
  },
}

async function huntClass(c) {
  const found = []
  let dry = 0, round = 0
  while (dry < DRY && round < MAX_ROUNDS) {
    round++
    const seen = found.map(f => f.title).join(' | ')
    const r = await agent(
      `Repo root: ${REPO}. Hunt **${c.key}** vulnerabilities — ${c.desc}. Search the whole tree (read excerpts). ${seen ? `Already found, do NOT repeat: ${seen}. ` : ''}Return only NEW findings (title, severity, file, line, dimension="${c.key}", evidence, fix, confidence); empty array if none remain.`,
      { label: `hunt:${c.key}#${round}`, phase: 'Hunt', agentType: c.agent, model: c.model, schema: FINDINGS_SCHEMA },
    )
    const fresh = (r && r.findings) || []
    if (!fresh.length) dry++
    else { dry = 0; found.push(...fresh.map(f => ({ ...f, dimension: c.key }))) }
  }
  return found
}

phase('Hunt')
log(`security-sweep [${MODE}]: ${classes.length} classes, dry-threshold ${DRY}`)
const found = (await parallel(classes.map(c => () => huntClass(c)))).filter(Boolean).flat()

if (!found.length) {
  log('No candidates found across all classes.')
  return { mode: MODE, classes: classes.map(c => c.key), candidates: 0, confirmed: 0, report: { summary: 'No security findings surfaced.', findings: [] } }
}

phase('Verify')
log(`Adversarially verifying ${found.length} candidate(s)`)
const verified = await parallel(found.map((f, i) => () =>
  parallel(Array.from({ length: SKEPTICS }, (_, k) => () => agent(
    `A security hunter raised this ${f.dimension} finding in repo ${REPO}:\nTitle: ${f.title}\nSeverity: ${f.severity}\nFile: ${f.file}${f.line ? ':' + f.line : ''}\nEvidence: ${f.evidence}\n\nYou are skeptic #${k + 1}. Try to REFUTE it: read the code and decide real / false_positive / wrong_severity. Default false_positive if you cannot confirm exploitability from the code. Return verdict + reason.`,
    { label: `verify:${f.dimension}#${i}.${k}`, phase: 'Verify', model: SKEPTIC_MODEL, schema: VERDICT_SCHEMA },
  ))).then(raw => {
    const v = raw.filter(Boolean)
    const refuted = v.filter(x => x.verdict === 'false_positive').length
    const real = v.length > 0 && refuted < Math.ceil(v.length / 2)
    const downgrade = v.filter(x => x.verdict === 'wrong_severity').length > v.length / 2
    return { ...f, real, severity: downgrade ? 'low' : f.severity }
  }),
))
const survivors = verified.filter(v => v && v.real)

phase('Report')
log(`${survivors.length}/${found.length} findings confirmed`)
const report = await agent(
  `Map these confirmed security findings (repo ${REPO}) to OWASP categories, dedup, and rank by severity. For each: title, severity, owasp (e.g. "A01:2021 Broken Access Control"), file, line, evidence, fix. Write a one-paragraph executive summary.\n\nCONFIRMED FINDINGS:\n${JSON.stringify(survivors.map(({ real, confidence, ...f }) => f), null, 2)}`,
  { label: 'report', phase: 'Report', agentType: 'security-architect', model: SYNTH_MODEL, schema: REPORT_SCHEMA },
)

return { mode: MODE, classes: classes.map(c => c.key), candidates: found.length, confirmed: survivors.length, report }
