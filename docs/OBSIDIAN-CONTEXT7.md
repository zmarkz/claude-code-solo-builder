# Obsidian + Context7 + Knowledge Graph Setup

> Your vault is the memory that makes every new project cheaper to build.

---

## Status: This vault is live, not aspirational

The vault at `~/Obsidian/Builds/` is actively in use with the Karpathy framework. As of v2.3:
- **9 projects indexed** in `01-Projects/` (portfolio-tracker, mcp-farm, knowledge-store, admin-nexus, markandey-in, kids-ai-app, family-expenses, fintech-project, tradingAgents)
- **10 patterns captured** in `05-Patterns/` (ai-model-routing, per-tenant-isolation, two-stack-bridge-via-sse, child-safe-ai-pipeline, rolling-session-summary, and more)
- **3 postmortems** in `04-Archive/` (med-tracker, open-health, medi-tracker — killed apps kept for reference)
- **ADRs at vault root** (ADR-0009-per-tenant-minio-bucket.md and others)
- **Git-backed** with auto-sync

## Why the Knowledge Layer Matters

Without a vault, every new app starts from zero. With one:
- Stripe integration in app 3 takes 20% of the time it took in app 1 (past ADR + wrapper found instantly)
- Security audit in app 4 references the exact same checklist used in app 2
- Every bug postmortem becomes a pattern that prevents the same bug in future apps

**Platform** makes each new app cheaper. **Knowledge** makes each new app smarter. The vault is the compound interest of your building career.

---

## The Three Knowledge Types

Every app produces three kinds of knowledge:

| Type | Description | Where it lives |
|------|-------------|---------------|
| **Procedural** | *How* to do things | Skills under `~/.claude/skills/` |
| **Episodic** | *What happened* | Vault notes in `~/Obsidian/Builds/` |
| **External** | *What's currently true* | Context7 MCP, pulled at query time |

The system addresses all three. Don't rely on just one.

---

## The Karpathy Six Rules

Named for Andrej Karpathy's "LLM Wiki" pattern. These rules prevent the vault from becoming an unnavigable mess:

1. **Five page types only** — `entity`, `concept`, `synthesis`, `source`, `report`
2. **Search before write** — always `kg_search` before creating a new note
3. **Backlinks are mandatory** — every note links to ≥1 other note
4. **Contradictions are flagged on the page, never silently overwritten**
5. **Attribution in frontmatter** — `created_by`, `last_edited_by`
6. **One vault** — no subvaults, no parallel hierarchies

---

## Vault Structure

```
~/Obsidian/Builds/
├── .obsidian/                          ← Obsidian settings (gitignored)
├── .claude/
│   ├── CLAUDE.md                       ← Vault-level standing instructions
│   └── skills/                         ← Vault-aware skills
├── 00-Inbox/                           ← Capture everything here first
├── 01-Projects/                        ← Active apps (one folder each)
│   ├── app-voice-notes/
│   │   ├── PRD.md
│   │   ├── ADR-001-stack.md
│   │   └── BUILD-LOG.md
│   └── ...
├── 02-Areas/                           ← Ongoing themes
│   ├── Distribution/
│   ├── Pricing/
│   ├── AI-Stack/
│   └── Customer-Research/
├── 03-Resources/                       ← Snippets, vendor docs, references
├── 04-Archive/                         ← Killed apps (DO NOT DELETE)
└── 05-Patterns/                        ← Patterns before they become skills
```

### Frontmatter template (actual format used in this vault)

Every note uses this frontmatter:

```yaml
---
type: <entity|concept|synthesis|source|report>
created: YYYY-MM-DD
created_by: <human|claude|swarm-name>
last_edited: YYYY-MM-DD
last_edited_by: <human|claude|swarm-name>
status: <draft|active|stale|archived>
canonical: false
tags: [topic1, topic2]
related: [[note1]], [[note2]]
---
```

**Concept** (pattern canonical across multiple apps):
```markdown
---
type: concept
created: 2026-05-16
created_by: claude
status: canonical
canonical: true
tags: [pattern, ai-routing, cost-optimisation]
related:
  - "[[01-Projects/portfolio-tracker/INDEX]]"
  - "[[01-Projects/mcp-farm/INDEX]]"
---
# Pattern: AI Model Routing (COMPLEX / SIMPLE split)
Route every AI call through a classifier. COMPLEX → Claude (paid). SIMPLE → Qwen local (free).
Apps never call Anthropic/Ollama directly.
```

**Entity** (a thing in your system):
```markdown
---
type: entity
name: Portfolio Tracker
created: 2026-05-16
created_by: markandey
status: active
tags: [spring-boot, java, mysql, portfolio]
related: [[01-Projects/mcp-farm/INDEX]], [[01-Projects/knowledge-store/INDEX]]
---
# Portfolio Tracker
The Spring Boot API that manages Zerodha holdings and provides AI-powered analysis.
[[mcp-farm]] → [[knowledge-store]] → [[portfolio-tracker-frontend]]
```

---

## MCP Server Setup

Install in this exact order. Don't skip the order — each layer builds on the previous.

### 1. Context7 (install first — takes 30 seconds)

Context7 fetches fresh library docs at query time. It knows the current Stripe API, the current Next.js 15 docs, the current Supabase SDK — not your model's training cutoff.

```bash
# In Claude Code settings (claude.json or via /config):
# Add to mcpServers:
{
  "context7": {
    "command": "npx",
    "args": ["-y", "@upstash/context7-mcp@latest"]
  }
}
```

**Usage pattern:**
```
# Claude Code automatically uses Context7 when you mention a library
> "Add Stripe subscriptions using the latest SDK"
# Claude silently calls Context7 for current Stripe docs
# You get code that actually works with today's API
```

### 2. vault-files via @modelcontextprotocol/server-filesystem (install second — takes 30 seconds)

Direct vault file access. No Obsidian dependency — works even when Obsidian is closed.

> **Note:** The `mcpvault` npm package (previously recommended here) returns a 404 — it does not exist on the registry. Use `@modelcontextprotocol/server-filesystem` instead, which is the official MCP filesystem server.

Install via Claude Code CLI (recommended):
```bash
claude mcp add --scope user vault-files -- npx -y @modelcontextprotocol/server-filesystem /Users/yourname/Obsidian/Builds
```

Or add to your MCP config manually:
```json
{
  "vault-files": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/yourname/Obsidian/Builds"]
  }
}
```

**Usage:** Covers ~80% of vault queries. Use while knowledge-graph is being indexed.

### 3. obra/knowledge-graph (install third — 30-minute setup block)

Vault as a queryable graph: SQLite + vectors + full-text + traversal. Enables:
- `kg_search "stripe subscription"` → finds related notes
- `kg_paths from [[Stripe]] to [[portfolio-tracker]]` → finds decision chains

```bash
# Clone and install
git clone https://github.com/obra/knowledge-graph-mcp.git ~/tools/knowledge-graph-mcp
cd ~/tools/knowledge-graph-mcp
npm install

# Set vault path
export KG_VAULT_PATH="/Users/yourname/Obsidian/Builds"

# Add to Claude Code settings:
{
  "knowledge-graph": {
    "command": "node",
    "args": ["/Users/yourname/tools/knowledge-graph-mcp/index.js"],
    "env": {
      "KG_VAULT_PATH": "/Users/yourname/Obsidian/Builds"
    }
  }
}
```

**Initial indexing:** Run `/kg-index` in Claude Code. Takes ~30 minutes for a large vault. Schedule a block for this — don't block vault-first behavior on it.

### What NOT to install

- **Obsidian Smart Connections** — RCE vulnerability discovered April 2026
- **Obsidian Copilot** — redundant with this setup
- **Community mcp-obsidian** — brittle, breaks on Obsidian updates

---

## The Combined Query Pattern

After setup, a single Claude Code request silently uses all three layers:

```
You: "Add Stripe subscriptions to this app, following my conventions."

Claude (silently):
  1. kg_search "stripe subscription" → finds past ADR + your wrapper in _platform/
  2. kg_paths [[Stripe]] to [[this-app]] → finds related prior decisions
  3. Context7: "stripe-node subscription latest API" → fetches fresh docs
  4. Synthesizes: YOUR wrapper, YOUR conventions, CURRENT Stripe API
  5. Writes the code
  6. Creates ADR in vault, links [[Stripe]] [[this-app]] [[platform-billing]]
```

The result: code that follows your patterns AND uses the current API. Neither vault alone nor Context7 alone produces this.

---

## Ingesting Existing Projects into the Vault

If you have existing projects, use the **Obsidian Ingestion Procedure** from the playbook (Part C).

For each existing project, create a note in `01-Projects/<project-name>/`:

1. **PRD.md** — What problem does it solve? For whom?
2. **ARCHITECTURE.md** — Key technical decisions (copy from code, not from memory)
3. **ADR-001-stack.md** — Why this stack? (retrospective is fine)
4. **BUILD-LOG.md** — Key events, pivots, what failed, what succeeded
5. **STATUS.md** — Current bucket: `ACTIVE-BUILD | VALIDATE | STABILIZE | KEEP-AS-IS | DEAD`

Minimum viable note if you're in a hurry:
```markdown
---
type: entity
name: <project-name>
status: <bucket>
last_edited_by: markandey
---
# <project-name>
One paragraph: what it does, who uses it, current state.
[[Link to stack decisions if any]]
```

Do at least the minimum note for every project. A shallow index is infinitely more useful than no index.

---

## Vault-First Behavior in CLAUDE.md

Add this to your `~/.claude/CLAUDE.md`:

```markdown
## MCP servers — vault-first behavior

At the START of every non-trivial task:
1. `kg_search` the vault (~/Obsidian/Builds/) for related notes.
2. For architectural decisions, also check `02-Areas/` and ADRs in `01-Projects/`.
3. For library / external service work, also query **Context7** for fresh docs.
4. Cite findings by `[[wikilink]]` in your response.

When producing outputs:
1. Non-trivial architectural decision → run `write-adr` skill → `docs/adr/NNNN-<slug>.md`
2. Reusable pattern → draft note for `05-Patterns/` via `extract-pattern`
3. Never silently overwrite an existing vault note — propose diffs only.
```

This ensures every session is vault-grounded without you having to ask.

---

## Daily Vault Maintenance (5 minutes)

```bash
# Morning: pull any updates
cd ~/Obsidian/Builds && git pull

# Evening: commit new notes
cd ~/Obsidian/Builds
git add . && git commit -m "vault: $(date '+%Y-%m-%d') session notes"
git push
```

**Weekly:** Run `kg_rebuild` to refresh the knowledge graph index after new notes.

**Monthly:** Check `04-Archive/` — kill postmortems there are gold for preventing repeat mistakes.

---

## The Vault Hierarchy: What Goes Where

| Content | Location |
|---------|----------|
| Active app docs (PRD, arch, ADRs) | `01-Projects/<app>/` |
| Patterns you use across apps | `05-Patterns/` |
| New ideas, quick captures | `00-Inbox/` (process weekly) |
| Vendor/library research | `03-Resources/` |
| Killed apps (keep forever) | `04-Archive/<app>/` |
| Distribution, pricing, customer research | `02-Areas/<theme>/` |
| Kill rituals, postmortems | `04-Archive/<app>/POSTMORTEM.md` |

**The golden rule:** If you learned something that will make the next project cheaper or smarter, it goes in the vault. If you learned something only relevant to today's session, it doesn't.

---

## Obsidian Plugins That Actually Help

| Plugin | Purpose | Install? |
|--------|---------|---------|
| Dataview | Query notes like a database (`WHERE status = "ACTIVE-BUILD"`) | Yes |
| Templater | Auto-fill frontmatter, create notes from templates | Yes |
| Git | Auto-sync vault to GitHub | Yes |
| Calendar | Navigate notes by date | Optional |
| Canvas | Visual project maps | Optional |

Do NOT install: Smart Connections (security), Copilot (redundant), or any plugin with fewer than 10k downloads unless you've read its source.

---

*See also: `PLAYBOOK.md` Part 4 for the complete Knowledge Layer reference, `docs/AGENTS-GUIDE.md` for how agents use the vault.*
