# ADR 0007 — Native-first alignment and remote operations

**Status:** Accepted
**Date:** 2026-11-06
**Deciders:** Markandey (with Claude)

## Context

Three problems surfaced together after the kit went unsynced for almost six months:

1. **The freshness check could not fail.** The monthly `/sync-skills` reminder only fired when a
   stamp file existed, and the stamp was never written on this machine. The drift check compares
   the repo with `~/.claude`, so it reported "0 drift" while gstack sat 474 commits behind.
2. **Pinned model IDs go stale silently.** A project pin to a full ID kept sessions on an older model
   after a newer one shipped, overriding `/model` on every restart. Aliases already resolve to the
   latest model of each tier.
3. **The local RAG reindex was destroying indexes.** `leann build` without `--force` replaces an index
   with only the changed files. One real project's index had shrunk to 17 of 3,308 tracked files.

Separately, working from a phone for days needs sessions in any repo without a terminal kept open by
hand, and Remote Control servers exit after about 10 minutes without network.

## Decision

- **Native first.** `docs/NATIVE-FIRST.md` routes each need to the native feature and states when a kit
  tool still earns its place. No command is removed in this release: this is routing, and removing
  anything needs evidence that it goes unused.
- **Tiers, not versions.** Docs name model tiers, code uses aliases, and the session check warns when a
  project pins a full model ID. Accepted ADRs and the changelog keep their historical names.
- **The reminder fails loud.** A missing stamp now means overdue, using the last sync record as a fallback.
- **Reindex with `--force`, throttled.** Every reindex re-embeds the whole repo, at most once per
  `RAG_MIN_INTERVAL_SEC` (default 30 minutes), and `/rag-status` reports file coverage.
- **`remote-fleet.sh` ships in the public kit.** Personal repo lists stay in the private overlay.

## Why servers run under Terminal

macOS privacy controls refuse launchd jobs access to `~/Documents`, `~/Desktop` and `~/Downloads`
without Full Disk Access (tested: `Operation not permitted`). Hosting servers under Terminal keeps its
existing access and needs no security change. launchd runs only a watchdog that reopens the supervisor.

## Alternatives rejected

- **A custom remote-control app.** It would add a new way into a browser holding every password, with no
  capability beyond OS screen sharing over a private network.
- **tmux as the host.** Removed from the personal setup earlier because it was hanging sessions.
- **Accepting workspace trust by editing `~/.claude.json`.** That prompt is a check for a person, so the
  fleet reports `needs-trust` and starts the server once it has been accepted.

## Consequences

- A rebuild of a large repo's index takes real time, so the index can lag edits by up to 30 minutes.
- Existing indexes stay damaged until rebuilt with `rag-reindex.sh --now`.
- A machine set to `bypassPermissions` with Chrome enabled is only as safe as the Claude account, which
  `docs/REMOTE-OPS.md` states plainly. The default remains `default`.
