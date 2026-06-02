---
description: Whole-repo security audit via the security-sweep Workflow (loop-until-dry hunters per vuln class + adversarial verification, OWASP-mapped). The heavyweight whole-repo sibling of /review-security.
---

Run the **`security-sweep`** saved workflow over the whole repository.

1. Launch it as a Dynamic Workflow, forwarding the active session profile:
   `Workflow({ name: 'security-sweep', args: { mode: <best|saver — the profile set by /mode, default best>, repoPath: '.' } })`.
2. This is the **heavyweight** sibling of `/review-security` (which is a fast single-agent per-diff pass). Use `security-sweep` for periodic whole-repo audits: parallel hunters per vuln class keep probing until dry, then skeptics verify each candidate.
3. It runs as a workflow (explicit opt-in) and costs meaningfully more tokens — scope accordingly.
4. When it returns, present the **OWASP-mapped, severity-ranked findings** and the executive summary. Surface any `critical`/`high` items first.
