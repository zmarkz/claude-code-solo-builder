/**
 * design-panel — N independent design proposals, a judge panel, then a synthesized recommendation.
 *
 * Independent proposers each attack the problem from a different angle (so they diverge) → a panel of
 * diverse-lens judges scores every proposal on a fixed rubric → the winner (or a hybrid) is
 * synthesized into an ADR draft. Feeds /plan-feature and /design-feature.
 *
 * Invoke:  Workflow({ name:'design-panel', args:{ problem:'<the design question>', mode } })
 * Profile (args.mode, default 'best'): best = 4 proposers, 4 judges, Opus synthesis;
 *   saver = 2 proposers, 2 judges, Sonnet synthesis. `args.problem` is REQUIRED.
 */

export const meta = {
  name: 'design-panel',
  description: 'Generate N independent design approaches to a problem, score each on a fixed rubric via a diverse judge panel, then synthesize the winner or a hybrid into an ADR-ready recommendation.',
  phases: [
    { title: 'Propose' },
    { title: 'Judge' },
    { title: 'Synthesize' },
  ],
}

let A = args // name-invocation delivers args as a JSON string; normalize to an object
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
const MODE = A.mode || 'best'
const SAVER = MODE === 'saver'
const PROBLEM = A.problem || ''
const CONTEXT = A.context || ''
const N = SAVER ? 2 : 4
const ANGLES = ['the simplest thing that could work', 'the most robust / scalable design', 'the fastest to ship safely', 'the most different, first-principles approach']
const JUDGES = SAVER ? ['solution-architect', 'qa-engineer'] : ['solution-architect', 'security-architect', 'qa-engineer', 'product-manager']
const RUBRIC = ['fit', 'simplicity', 'risk', 'reversibility', 'effort']
const SYNTH_MODEL = SAVER ? 'sonnet' : 'opus'

if (!PROBLEM) {
  log('design-panel: no args.problem provided — nothing to design.')
  return { error: 'no problem provided', usage: "Workflow({ name:'design-panel', args:{ problem:'...', context?, mode? } })" }
}

const PROPOSAL_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['name', 'summary', 'approach', 'tradeoffs', 'risks', 'effort'],
  properties: {
    name: { type: 'string' }, summary: { type: 'string' }, approach: { type: 'string' },
    tradeoffs: { type: 'array', items: { type: 'string' } },
    risks: { type: 'array', items: { type: 'string' } },
    effort: { type: 'string', enum: ['S', 'M', 'L', 'XL'] },
  },
}
const SCORE_PROPS = {}
for (const r of RUBRIC) SCORE_PROPS[r] = { type: 'integer', minimum: 0, maximum: 10 }
const JUDGE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['proposal', 'scores', 'total', 'rationale'],
  properties: {
    proposal: { type: 'string' },
    scores: { type: 'object', additionalProperties: false, required: RUBRIC, properties: SCORE_PROPS },
    total: { type: 'integer' },
    rationale: { type: 'string' },
  },
}
const ADR_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['title', 'context', 'decision', 'rationale', 'alternatives', 'consequences'],
  properties: {
    title: { type: 'string' }, context: { type: 'string' }, decision: { type: 'string' }, rationale: { type: 'string' },
    alternatives: { type: 'array', items: { type: 'string' } },
    consequences: { type: 'array', items: { type: 'string' } },
  },
}

const HEAD = `DESIGN PROBLEM:\n${PROBLEM}${CONTEXT ? `\n\nCONTEXT:\n${CONTEXT}` : ''}`

phase('Propose')
log(`design-panel [${MODE}]: ${N} proposers → ${JUDGES.length} judges`)
const proposals = (await parallel(Array.from({ length: N }, (_, i) => () => agent(
  `${HEAD}\n\nPropose a complete design from this angle: **${ANGLES[i % ANGLES.length]}**. Do not hedge toward other angles — commit to this one so the panel sees genuinely different options. Return: name, summary, the approach in detail, tradeoffs, risks, effort (S/M/L/XL).`,
  { label: `propose#${i}`, phase: 'Propose', agentType: 'solution-architect', model: SAVER ? 'sonnet' : 'opus', schema: PROPOSAL_SCHEMA },
)))).filter(Boolean)

if (proposals.length < 2) {
  return { error: 'not enough proposals', proposals }
}

phase('Judge')
const judged = await parallel(proposals.map((p, pi) =>
  JUDGES.map(j => () => agent(
    `${HEAD}\n\nYou are a **${j}** judge. Score this proposal 0-10 on each rubric dimension (${RUBRIC.join(', ')}) from your perspective, give the total, and a one-line rationale.\n\nPROPOSAL "${p.name}":\n${JSON.stringify(p, null, 2)}`,
    { label: `judge:${j}#${pi}`, phase: 'Judge', agentType: j, model: 'sonnet', schema: JUDGE_SCHEMA },
  )),
).flat())
const scores = {}
for (const v of judged.filter(Boolean)) scores[v.proposal] = (scores[v.proposal] || 0) + (v.total || 0)

phase('Synthesize')
log(`Scored ${proposals.length} proposals across ${JUDGES.length} judges`)
const adr = await agent(
  `${HEAD}\n\nThe judge panel scored these proposals (summed totals): ${JSON.stringify(scores)}. Pick the winner or construct a hybrid that grafts the best ideas from the runners-up, and write it up as an ADR draft (title, context, decision, rationale, alternatives considered, consequences).\n\nPROPOSALS:\n${JSON.stringify(proposals, null, 2)}\n\nJUDGE NOTES:\n${JSON.stringify(judged.filter(Boolean).map(v => ({ proposal: v.proposal, total: v.total, rationale: v.rationale })), null, 2)}`,
  { label: 'synthesize', phase: 'Synthesize', agentType: 'solution-architect', model: SYNTH_MODEL, schema: ADR_SCHEMA },
)

return { mode: MODE, proposals: proposals.map(p => p.name), scores, adr }
