#!/usr/bin/env bash
# scripts/secret-scan.sh
# Full secret scan for the repo. Used by `make security`, pre-commit, and CI.
#
# Modes:
#   (no args)     Scan the whole working tree.
#   --staged      Scan only files staged for commit (used by pre-commit).
#   --diff        Scan only the diff vs default branch (used in PR CI).

set -euo pipefail

cd "$(dirname "$0")/.."

MODE="${1:-full}"

# Prefer gitleaks if available.
if command -v gitleaks >/dev/null 2>&1; then
  case "$MODE" in
    --staged) gitleaks protect --staged --redact -v ;;
    --diff)   gitleaks detect --log-opts="main..HEAD" --redact -v ;;
    *)        gitleaks detect --redact -v ;;
  esac
  echo "  gitleaks: clean"
else
  echo "  gitleaks not installed — falling back to custom patterns."
fi

# Custom patterns layered on top of gitleaks (project-specific additions can be appended).
PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'ASIA[0-9A-Z]{16}'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'xox[abprs]-[A-Za-z0-9-]{10,}'
  'ghp_[A-Za-z0-9]{36}'
  'gho_[A-Za-z0-9]{36}'
  'sk-ant-[A-Za-z0-9-]{32,}'
  'sk-[A-Za-z0-9]{40,}'
  'AIza[0-9A-Za-z\-_]{35}'
)

case "$MODE" in
  --staged)
    files=$(git diff --cached --name-only --diff-filter=ACMR)
    ;;
  --diff)
    files=$(git diff --name-only --diff-filter=ACMR main..HEAD 2>/dev/null || git diff --name-only --diff-filter=ACMR master..HEAD 2>/dev/null || true)
    ;;
  *)
    files=$(git ls-files)
    ;;
esac

violations=0
for pattern in "${PATTERNS[@]}"; do
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in
      *.lock|*lock.json|pnpm-lock.yaml|yarn.lock|uv.lock|poetry.lock|Cargo.lock) continue ;;
      scripts/check-secrets-staged.sh|scripts/secret-scan.sh) continue ;;
      .env.example) continue ;;
    esac
    [ -f "$f" ] || continue
    if grep -nE -- "$pattern" "$f" >/dev/null 2>&1; then
      echo "VIOLATION: $f matches /$pattern/" >&2
      grep -nE -- "$pattern" "$f" | head -3 >&2 || true
      violations=$((violations+1))
    fi
  done <<< "$files"
done

if [ "$violations" -gt 0 ]; then
  echo ""
  echo "$violations secret-like match(es). Mask, remove, or move to .env." >&2
  exit 1
fi

echo "  custom patterns: clean"
exit 0
