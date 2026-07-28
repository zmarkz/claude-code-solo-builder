#!/usr/bin/env bash
# scripts/rag-reindex.sh
# Hook: PostToolUse on Write/Edit (from .claude/settings.json), AND runnable
# manually / from /rag-init (`--now` = foreground build, no debounce/lock).
# Incrementally reindexes the project's local LEANN RAG index in the
# background, debounced via a lockfile. Non-blocking — a no-op unless the
# index exists and the leann CLI is installed.
#
# TEMPLATE — do not patch this file in place. /sync-project may refresh it
# from the kit. Durable per-project tuning (excludes, file types, embedding
# model) belongs in scripts/rag-reindex.conf — committed with the project,
# sourced below, never touched by the kit.
# See docs/LOCAL-RAG.md (kit repo) for the module guide.

set -euo pipefail

cd "$(dirname "$0")/.."

MODE="hook"
[ "${1:-}" = "--now" ] && MODE="now"

# Dormant unless the project has an index (built by /rag-init or the scaffold).
# --now (the initial build, called by /rag-init) skips the guard.
if [ "$MODE" = "hook" ] && [ ! -d .leann ]; then exit 0; fi

# uv tool installs land in ~/.local/bin, which hook shells may not have on PATH.
export PATH="$HOME/.local/bin:$PATH"

if ! command -v leann >/dev/null 2>&1; then
  echo "[rag] leann CLI not found — index is stale. Install: uv tool install leann-core --with leann --with docx2txt"
  [ "$MODE" = "now" ] && exit 1
  exit 0
fi

INDEX_NAME="$(basename "$PWD" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-')"
LOCK_FILE=".leann/reindex.lock"
LOG_FILE=".leann/reindex.log"
# Text/code allowlist passed to LEANN's reader. Without it the per-DIRECTORY
# loader scans listed dirs and chokes on media it finds there (.m4a → Whisper).
RAG_FILE_TYPES="${RAG_FILE_TYPES:-.md,.mdx,.txt,.ts,.tsx,.js,.jsx,.mjs,.cjs,.json,.py,.java,.kt,.go,.rs,.rb,.php,.swift,.c,.h,.cpp,.hpp,.cs,.sh,.bash,.fish,.zsh,.yaml,.yml,.toml,.ini,.cfg,.sql,.html,.css,.scss,.vue,.svelte,.xml,.gradle,.properties,.tf,.proto,.graphql,.prisma}"
# Pruned from git ls-files before the build: vendored/build dirs, and
# media/binary extensions LEANN would otherwise try to parse (mp3 wants
# Whisper, xlsx wants openpyxl — none of it helps code retrieval).
RAG_EXCLUDE_DIRS="${RAG_EXCLUDE_DIRS:-node_modules|vendor|dist|build|\.next|__pycache__}"
RAG_EXCLUDE_EXTS="${RAG_EXCLUDE_EXTS:-png|jpe?g|gif|svg|ico|icns|webp|bmp|mp3|wav|m4a|ogg|flac|mp4|mov|avi|webm|mkv|xls|xlsx|ppt|pptx|csv|zip|gz|tgz|tar|7z|rar|woff2?|ttf|otf|eot|jar|class|pyc|so|dylib|bin|sqlite|db}"

# Per-project overrides — the durable home for reindex tuning. Never
# overwritten by /sync-project or the scaffold.
[ -f scripts/rag-reindex.conf ] && . scripts/rag-reindex.conf

run_build() {
  # leann build is idempotent/incremental (Merkle diff: only changed files are
  # re-embedded). git ls-files keeps the scope gitignore-filtered.
  # NOTE: can hit ARG_MAX on very large repos — if that happens, tighten
  # RAG_EXCLUDE_* in scripts/rag-reindex.conf or switch to --docs . there.
  # shellcheck disable=SC2046
  leann build "$INDEX_NAME" --docs $(git ls-files | grep -vE "(^|/)($RAG_EXCLUDE_DIRS)/" | grep -ivE "\.($RAG_EXCLUDE_EXTS)\$") \
    --file-types "$RAG_FILE_TYPES" \
    --embedding-mode "${RAG_EMBEDDING_MODE:-ollama}" \
    --embedding-model "${RAG_EMBEDDING_MODEL:-nomic-embed-text}" \
    --use-ast-chunking --ast-fallback-traditional
}

if [ "$MODE" = "now" ]; then
  # Foreground initial/full build for /rag-init — streams output to the caller.
  run_build
  exit 0
fi

# Debounce: one queued/running reindex at a time.
[ -f "$LOCK_FILE" ] && exit 0
touch "$LOCK_FILE"

(
  sleep 5   # absorb bursts of rapid successive edits
  {
    echo "[rag-reindex] $(date '+%Y-%m-%d %H:%M:%S') — starting ($INDEX_NAME)"
    run_build
    echo "[rag-reindex] $(date '+%Y-%m-%d %H:%M:%S') — done"
  } >> "$LOG_FILE" 2>&1 || echo "[rag-reindex] FAILED — see $LOG_FILE" >> "$LOG_FILE"
  rm -f "$LOCK_FILE"
) &

exit 0
