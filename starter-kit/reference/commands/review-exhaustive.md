---
description: Deep multi-lens review of the current diff via the exhaustive-review Workflow (parallel reviewers + adversarial verification, false positives killed by skeptics). For a fast single-agent pass use /review-security.
---

Run the **`exhaustive-review`** saved workflow on the current diff.

1. Confirm there is something to review: `git status --porcelain` / `git diff main...HEAD`. If the tree is clean vs `main`, say so and stop.
2. Launch it as a Dynamic Workflow, forwarding the active session profile:
   `Workflow({ name: 'exhaustive-review', args: { mode: <best|saver — the profile set by /mode this session, default best> } })`.
3. This runs as a workflow (explicit opt-in) and costs meaningfully more tokens than `/review-security` — that's the trade for breadth (one reviewer per lens) + adversarial verification (skeptics kill false positives). For a fast single-agent per-diff pass, use `/review-security` instead.
4. When it returns, present the synthesized report — **Must-fix / Should-fix / Nits** — with `file:line` citations and the overall verdict.
