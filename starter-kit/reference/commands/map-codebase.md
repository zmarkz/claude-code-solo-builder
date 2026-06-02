---
description: Build an architecture brief of this repo via the codebase-map Workflow (parallel multi-modal readers + completeness critic). Read-only — good for onboarding or refactor-prep.
---

Run the **`codebase-map`** saved workflow on this repository.

1. Launch it as a Dynamic Workflow, forwarding the active session profile:
   `Workflow({ name: 'codebase-map', args: { mode: <best|saver — the profile set by /mode, default best>, repoPath: '.' } })`.
2. It is **read-only** and safe: parallel readers sweep the tree in distinct modes (modules, data model, integrations, tests, build/CI, domain language), a brief is synthesized, and a completeness critic triggers a gap re-pass.
3. Runs as a workflow (explicit opt-in); cheaper than the review/audit recipes but still more than a normal turn.
4. When it returns, present the **architecture brief** — overview, components, primary data flow, key paths a new contributor must know, and risks.
