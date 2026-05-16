---
description: Update the Obsidian vault INDEX.md for the current project, then trigger knowledge-graph re-index.
---

Update the Obsidian vault note for the current project at `~/Obsidian/Builds/01-Projects/<project-name>/INDEX.md`.

Steps:

1. Determine the current project name from the working directory (basename of cwd).
2. Read the current project's `CLAUDE.md`, `ROADMAP.md` (if present), and recent git log (`git log --oneline -10`).
3. Open `~/Obsidian/Builds/01-Projects/<project-name>/INDEX.md`. If it does not exist, create it.
4. Write or update the note using this template:

```markdown
---
type: entity
name: <project-name>
created: <original created date or today>
created_by: markandey
last_edited: <today YYYY-MM-DD>
last_edited_by: claude
status: <ACTIVE-BUILD | VALIDATE | STABILIZE | KEEP-AS-IS | DEAD>
tags: [list key tech tags from stack]
related: [[05-Patterns/<relevant-pattern>]]
---
# <project-name>

## What it does
One paragraph: purpose, who uses it, core value.

## Current status
Phase N — <phase name>. Next: <next 1-2 tasks>.

## Stack
Key technologies in use.

## Recent decisions
- <ADR slug> — <one-line summary> (<date>)

## Key patterns used
- [[05-Patterns/<pattern-name>]]

## Links
- Repo: <path or URL>
- Running at: <localhost port or domain>
```

5. Do NOT overwrite any section that has human-written content unless the facts are clearly stale (>14 days). Instead, append under a `## Session <date>` heading.
6. After writing the note, run the re-index:

```bash
bash ~/builds/_platform/scripts/kg-reindex.sh
```

7. Commit the vault note:

```bash
cd ~/Obsidian/Builds && git add . && git commit -m "vault: update <project-name> INDEX — $(date '+%Y-%m-%d')"
```

Report: which fields were updated, whether the re-index was triggered, and the commit hash.
