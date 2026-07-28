# Local RAG — per-project semantic code search

> Verified against LEANN CLI (July 2026) — see ADR 0004 for the engine decision.

Every project initialized with this kit can carry a **local semantic index** of
its own code and docs. Claude answers "where is X / how does Y work" questions
with **one retrieval call** instead of a multi-turn grep→read→grep loop.
Everything runs on your machine — embeddings via Ollama (or MLX), index as
plain files in `<project>/.leann/` — nothing leaves the laptop.

## Why (the economics)

A grep-exploration loop typically costs 5–15 agent turns and pulls tens of
thousands of irrelevant tokens into context. A RAG lookup is one MCP call
returning ~1–2K tokens of relevant chunks, and the embedding search itself
costs **zero LLM tokens**. If your constraint is a weekly usage cap (see
`docs/TOKEN-EFFICIENCY.md`), this is directly cap money.

**The honest caveat:** agentic (grep-based) search reaches ~90% of RAG answer
quality in published evals. The win here is *turns, tokens, and speed* — with a
modest quality lift from AST-aware chunking — not a transformation. That's why
the module is opt-out rather than mandatory doctrine.

## Prerequisites (one-time, user level)

```bash
brew install uv ollama                      # if missing
uv tool install leann-core --with leann --with docx2txt   # the LEANN CLI (+ Word-file parser)
ollama pull nomic-embed-text                # local embedding model (274 MB)
claude mcp add --scope user leann-server -- leann_mcp   # one MCP server, all projects
```

(`--with docx2txt` matters: if any tracked file is a `.docx`, LEANN's build
dies with an ImportError without it.)

## Lifecycle

| Moment | What happens |
|---|---|
| Scaffold (new project) | Q12 asks "Local RAG index?" (default yes); wiring always ships; build usually defers to `/rag-init` (needs a git repo) |
| Existing project | `/rag-init` — preflight, wiring check, build, smoke test |
| Every Claude edit | `scripts/rag-reindex.sh` (PostToolUse hook) — debounced background rebuild (Merkle diff; pure additions update incrementally, modifications trigger a fast full rebuild — ~20s at solo-project scale) |
| Session start | `session-start.sh` warns if the index is behind HEAD |
| Trouble | `/rag-status` — freshness, log tail, MCP registration |

The index is scoped by `git ls-files` (gitignore filtering for free), chunked
AST-aware (`--use-ast-chunking`), and `.leann/` is gitignored — machine-local
and rebuildable, never committed.

## Portfolio coverage & cross-project reuse

Run `/rag-init` in **each** project. The user-scope MCP server sees every
index (`leann list`), so searches can span your whole portfolio. That powers
the kit's reuse loop:

- `/plan-feature` **Step 0.6** searches the pattern library + other projects'
  indexes before scoping a new module — "model-picker already exists in app-X;
  reuse / extract / reimplement?"
- `/extract-pattern` saves reusable modules to `~/.claude/patterns/` (its own
  `patterns` index), so curated reuse hits don't depend on raw code search.
- `/build-feature`'s reuse guard catches modules that emerge mid-build.

## Per-project tuning (`scripts/rag-reindex.conf`)

`scripts/rag-reindex.sh` is a kit-owned **template** — `/sync-project` may
refresh it, so never patch it in place. Durable tuning lives in
`scripts/rag-reindex.conf`: project-owned, committed with the project, sourced
by the script, and never overwritten by the kit.

```bash
# scripts/rag-reindex.conf — every line optional
RAG_EXCLUDE_DIRS='node_modules|vendor|dist|build|\.next|__pycache__|legacy'
RAG_EXCLUDE_EXTS='png|jpe?g|gif|svg|mp3|m4a|mp4|xlsx|zip|pdf'
RAG_FILE_TYPES='.md,.ts,.tsx,.sql'
RAG_EMBEDDING_MODE=mlx        # or: ollama | sentence-transformers | openai
RAG_EMBEDDING_MODEL=<model>
```

The same variables work as session env vars for one-off experiments.
`/rag-init` builds via `bash scripts/rag-reindex.sh --now`, so the initial
build and the hook's background rebuilds share one code path — tune once,
applies everywhere.

## Troubleshooting

- **`/rag-status`** is the entry point — it names the single remedy.
- Reindex log: `.leann/reindex.log`. Stuck lock: `rm .leann/reindex.lock`.
- Rebuild from scratch: `rm -rf .leann && /rag-init` (indexes are disposable).
- Retrieval quality poor (esp. large polyglot/legacy code)? The pre-vetted
  fallback engine is `zilliztech/claude-context` (AST + hybrid BM25, needs a
  Milvus container). All engine calls live in `scripts/rag-reindex.sh` (which
  `/rag-init` calls via `--now`) and one line of `/extract-pattern` — swapping
  engines is a 2-file change. See ADR 0004.
