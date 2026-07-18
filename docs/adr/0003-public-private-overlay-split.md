# ADR 0003 — Public/private overlay split (v3.0)

**Status:** Accepted
**Date:** 2026-07-18
**Deciders:** Markandey (with Claude)

## Context

The repo billed itself as generic but was coupled to the author's machine:
install.sh synced personal platform scripts to `~/builds/_platform/scripts`,
five docs described the author's apps/infra (Agent Farm routing, Zerodha
examples, Telegram fleet digest, Obsidian vault wiring), the PLAYBOOK carried
79 personal references, settings templates required a manual `/YOUR_HOME`
find-and-replace, and sync-skills tracked the author's private knowledge-graph
tool. A third party could not clone-and-install without inheriting or manually
stripping all of it. The three ADR tests all pass: hard to reverse (layout +
install contract change), surprising without context (why files vanished),
result of a real trade-off (see alternatives).

## Decision

1. **This repo becomes 100% generic.** Anyone can: clone → `make install` →
   `/sync-project` in any project. No personal paths, apps, currencies, or
   services remain (Razorpay/ap-south-1 survive only as labeled examples).
2. **Personal content moves to a private overlay repo** (`solo-builder-private`)
   holding: the 4 personal platform scripts, personal docs (moved whole or
   extracted halves), `sources.local.json`, and `solo-builder.config`. Its
   installer runs the public installer first, then overlays — install order is
   the entire layering mechanism.
3. **Values are config, content is overlay.** The public kit reads one optional
   shell-sourceable file `~/.claude/solo-builder.config` (template shipped) with
   `VAULT_PATH` and `VAULT_REINDEX_CMD`. The vault module is dormant/silent when
   `VAULT_PATH` is unset; enabling it is one config line — no overlay required
   for third parties.
4. **Generic hook scripts move into the repo** (top-level `scripts/`, synced
   additively to `~/.claude/scripts/`), so settings templates reference
   `$HOME`-based paths and the `/YOUR_HOME` placeholder era ends. install.sh
   drops the platform-scripts op entirely.
5. **sync-skills merges local sources**: `~/.claude/sync-skills/sources.local.json`
   (concat by `id`, local wins). It lives in the state dir because the skill dir
   is `--delete`-synced. Plugin-marketplace sources are tracked metadata-only;
   updates always go through `claude plugin update`.

## Consequences

- Third parties get a working kit with zero personal residue; the author's
  environment is reproduced by two repos instead of one (`overlay install.sh`
  is the single entry point).
- Breaking for existing installs: session-check hooks moved from
  `~/builds/_platform/scripts/` to `~/.claude/scripts/` — live settings.json
  needs a one-time path update (install.sh warns about the old path).
- Git history keeps the personal color of v1–v2.5 (verified: no secrets, no
  internal project names in any commit). Delete-going-forward; no rewrite.
- Model references switched from pinned IDs to aliases (`opus`/`sonnet`/`haiku`)
  — retired-model hard-failures are structurally eliminated; per-tier retuning
  is deferred to the platform-doctrine refresh (v3.2).
