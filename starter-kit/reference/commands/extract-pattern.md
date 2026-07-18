---
description: Save a reusable module/pattern from this project into the user-level pattern library (~/.claude/patterns/), indexed for cross-project reuse search. Run after building something worth reusing.
argument-hint: <module name or path, e.g. "model picker" or src/components/ModelPicker.tsx>
---

Extract a reusable pattern: **$ARGUMENTS**

The pattern library is what `/plan-feature` Step 0.6 and `/build-feature`'s reuse
guard search before anything gets rebuilt from scratch. A pattern note is a
*pointer + contract*, not a code copy — the source stays in its project.

## 1. Locate and understand the module

- If $ARGUMENTS is a path, read it (plus its immediate imports/tests). If it's a
  name, find it (LEANN search or grep) and confirm the path with the user.
- Interview briefly (one question at a time, only what the code doesn't answer):
  what problem it solves, its public API surface, hard dependencies, what would
  need to change to lift it into another project.

## 2. Write the pattern note

Write `~/.claude/patterns/<kebab-slug>.md`:

```markdown
---
name: <kebab-slug>
source_project: <project name>
source_path: <repo-relative path(s)>
stack: [<e.g. nextjs, ts, supabase>]
tags: [<capability tags, e.g. model-picker, llm, ui>]
extracted: <YYYY-MM-DD>
---
# <Human name>

## What it does
<2-3 sentences — the problem it solves and for whom.>

## Public API / contract
<The interface another project would consume — props, function signatures, endpoints.>

## Dependencies
<Hard deps and versions that travel with it.>

## How to reuse
<Copy-and-adapt steps, or "extract to packages/shared first because …">

## Gotchas
<Anything that bit you — coupling, assumptions, env needs.>
```

Never overwrite an existing pattern note silently — show a diff and ask.

## 3. Index the library

```bash
export PATH="$HOME/.local/bin:$PATH"
command -v leann >/dev/null && \
  leann build patterns --docs "$HOME/.claude/patterns" \
    --embedding-mode "${RAG_EMBEDDING_MODE:-ollama}" \
    --embedding-model "${RAG_EMBEDDING_MODEL:-nomic-embed-text}" \
  || echo "leann not installed — pattern saved but unindexed (searchable after /rag-init prereqs)"
```

## 4. Vault mirror (only if the vault module is on)

```bash
CONFIG="${CLAUDE_HOME:-$HOME/.claude}/solo-builder.config"
[ -f "$CONFIG" ] && . "$CONFIG"
[ -n "${VAULT_PATH:-}" ] && cp "$HOME/.claude/patterns/<slug>.md" "$VAULT_PATH/05-Patterns/<slug>.md"
```

## 5. Report

Pattern name, file path, indexed (yes/no), vault-mirrored (yes/no), and one
line on when this pattern will surface (plan-feature reuse check hits on its
tags/description).
