# Native first

Claude Code now ships much of what this kit originally had to build. Use the native
feature by default. Reach for the kit when you need what it adds.

| Need | Use first | Kit tool, and when it still earns its place |
| :-- | :-- | :-- |
| Review a diff | `/code-review` (effort levels, `--fix`, `--comment`) | `/review-exhaustive`, when you want the project's own agents and adversarial verification |
| Security review of a diff | `/security-review` | `/review-security`, which applies the project's `security-architect` |
| Security audit of a whole repo | `claude-security` plugin | `/audit-security`, for loop-until-dry hunting mapped to OWASP |
| Run something on a schedule | `/loop`, `/schedule` | None |
| Parallel sessions | Worktrees and background agents (`claude agents`) | None |
| Parallel work inside one job | Workflow tool | The 7 recipes, which are ready-made Workflow scripts |
| Dynamic fan-out | Agent teams | `/start-phase-team`. `/orchestrate-loops` is legacy; see ADR 0006 |
| Understand a codebase | Explore agent, LSP plugins | `/map-codebase`, for a durable written brief |
| Find code by meaning | None | LEANN local RAG (`/rag-init`) |
| Choose a model | Aliases: `opus`, `sonnet`, `haiku` | Never pin a full model ID. Pins go stale silently, aliases do not |
| Work from a phone | Remote Control | `remote-fleet.sh`, which keeps servers running across outages (`docs/REMOTE-OPS.md`) |

## What only this kit provides

- **Guardrail hooks:** secret scan, dangerous-command guard, file-domain guard, design lint.
- **Domain agents:** project-specific reviewers that carry knowledge no general agent has.
- **Project lifecycle:** spec, build, phase review, and `/sync-project` across a portfolio.
- **Knowledge layer:** vault, knowledge graph, and the cross-project pattern library.

## Companion suites

Keep these current with `/sync-skills`, which now warns when it is overdue.

| Suite | Update with | Worth knowing |
| :-- | :-- | :-- |
| gstack | `/gstack-upgrade` | `/verify` runs the checks `/ship` would pick; `/captain` runs a crew of agents through merge trains |
| mattpocock skills | `claude plugin update mattpocock-skills@mattpocock` | Adds `to-spec`, `to-tickets`, `wayfinder`, `implement`, `pr`, `retro` |
| LSP plugins | `claude plugin update <name>@claude-plugins-official` | `typescript-lsp`, `pyright-lsp` and `gopls-lsp` need their language servers installed |

A plugin's skills cost context in every session, even unused. Installing one is cheap to try
and easy to forget, so remove suites you do not use.
