# ADR 0004 — Per-project local RAG via LEANN

**Status:** Accepted
**Date:** 2026-07-18
**Deciders:** Markandey (with Claude)

## Context

The kit's knowledge layer stopped at the (optional) curated vault — no semantic
retrieval over code existed. All code exploration was Glob/Grep/Read loops:
5–15 agent turns and large irrelevant context per "where is X?" question, spent
against the weekly usage cap that is the binding constraint on Max plans. The
user also wants cross-project module reuse ("model picker exists in app A —
don't rebuild it in app B"), which requires portfolio-wide semantic search.

All three ADR tests pass: adds a permanent module + hook to every scaffold
(hard to reverse cheaply), a RAG engine choice is surprising without context,
and real alternatives were rejected.

## Decision

1. **Engine: LEANN**, direct (no abstraction layer). Zero-daemon, plain files
   in `<project>/.leann/` (gitignored), incremental Merkle rebuilds, AST-aware
   chunking (`--use-ast-chunking`), local embeddings via Ollama
   `nomic-embed-text` (MLX supported via env override). Verified against the
   CLI: build == reindex (idempotent), `leann list` discovers all indexes.
2. **Exposure: one user-scope MCP server** (`claude mcp add --scope user
   leann-server -- leann_mcp`) — per-project index data, portfolio-wide search.
3. **Wiring: 10th guardrail script** `scripts/rag-reindex.sh` on PostToolUse
   Write|Edit — lockfile-debounced (5s), background, logs to
   `.leann/reindex.log`, dormant until an index exists. Claude-hook (not git
   hooks) because freshness matters mid-session, when retrieval actually fires.
4. **Init: opt-out.** Scaffold Q12 defaults yes; graceful degradation
   everywhere (missing prereqs print exact remedies, never fail the scaffold;
   `/rag-init` is the deferred/retrofit path). The scaffold never modifies
   user-level config — MCP registration is check-and-instruct.
5. **Reuse layer on top:** `/plan-feature` Step 0.6 (cross-index search before
   scoping), `/build-feature` reuse guard, `/extract-pattern` →
   `~/.claude/patterns/` with its own `patterns` index (vault-mirrored to
   `05-Patterns/` when the vault module is on).
6. **Engine isolation (isolate-and-defer):** every engine invocation lives in
   exactly three places — `rag-reindex.sh`, `/rag-init`, and one build line in
   `/extract-pattern`. No multi-engine adapter is built.

## Alternatives rejected

- **Status quo (grep-only):** works — published evals put agentic search at
  ~90% of RAG answer quality — but pays in turns/tokens against the weekly cap.
  This caveat is retained honestly in docs/LOCAL-RAG.md: the win is
  turns/tokens/speed, not a step-change in quality.
- **pgvector/Postgres pipeline (e.g. extending knowledge-store):** a daemon,
  a schema, and Docker for a job plain files do; drags app-runtime infra into
  dev tooling.
- **zilliztech/claude-context:** strong (AST + hybrid BM25) but requires a
  permanent Milvus container. Named FALLBACK: adopt if LEANN retrieval
  disappoints on large/legacy polyglot code after ~2 weeks of real use — the
  3-file isolation makes the swap cheap.
- **Cloud embeddings:** violates the local-only requirement.
- **Multi-engine adapter now:** speculative flexibility for a second engine
  that may never be needed.

## Consequences

- One retrieval call replaces grep loops; portfolio-wide reuse search becomes
  possible; all data stays local.
- New user-level prerequisites (uv, LEANN, Ollama model) — mitigated by
  graceful degradation and `/rag-init`'s printed remedies.
- Embedding builds cost local compute (seconds to minutes per project);
  out-of-band edits leave the index briefly stale (session-start warns).
- Success metric: fewer exploration turns per session. Re-evaluate engine
  choice after two weeks of measurement (see PR 2c rollout).
