/**
 * safe-migration — large mechanical migration across many files, isolated per domain, never self-merged.
 *
 * Discover affected sites → group into non-overlapping file-domains → transform each domain in its own
 * git worktree (attempt-capped, self-verifying via `make quality`) → a reviewer checks cross-leaf
 * contract drift → STOP at a human hand-off. This is the saved, generic form of the Mode-3 substrate
 * (ADR 0001); for per-phase tasks.json work use /orchestrate-loops. The ONLY recipe that writes.
 *
 * Invoke:  Workflow({ name:'safe-migration', args:{ task:'<what to change>', repoPath, mode } })
 * `args.task` is REQUIRED. Reuses the existing safety substrate: worktree isolation + the
 * guard-file-domain.sh PreToolUse hook (leaves export LEAF_DOMAIN_GLOBS). Never merges.
 */

export const meta = {
  name: 'safe-migration',
  description: 'Large mechanical migration: discover sites, group into non-overlapping domains, transform each in an isolated worktree with attempt caps and make-quality gates, reviewer checks cross-leaf drift, stops at a human hand-off (never merges).',
  phases: [
    { title: 'Discover' },
    { title: 'Transform' },
    { title: 'Integrate' },
  ],
}

let A = args // name-invocation delivers args as a JSON string; normalize to an object
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
const MODE = A.mode || 'best'
const SAVER = MODE === 'saver'
const REPO = A.repoPath || '.'
const TASK = A.task || ''
const QUALITY = A.qualityCmd || 'make quality'
const ATTEMPTS = 3

if (!TASK) {
  log('safe-migration: no args.task provided — nothing to migrate.')
  return { error: 'no task provided', usage: "Workflow({ name:'safe-migration', args:{ task:'...', repoPath?, qualityCmd?, mode? } })" }
}

const DISCOVERY_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['domains'],
  properties: {
    domains: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['id', 'globs', 'sites'], properties: {
      id: { type: 'string' },
      globs: { type: 'array', items: { type: 'string' } },
      sites: { type: 'array', items: { type: 'string' } },
      note: { type: 'string' },
    } } },
  },
}
const LEAF_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['domain', 'status', 'filesChanged'],
  properties: {
    domain: { type: 'string' },
    status: { type: 'string', enum: ['done', 'needs-human'] },
    filesChanged: { type: 'array', items: { type: 'string' } },
    commit: { type: ['string', 'null'] },
    notes: { type: 'string' },
  },
}
const REVIEW_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['verdict', 'risks'],
  properties: {
    verdict: { type: 'string', enum: ['clean', 'drift-found'] },
    risks: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['detail'], properties: { detail: { type: 'string' }, file: { type: 'string' } } } },
  },
}

phase('Discover')
log(`safe-migration [${MODE}]: discovering sites for "${TASK}"`)
const discovery = await agent(
  `Repo root: ${REPO}. Migration task: ${TASK}\n\nFind every site affected and group them into domains with NON-OVERLAPPING file globs (two domains' globs must not intersect — that is what lets them run as parallel worktree leaves safely). For each domain: id, globs, sites (specific files), and a note. Do not edit anything.`,
  { label: 'discover', phase: 'Discover', agentType: 'solution-architect', model: SAVER ? 'claude-sonnet-4-6' : 'claude-opus-4-8', schema: DISCOVERY_SCHEMA },
)
const domains = (discovery && discovery.domains) || []
if (!domains.length) {
  return { mode: MODE, task: TASK, domains: 0, note: 'no affected sites found' }
}

phase('Transform')
log(`Transforming ${domains.length} domain(s) in isolated worktrees`)
const results = (await parallel(domains.map(d => () => agent(
  `Repo root: ${REPO}. You own ONE migration domain and run in your own git worktree. Do NOT touch files outside your globs.\n\nFIRST, in your shell: \`export LEAF_DOMAIN_GLOBS="${(d.globs || []).join(':')}"\` so the guard-file-domain.sh hook enforces your boundary.\n\nMIGRATION TASK: ${TASK}\nYOUR DOMAIN: ${d.id}\nGLOBS: ${(d.globs || []).join(', ')}\nSITES: ${(d.sites || []).join(', ')}\n\nApply the change across your sites, then run \`${QUALITY}\`. Retry up to ${ATTEMPTS} times, fixing failures. On the ${ATTEMPTS + 1}th failure, set status="needs-human" and stop touching the domain. On green, commit (Conventional Commits, one commit) and set status="done". Return domain, status, filesChanged, commit, notes. Do NOT merge or switch branches.`,
  { label: `migrate:${d.id}`, phase: 'Transform', isolation: 'worktree', agentType: 'backend-engineer', model: SAVER ? 'claude-haiku-4-5-20251001' : 'claude-sonnet-4-6', schema: LEAF_SCHEMA },
)))).filter(Boolean)

phase('Integrate')
const needsHuman = results.filter(r => r.status === 'needs-human')
const review = await agent(
  `A migration ("${TASK}") was applied across ${results.length} isolated worktree domains. Review for CROSS-LEAF contract drift — places where one domain's change breaks an assumption in another (shared types, API shapes, call sites). Use \`git diff\` across the leaf branches. Return verdict (clean / drift-found) + risks.\n\nLEAF RESULTS:\n${JSON.stringify(results, null, 2)}`,
  { label: 'reviewer', phase: 'Integrate', agentType: 'product-owner-reviewer', model: 'claude-opus-4-8', schema: REVIEW_SCHEMA },
)

return {
  mode: MODE,
  task: TASK,
  domains: domains.length,
  done: results.filter(r => r.status === 'done').map(r => r.domain),
  needsHuman: needsHuman.map(r => r.domain),
  review,
  handoff: 'Migration complete in isolated worktrees — NOT merged. Human: review each leaf branch (git log --oneline --all), resolve any needs-human / drift risks, then merge in dependency order and run /phase-review.',
}
