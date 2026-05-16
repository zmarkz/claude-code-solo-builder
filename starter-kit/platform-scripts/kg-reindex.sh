#!/bin/bash
# Rebuild the knowledge-graph index over ~/Obsidian/Builds
# Safe to run anytime — incremental update, not a full rebuild from scratch

set -euo pipefail

KG_DIR="$HOME/builds/_knowledge-graph"
VAULT_PATH="$HOME/Obsidian/Builds"
LOG_DIR="$HOME/logs"

mkdir -p "$LOG_DIR"

echo "[kg-reindex] $(date '+%Y-%m-%d %H:%M:%S') — starting"

cd "$KG_DIR"
KG_VAULT_PATH="$VAULT_PATH" \
  npx --prefix "$KG_DIR" tsx "$KG_DIR/src/cli/index.ts" index \
  2>&1 | tee -a "$LOG_DIR/kg-reindex.log" | tail -3

echo "[kg-reindex] $(date '+%Y-%m-%d %H:%M:%S') — done"
