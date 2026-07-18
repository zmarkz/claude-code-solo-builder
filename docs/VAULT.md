# Knowledge Vault (optional module)

> An optional, curated knowledge layer for your build portfolio: ADRs, cross-app patterns, and
> per-project INDEX notes that make each new project cheaper and smarter to build.
> **Off by default** — the kit runs fine without it.

---

## What it is

A knowledge vault is a plain-markdown directory (an Obsidian vault, or any folder of `.md` files)
that holds the *durable* knowledge your building produces:

- **ADRs** — architecture decisions, so you never re-litigate the same trade-off
- **Patterns** — reusable solutions abstracted across apps (auth, tenancy, routing, …)
- **Project INDEX notes** — one per project: what it does, its stack, current state

It is distinct from code (which lives in repos) and from session memory (which the kit's native
`MEMORY.md` already handles). The vault is the *cross-project* layer — the compound interest of
everything you have built.

It follows six rules (after Andrej Karpathy's "LLM Wiki" pattern) that keep it navigable:

1. **Few page types** — `entity`, `concept`, `synthesis`, `source`, `report`
2. **Search before write** — look for an existing note before creating one
3. **Backlinks mandatory** — every note links to ≥1 other note
4. **Contradictions flagged on the page**, never silently overwritten
5. **Attribution in frontmatter** — `created_by`, `last_edited_by`
6. **One vault** — no subvaults, no parallel hierarchies

---

## Off by default

The vault module is dormant until you point the kit at a vault directory. Set `VAULT_PATH` in
`~/.claude/solo-builder.config`:

```bash
# ~/.claude/solo-builder.config
VAULT_PATH="$HOME/path/to/your/vault"
```

With no `VAULT_PATH`, every vault hook and command is a no-op — nothing runs, nothing warns. One
line enables the whole module; deleting it disables it.

---

## Recommended structure

A PARA-style layout keeps the vault predictable across projects:

```
$VAULT_PATH/
├── 00-Inbox/       ← Capture everything here first, process weekly
├── 01-Projects/    ← One folder per active app; each has an INDEX.md
│   └── <app>/INDEX.md
├── 02-Areas/       ← Ongoing themes (pricing, distribution, AI-stack)
├── 03-Resources/   ← Snippets, vendor docs, references
├── 04-Archive/     ← Killed apps + postmortems (keep forever)
└── 05-Patterns/    ← Patterns before they graduate into skills
```

The load-bearing convention: **one `INDEX.md` per project** in `01-Projects/<app>/`, describing what
the app does, its stack, and its current state. Everything else is optional depth.

---

## How the kit uses it

When `VAULT_PATH` is set, the kit wires the vault in at four touch-points — all generic, none
requiring Obsidian to be running:

- **Session-start freshness check** — `~/.claude/scripts/vault-session-check.sh` runs on
  `SessionStart` and warns when the current project's `INDEX.md` is missing or stale (>7 days), so
  you know when to refresh it.
- **`/vault-update` command** — writes or refreshes the current project's `INDEX.md` from its
  `CLAUDE.md`, roadmap, and recent git log, then triggers a re-index.
- **Optional re-index hook** — if you run your own indexer (SQLite, vectors, full-text), set
  `VAULT_REINDEX_CMD` in the config and the kit calls it after vault writes. Omit it and nothing
  re-indexes.
- **Optional MCP registration** — register a `vault-files` (filesystem) and/or `knowledge-graph`
  MCP server against `$VAULT_PATH` for `kg_search`-style retrieval. Vault-first retrieval (search
  the vault before starting a non-trivial task) is what turns the vault into a cost saving — see
  `docs/TOKEN-EFFICIENCY.md` Strategy 4.

---

## What does NOT belong

The vault is for *curated, durable, cross-project* knowledge. Two things look like they belong but
do not:

- **Code retrieval** — "find me the function that does X" is a job for a code-aware index, not the
  vault. That is the upcoming **Local RAG module**, not this one. Keep source out of the vault.
- **Session learnings** — "what we figured out this session" is handled by the kit's native
  `MEMORY.md`. Do not duplicate it into the vault; promote only the *durable* distillate (a pattern,
  an ADR) when it is worth keeping across projects.

---

*The vault is optional. If you never set `VAULT_PATH`, ignore this doc entirely — nothing in the kit
depends on it.*
