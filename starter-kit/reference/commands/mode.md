---
description: Switch the session execution profile — /mode best (max quality+speed, default) or /mode saver (token-optimised). Sets how workflow recipes fan out and which models they use.
argument-hint: best | saver
---

Set the active execution profile for this session to **$ARGUMENTS** (default `best` if empty).

This profile is the `args.mode` the workflow recipes read, and the value the wrapper commands
(`/review-exhaustive`, `/audit-security`, `/map-codebase`) forward. The `Workflow()` runtime cannot
flip `/model` for you (and `/model` is unavailable in cloud sessions), so this command is session sugar
over the deterministic `args.mode` channel:

1. **Record** the chosen profile for the rest of this session; pass `mode: "<profile>"` in `args` to
   every recipe you launch from now on.
2. **Print the manual switch** for the user to apply interactively:
   - **best** (default) — `/model opus` + turn `/fast` on + `/effort xhigh` (or `/effort ultracode` to
     let workflows auto-trigger). Recipes use full fan-out, 5 Sonnet skeptics/finding, Opus synthesis.
     Token cost is *not* the constraint on Max plans — the **weekly Opus cap** is, so recipes keep bulk
     leaves (skeptics, grind) on Sonnet/Haiku to preserve it.
   - **saver** — `/model sonnet` + `/effort high` (+ `/caveman` if you want compression). Recipes use
     narrow fan-out, 1–2 Haiku skeptics, Sonnet synthesis.
3. **Confirm:** "Session profile: **<profile>**. Recipes will run in `<profile>` mode; apply the
   model/effort switch above to match it interactively."

If `$ARGUMENTS` is neither `best` nor `saver`, default to `best` and note it.
