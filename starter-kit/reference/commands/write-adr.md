---
description: Write an Architecture Decision Record at docs/adr/NNNN-<slug>.md using the kit's template and 3-test threshold. Vault-mirrored when the vault module is on.
argument-hint: <one-line decision, e.g. "use per-tenant MinIO buckets">
---

Write an ADR for: **$ARGUMENTS**

## 1. Apply the 3-test threshold first

An ADR is warranted only if ALL three hold — otherwise say so and stop:
1. **Hard to reverse** — undoing it later is expensive.
2. **Surprising without context** — a future reader would ask "why on earth?".
3. **Result of a real trade-off** — a credible alternative was rejected.

## 2. Number and write

- Next number = highest existing `docs/adr/NNNN-*.md` + 1 (monotonic, never
  reuse; create `docs/adr/` + `INDEX.md` if missing).
- Follow the structure of `examples/ADR-NNNN-template.md.example` (Status /
  Date / Deciders, Context, Decision, Alternatives considered, Consequences —
  including the negative ones).
- Keep it under a page. Link related ADRs and the feature spec if one exists.
- Add a line to `docs/adr/INDEX.md`.

## 3. Vault mirror (only if the vault module is on)

```bash
CONFIG="${CLAUDE_HOME:-$HOME/.claude}/solo-builder.config"
[ -f "$CONFIG" ] && . "$CONFIG"
if [ -n "${VAULT_PATH:-}" ]; then
  PROJECT="$(basename "$PWD")"
  mkdir -p "$VAULT_PATH/01-Projects/$PROJECT"
  cp docs/adr/<NNNN-slug>.md "$VAULT_PATH/01-Projects/$PROJECT/"
fi
```

(ADRs live in `01-Projects/<project>/` in the vault — never at the vault root.)

## 4. Report

ADR number, path, one-line decision, vault-mirrored (yes/no).
