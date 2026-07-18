---
description: Build (or rebuild) the local LEANN RAG index for this project. Run once per project; the PostToolUse hook keeps it fresh afterward. Safe to re-run.
---

Build the project's local semantic code index (see the kit's `docs/LOCAL-RAG.md`).
Everything runs locally — nothing leaves the machine.

## 1. Preflight

Check each prerequisite, collecting misses instead of stopping (print the exact
remedy for each miss):

```bash
export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null    || echo "MISS uv      → brew install uv"
command -v leann >/dev/null || echo "MISS leann   → uv tool install leann-core --with leann --with docx2txt"
command -v ollama >/dev/null || echo "MISS ollama  → brew install ollama"
ollama list 2>/dev/null | grep -q nomic-embed-text || echo "MISS model   → ollama pull nomic-embed-text"
claude mcp list 2>/dev/null | grep -q leann-server || echo "MISS mcp     → claude mcp add --scope user leann-server -- leann_mcp"
```

- The `claude mcp add` command is **user-level config — tell the user to run it
  themselves; never run it from this command.**
- If `leann` or the embedding model is missing after printing remedies: stop
  with "re-run /rag-init after installing".

## 2. Wiring check

- `scripts/rag-reindex.sh` exists and is executable. If missing (retrofitted
  project): `cp ~/.claude/skills/ai-project-scaffold/reference/scripts/rag-reindex.sh scripts/ && chmod +x scripts/rag-reindex.sh`.
- `.gitignore` contains a `.leann/` line — append if not.
- `.claude/settings.json` has the PostToolUse entry
  `{"matcher": "Write|Edit", "hooks": [{"type": "command", "command": "bash scripts/rag-reindex.sh"}]}` —
  if absent, show the user this JSON block to add (project settings may be customized; don't clobber).

## 3. Build

```bash
INDEX_NAME="$(basename "$PWD" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-')"
leann build "$INDEX_NAME" --docs $(git ls-files | grep -ivE '\.(png|jpe?g|gif|svg|ico|icns|webp|bmp|mp3|wav|m4a|ogg|flac|mp4|mov|avi|webm|mkv|xls|xlsx|ppt|pptx|csv|zip|gz|tgz|tar|7z|rar|woff2?|ttf|otf|eot|jar|class|pyc|so|dylib|bin|sqlite|db)$') \
  --file-types ".md,.mdx,.txt,.ts,.tsx,.js,.jsx,.mjs,.cjs,.json,.py,.java,.kt,.go,.rs,.rb,.php,.swift,.c,.h,.cpp,.hpp,.cs,.sh,.bash,.fish,.zsh,.yaml,.yml,.toml,.ini,.cfg,.sql,.html,.css,.scss,.vue,.svelte,.xml,.gradle,.properties,.tf,.proto,.graphql,.prisma" \
  --embedding-mode "${RAG_EMBEDDING_MODE:-ollama}" \
  --embedding-model "${RAG_EMBEDDING_MODEL:-nomic-embed-text}" \
  --use-ast-chunking --ast-fallback-traditional
```

- Requires a git repo with tracked files (`git ls-files` non-empty). If the
  project isn't committed yet: `git init && git add -A && git commit` first.
- Re-running is safe and incremental (Merkle diff — only changed files re-embed).

## 4. Smoke test

```bash
leann search "$INDEX_NAME" "where is the main entry point"
```

Show the top result. If empty, check `.leann/reindex.log` and `leann list`.

## 5. Report

- Index name + location (`.leann/indexes/<name>`), file count, build time.
- How Claude uses it: the CLAUDE.md "search before you grep" rule — semantic
  questions go through one LEANN MCP search call instead of grep/read loops.
- Freshness: the PostToolUse hook reindexes in the background after edits;
  `/rag-status` for troubleshooting.
