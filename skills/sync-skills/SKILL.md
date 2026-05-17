# /sync-skills

Sync, assess, and benchmark all third-party skills and tools in the environment.
Auto-discovers everything installed (skills, MCPs, npm packages, git repos).
Fetches latest from each source, benchmarks against current setup, applies the best changes.
Produces a dated report of what changed, what was applied, and what was skipped.

---

## Step 0 — Init

```bash
mkdir -p ~/.claude/sync-skills/state ~/Obsidian/Builds/02-Areas/Sync-Reports
SYNC_DATE=$(date +%Y-%m-%d)
SYNC_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SOURCES_FILE=~/.claude/skills/sync-skills/sources.json
STATE_FILE=~/.claude/sync-skills/state/last-sync.json
REPORT_FILE=~/Obsidian/Builds/02-Areas/Sync-Reports/$SYNC_DATE.md

# Load last sync info
if [ -f "$STATE_FILE" ]; then
  LAST_RUN=$(jq -r '.last_run // "never"' "$STATE_FILE" 2>/dev/null || echo "never")
else
  LAST_RUN="never"
fi

echo "=== /sync-skills ==="
echo "Date: $SYNC_TS"
echo "Last run: $LAST_RUN"
echo ""
```

---

## Step 1 — Auto-Discovery

Scan the environment and build a complete map of everything installed. Do NOT limit to sources.json — discover all third-party sources.

Run ALL of these discovery commands:

```bash
echo "=== DISCOVERY ==="

# 1. All skill directories in ~/.claude/skills/
echo "--- Skills in ~/.claude/skills/ ---"
ls -la ~/.claude/skills/ 2>/dev/null

# 2. Check each skill dir for update mechanism
for dir in ~/.claude/skills/*/; do
  name=$(basename "$dir")
  [ "$name" = "sync-skills" ] && continue  # skip self
  
  has_git="no"
  has_version="no"
  has_remote="none"
  pkg_version="none"
  
  # Check if it's a git repo
  if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    has_git="yes"
    has_remote=$(git -C "$dir" remote get-url origin 2>/dev/null || echo "none")
  fi
  
  # Check VERSION file
  [ -f "$dir/VERSION" ] && has_version=$(cat "$dir/VERSION")
  
  # Check package.json
  if [ -f "$dir/package.json" ]; then
    pkg_version=$(jq -r '.version // "unknown"' "$dir/package.json" 2>/dev/null || echo "unknown")
    pkg_repo=$(jq -r '.repository.url // .repository // "none"' "$dir/package.json" 2>/dev/null || echo "none")
  fi
  
  echo "SKILL: $name | git=$has_git | version=$has_version | remote=$has_remote | pkg=$pkg_version"
done

echo ""
echo "--- Skills in ~/.agents/skills/ ---"
ls ~/.agents/skills/ 2>/dev/null || echo "(none)"

# Check if ~/.agents/skills is a git repo
if git -C ~/.agents/skills rev-parse --git-dir >/dev/null 2>&1; then
  AGENTS_REMOTE=$(git -C ~/.agents/skills remote get-url origin 2>/dev/null || echo "none")
  AGENTS_BRANCH=$(git -C ~/.agents/skills branch --show-current 2>/dev/null || echo "unknown")
  echo "~/.agents/skills is a git repo | remote=$AGENTS_REMOTE | branch=$AGENTS_BRANCH"
  git -C ~/.agents/skills log --oneline -5 2>/dev/null
else
  echo "~/.agents/skills is NOT a git repo (manual install)"
fi

echo ""
echo "--- MCPs in ~/.claude/settings.json ---"
jq -r '.mcpServers | to_entries[] | "\(.key): \(.value.command // .value.url // "unknown")"' ~/.claude/settings.json 2>/dev/null || echo "(no mcpServers found)"

echo ""
echo "--- MCPs in ~/.claude/settings.local.json ---"
jq -r '.mcpServers | to_entries[] | "\(.key): \(.value.command // .value.url // "unknown")"' ~/.claude/settings.local.json 2>/dev/null || echo "(none)"

echo ""
echo "--- Globally installed npm packages (AI/Claude-related) ---"
npm ls -g --depth=0 2>/dev/null | grep -iE "claude|anthropic|mcp|gstack|openai|ollama|langchain" || echo "(none found)"

echo ""
echo "--- Local builds with version info ---"
for pkg in ~/builds/*/package.json; do
  [ -f "$pkg" ] && echo "$pkg: $(jq -r '"\(.name) v\(.version)"' "$pkg" 2>/dev/null)"
done
```

Analyze the discovery output. Build a list of all discovered sources, classifying each as:
- `TRACKED` — already in sources.json
- `UNTRACKED_UPDATABLE` — has a git remote or known update mechanism, not in sources.json
- `UNTRACKED_STATIC` — installed but no update mechanism found
- `MCP` — registered MCP server

---

## Step 2 — gstack

```bash
echo "=== gstack ==="
GSTACK_VERSION=$(cat ~/.claude/skills/gstack/VERSION 2>/dev/null || echo "unknown")
echo "Current version: $GSTACK_VERSION"

# Run the update check
UPDATE_CHECK=$(~/.claude/skills/gstack/bin/gstack-update-check 2>/dev/null || echo "")
echo "Update check: $UPDATE_CHECK"
```

If output contains `UPGRADE_AVAILABLE <old> <new>`:
- Record the old/new versions
- Invoke the `/gstack-upgrade` skill inline to perform the upgrade
- After upgrade: read `~/.claude/skills/gstack/CHANGELOG.md` (first 100 lines) to extract what's new
- List any new skill directories that weren't present before
- Status: `UPGRADED`

If output is empty or contains nothing about an upgrade:
- Status: `UP_TO_DATE at <version>`

---

## Step 3 — mattpocock/skills

```bash
echo "=== mattpocock/skills ==="
if git -C ~/.agents/skills rev-parse --git-dir >/dev/null 2>&1; then
  echo "Remote: $(git -C ~/.agents/skills remote get-url origin 2>/dev/null)"
  echo "Current HEAD: $(git -C ~/.agents/skills log --oneline -1 2>/dev/null)"
  
  git -C ~/.agents/skills fetch origin 2>&1
  NEW_COMMITS=$(git -C ~/.agents/skills log --oneline HEAD..origin/$(git -C ~/.agents/skills branch --show-current) 2>/dev/null)
  echo "New commits: ${NEW_COMMITS:-none}"
  
  if [ -n "$NEW_COMMITS" ]; then
    # Show which SKILL.md files changed
    git -C ~/.agents/skills diff --name-only HEAD origin/$(git -C ~/.agents/skills branch --show-current) 2>/dev/null
  fi
else
  echo "Not a git repo — checking for npm package"
  # Try to find the source package
  npm ls -g @anthropic-ai/claude-code-skills 2>/dev/null || echo "No npm source found"
fi
```

If new commits exist: show the commit list and changed files, then ask:

> **mattpocock/skills** has N new commits. Pull and update?
> - A) Yes, pull now
> - B) Show me the full diff first
> - C) Skip this time

If A: `git -C ~/.agents/skills pull` — then list all changed/added SKILL.md files
If B: run `git -C ~/.agents/skills diff HEAD origin/main` — then ask A/C
If C: log as SKIPPED

---

## Step 4 — Karpathy CLAUDE.md

Fetch the latest Karpathy CLAUDE.md from the URL in sources.json.

```bash
echo "=== Karpathy CLAUDE.md ==="
KARPATHY_CACHE=~/.claude/sync-skills/state/karpathy-claude.last
KARPATHY_URL=$(jq -r '.sources[] | select(.id=="karpathy-claude") | .url' ~/.claude/skills/sync-skills/sources.json)
echo "URL: $KARPATHY_URL"
[ -f "$KARPATHY_CACHE" ] && echo "Cache exists: $(wc -l < $KARPATHY_CACHE) lines" || echo "No cache (first run)"
```

Use WebFetch to retrieve the URL. Then:

1. If no cache exists: save fetched content to `~/.claude/sync-skills/state/karpathy-claude.last`. Status: `BASELINE_SAVED`. No diff yet — this is the first run establishing baseline.

2. If cache exists:
   - Extract the behavioral principles section from fetched content (everything between `## Behavioral Principles` and the next `##` heading, or entire file if no sections)
   - Extract our current `## Behavioral Principles` section from `~/.claude/CLAUDE.md`
   - Diff them line by line
   - Classify each upstream principle:
     - `ALREADY_COVERED` — same or semantically equivalent exists in ours
     - `NEW` — exists upstream, missing in ours
     - `CHANGED` — exists in both but wording differs
     - `UPSTREAM_REMOVED` — was in ours but removed upstream (flag only, don't auto-remove)
   - If no actionable diff: Status `UP_TO_DATE`
   - If diff exists: show a structured diff table

For each `NEW` or `CHANGED` item, ask:

> Karpathy CLAUDE.md has a change in behavioral principles. Apply?
> [Show the specific new/changed text]
> - A) Adopt — add/update in our ~/.claude/CLAUDE.md
> - B) Skip — keep our current version
> - C) Adopt with modification — I'll edit after

Apply accepted changes to `~/.claude/CLAUDE.md` (insert into the `## Behavioral Principles` section, preserving our additions).

Save fetched content to cache file.

---

## Step 5 — Untracked Updatable Sources

For each source classified as `UNTRACKED_UPDATABLE` in Step 1:

Show:
```
Found: <name> at <path>
Remote: <git-remote or URL>
Not in sources.json — want to track this source?
```

Ask:
> **New source found: <name>** — has a git remote and could be auto-synced. Add to tracking?
> - A) Yes, add to sources.json and sync now
> - B) Add to sources.json for future syncs only
> - C) Ignore this source

If A or B: append an entry to `~/.claude/skills/sync-skills/sources.json` and run git fetch to get current state.

---

## Step 6 — MCP Assessment

For each MCP found in settings.json / settings.local.json:

```bash
echo "=== MCP Assessment ==="
# For each MCP, check if the command path exists and is executable
jq -r '.mcpServers | to_entries[] | "\(.key)|\(.value.command // "")"' ~/.claude/settings.json 2>/dev/null | while IFS='|' read name cmd; do
  if [ -n "$cmd" ]; then
    if [ -f "$cmd" ]; then
      echo "MCP $name: command exists at $cmd"
      # Check if it's in a git repo
      MCP_DIR=$(dirname "$cmd")
      if git -C "$MCP_DIR" rev-parse --git-dir >/dev/null 2>&1; then
        echo "  -> git repo: $(git -C "$MCP_DIR" remote get-url origin 2>/dev/null)"
        echo "  -> last commit: $(git -C "$MCP_DIR" log --oneline -1 2>/dev/null)"
      fi
    else
      echo "MCP $name: WARNING — command not found at $cmd"
    fi
  fi
done
```

Report: list all MCPs with their status (healthy / missing command / updateable via git).
For MCPs with git remotes and new commits: offer to add to sources.json.

---

## Step 7 — Write Sync Report

```bash
cat > "$REPORT_FILE" << 'REPORT_EOF'
REPORT_EOF
```

Write a complete markdown report to `~/Obsidian/Builds/02-Areas/Sync-Reports/$SYNC_DATE.md`:

```markdown
# Sync Report — <SYNC_TS>

## Summary

| Source | Type | Status | Detail |
|---|---|---|---|
| gstack | skills | <status> | <version change or up-to-date> |
| mattpocock/skills | skills | <status> | <N commits / up-to-date / skipped> |
| Karpathy CLAUDE.md | behavioral | <status> | <N principles assessed / baseline saved> |
| <any untracked sources> | discovered | <added/ignored> | — |
| <MCPs> | mcp | <healthy/warning> | — |

## Discovered Sources (not in sources.json)
<list with classification>

## Changes Applied

### ~/.claude/CLAUDE.md
<show exact diff of any behavioral principle changes>

### gstack
<new skills or version bump>

### mattpocock/skills
<new/changed SKILL.md files>

## Skipped
<list of what was skipped and why>

## Warnings
<missing MCP commands, git repos with no remote, etc.>

## Sources Registry After This Run
<current state of sources.json>

## Next Sync
Recommended: run /sync-skills monthly or after any major tool update.
```

---

## Step 8 — Persist State

```bash
# Write last-sync.json
cat > ~/.gstack/sync-state/last-sync.json << EOF
{
  "last_run": "$SYNC_TS",
  "results": {
    "gstack": "<status>",
    "mattpocock-skills": "<status>",
    "karpathy-claude": "<status>"
  }
}
EOF
echo "State saved."
```

---

## Step 9 — Final Summary

Print a clean terminal summary:

```
=== /sync-skills Complete ===

Source                   Status           Detail
------------------------------------------------------------
gstack                   UPGRADED         1.39.1.0 → 1.39.2.0
mattpocock/skills        UP_TO_DATE       —
Karpathy CLAUDE.md       BASELINE_SAVED   First run — diff next time
<discovered sources>     UNTRACKED        2 found, 1 added to tracking

Report: ~/Obsidian/Builds/02-Areas/Sync-Reports/<date>.md

Run again any time with /sync-skills
```

---

## Completion Status Protocol

- **DONE** — all sources processed, report written.
- **DONE_WITH_CONCERNS** — processed, but one or more sources had warnings (missing command, no git remote, fetch failed).
- **BLOCKED** — cannot fetch a source (network error) and no cache exists. State blocker explicitly.

---

## Adding a New Source

To track a new third-party tool, add an entry to `~/.claude/skills/sync-skills/sources.json`:

```json
{
  "id": "unique-id",
  "name": "Human readable name",
  "type": "web-fetch | git-repo | gstack-upgrade | npm-package",
  "description": "What this provides",
  "url": "https://... (for web-fetch)",
  "local_path": "~/.path/to/repo (for git-repo)",
  "auto_apply": false
}
```

Then run `/sync-skills` — it will pick up the new source automatically.
