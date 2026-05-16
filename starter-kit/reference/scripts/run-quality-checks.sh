#!/usr/bin/env bash
# scripts/run-quality-checks.sh
# Hook: PostToolUse on Write/Edit, AND used by `make quality`.
#
# Mode:
#   (no args)         Full quality gate: lint + typecheck + tests + security.
#   --changed-only    Limit to files changed in the last commit / staged. Used
#                     by the post-tool-use hook to keep iteration fast.
#
# This script auto-detects which app directories exist (apps/api, apps/web,
# packages/*, etc.) and runs the appropriate tooling. Empty / nonexistent dirs
# are skipped — useful during phase 0/1 when not everything is scaffolded yet.

set -euo pipefail

cd "$(dirname "$0")/.."

MODE="${1:-full}"

run_step() {
  local name="$1"; shift
  echo "─── $name ───"
  if "$@"; then
    echo "  ok: $name"
  else
    echo "  FAIL: $name" >&2
    return 1
  fi
}

# --- Determine which scopes to run ---
have_api=false; have_web=false
[ -f apps/api/pyproject.toml ] && have_api=true
[ -f apps/web/package.json ] && have_web=true

# --- Lint + format ---
if $have_api; then
  run_step "ruff (api)"     bash -c 'cd apps/api && uv run ruff check .'
  run_step "black (api)"    bash -c 'cd apps/api && uv run black --check .'
fi
if $have_web; then
  run_step "eslint (web)"   bash -c 'cd apps/web && pnpm -s lint'
  run_step "prettier (web)" bash -c 'cd apps/web && pnpm -s prettier --check .'
fi

# --- Typecheck ---
if [ "$MODE" = "full" ]; then
  if $have_api; then
    run_step "mypy (api)"     bash -c 'cd apps/api && uv run mypy app'
  fi
  if $have_web; then
    run_step "tsc (web)"      bash -c 'cd apps/web && pnpm -s typecheck'
  fi
fi

# --- Tests ---
if [ "$MODE" = "full" ]; then
  if $have_api; then
    run_step "pytest (api)"   bash -c 'cd apps/api && uv run pytest -q'
  fi
  if $have_web; then
    run_step "vitest (web)"   bash -c 'cd apps/web && pnpm -s test'
  fi
fi

# --- Security ---
if [ "$MODE" = "full" ]; then
  run_step "secret-scan"      bash scripts/secret-scan.sh
fi

# Note: this script is intentionally lenient about missing app directories so it
# works during phase 0 (planning only) and phase 1 (apps being scaffolded). Once
# both apps are present and you want strictness, replace the `if $have_*` guards
# with hard requirements.

exit 0
