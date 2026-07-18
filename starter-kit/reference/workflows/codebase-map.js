/**
 * codebase-map — build a navigable mental model of a repo from parallel multi-modal readers.
 *
 * Distinct readers sweep the same tree in different modes (modules, data, integrations, tests,
 * build/CI, domain language) → an architecture brief is synthesized → a completeness critic finds
 * unread areas → one re-pass fills the gaps (best mode). Pure read-only; safe on any repo.
 *
 * Invoke:  /map-codebase   ·   or  Workflow({ name:'codebase-map', args:{ mode, repoPath } })
 * Profile (args.mode, default 'best'): best = all 6 modes + critic re-pass; saver = 3 core modes,
 *   single pass, Sonnet synthesis. `args.repoPath` (default '.') is passed to agents; the script has
 *   no fs access of its own.
 */

export const meta = {
  name: 'codebase-map',
  description: 'Map a repo with parallel readers each in a distinct mode (modules, data model, integrations, tests, build/CI, domain language), synthesize one architecture brief, then run a completeness critic that triggers a gap re-pass.',
  phases: [
    { title: 'Sweep' },
    { title: 'Synthesize' },
    { title: 'Critique' },
  ],
}

let A = args // name-invocation delivers args as a JSON string; normalize to an object
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') A = {}
const MODE = A.mode || 'best'
const SAVER = MODE === 'saver'
const REPO = A.repoPath || '.'
const MODES = SAVER
  ? ['modules', 'data-model', 'tests']
  : ['modules', 'data-model', 'integrations', 'tests', 'build-ci', 'domain-language']
const SYNTH_MODEL = SAVER ? 'sonnet' : 'opus'

const MODE_BRIEF = {
  'modules': 'top-level modules / packages / entrypoints and how they depend on each other',
  'data-model': 'persistence: schemas, migrations, entities/tables and their relationships',
  'integrations': 'external services, API clients, config and environment variables, secrets surfaces',
  'tests': 'test topology: where tests live, frameworks, what is and is not covered',
  'build-ci': 'build system, scripts, CI workflows, deploy/release pipeline',
  'domain-language': 'the ubiquitous domain language: core nouns/verbs and what they mean here',
}

const SECTION_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['mode', 'summary', 'keyPaths'],
  properties: {
    mode: { type: 'string' },
    summary: { type: 'string' },
    keyPaths: { type: 'array', items: { type: 'string' } },
    entrypoints: { type: 'array', items: { type: 'string' } },
    risks: { type: 'array', items: { type: 'string' } },
  },
}
const BRIEF_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['overview', 'components', 'dataFlow', 'keyPaths'],
  properties: {
    overview: { type: 'string' },
    components: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['name', 'role'], properties: { name: { type: 'string' }, role: { type: 'string' }, paths: { type: 'array', items: { type: 'string' } } } } },
    dataFlow: { type: 'string' },
    keyPaths: { type: 'array', items: { type: 'string' } },
    risks: { type: 'array', items: { type: 'string' } },
  },
}
const CRITIC_SCHEMA = { type: 'object', additionalProperties: false, required: ['complete', 'gaps'], properties: { complete: { type: 'boolean' }, gaps: { type: 'array', items: { type: 'string' } } } }

const reader = (m) => agent(
  `Repo root: ${REPO}. You are the **${m}** reader. Explore the tree and report on: ${MODE_BRIEF[m] || m}. Read excerpts, not whole files. Return a section: mode="${m}", a tight summary, the key paths, entrypoints, and any risks you noticed.`,
  { label: `read:${m}`, phase: 'Sweep', model: 'sonnet', agentType: m === 'domain-language' ? 'domain-expert' : undefined, schema: SECTION_SCHEMA },
)
const synthPrompt = (sections, extra) =>
  `Synthesize these per-mode readings of repo ${REPO} into ONE architecture brief: overview, components (name/role/paths), the primary data-flow path, the key paths a new contributor must know, and risks. ${extra || ''}\n\nSECTIONS:\n${JSON.stringify(sections, null, 2)}`

phase('Sweep')
log(`codebase-map [${MODE}]: ${MODES.length} readers over ${REPO}`)
let sections = (await parallel(MODES.map(m => () => reader(m)))).filter(Boolean)

phase('Synthesize')
let brief = await agent(synthPrompt(sections), { label: 'synthesize', phase: 'Synthesize', agentType: 'solution-architect', model: SYNTH_MODEL, schema: BRIEF_SCHEMA })

phase('Critique')
const critic = await agent(
  `You are a completeness critic for an architecture brief of repo ${REPO}. Given the modes already swept (${MODES.join(', ')}) and the brief below, list concrete areas that were NOT read but should be (a directory never opened, a service with no described entrypoint, etc.). Set complete=true with an empty gaps list if coverage is adequate.\n\nBRIEF:\n${JSON.stringify(brief, null, 2)}`,
  { label: 'critic', phase: 'Critique', model: SYNTH_MODEL, schema: CRITIC_SCHEMA },
)
const gaps = (critic && critic.gaps) || []
if (!SAVER && gaps.length) {
  log(`Critic found ${gaps.length} gap(s) — one re-pass`)
  const extra = (await parallel(gaps.slice(0, 6).map((g, i) => () => agent(
    `Repo ${REPO}. A completeness critic flagged this previously-unread area: "${g}". Read it and return a section (mode="gap:${i}", summary, keyPaths, entrypoints, risks).`,
    { label: `read:gap#${i}`, phase: 'Critique', model: 'sonnet', schema: SECTION_SCHEMA },
  )))).filter(Boolean)
  sections = sections.concat(extra)
  brief = await agent(synthPrompt(sections, 'Incorporate the newly-read gap areas.'), { label: 'resynthesize', phase: 'Critique', agentType: 'solution-architect', model: SYNTH_MODEL, schema: BRIEF_SCHEMA })
}

return { mode: MODE, modes: MODES, sectionsRead: sections.length, gapsFound: gaps.length, complete: !!(critic && critic.complete), brief }
