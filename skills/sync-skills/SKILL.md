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

# Hard prerequisite — sources.json must exist
if [ ! -f "$SOURCES_FILE" ]; then
  echo "BLOCKED: sources.json not found at $SOURCES_FILE"
  echo "Create it first — see the 'Adding a New Source' section at the bottom of this skill."
  exit 1
fi

# Validate it parses
if ! jq empty "$SOURCES_FILE" 2>/dev/null; then
  echo "BLOCKED: sources.json is not valid JSON. Fix it before running /sync-skills."
  exit 1
fi

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
# nullglob prevents literal '*' expansion when dir is empty (bash); zsh handles it natively
shopt -s nullglob 2>/dev/null || setopt NULL_GLOB 2>/dev/null || true
for dir in ~/.claude/skills/*/; do
  [ -d "$dir" ] || continue  # skip if glob produced no matches
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

If A:
```bash
# Dirty check — do not pull over uncommitted changes
if ! git -C ~/.agents/skills diff --quiet 2>/dev/null; then
  echo "WARNING: ~/.agents/skills has uncommitted changes — skipping pull to avoid data loss."
  echo "Commit or stash changes manually, then re-run /sync-skills."
else
  CURRENT_BRANCH=$(git -C ~/.agents/skills branch --show-current 2>/dev/null || echo "main")
  git -C ~/.agents/skills pull --ff-only origin "$CURRENT_BRANCH" 2>&1 || \
    echo "WARN: pull --ff-only failed (diverged history?). Run manually: cd ~/.agents/skills && git pull"
fi
```
Then list all changed/added SKILL.md files with `git diff --name-only HEAD~1 HEAD 2>/dev/null`.

If B: run `git -C ~/.agents/skills diff HEAD origin/$(git -C ~/.agents/skills branch --show-current 2>/dev/null || echo main)` — then ask A/C
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

Before writing any change to `~/.claude/CLAUDE.md`:
```bash
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak-"$SYNC_DATE"
echo "Backup created: ~/.claude/CLAUDE.md.bak-$SYNC_DATE"
```

Then apply the accepted change by inserting or replacing the specific line(s) within the `## Behavioral Principles` section only. Do NOT rewrite the entire file — use the Edit tool targeting the exact old string. If the section does not exist in CLAUDE.md, append a new `## Behavioral Principles` block at the end.

Save fetched content to cache file:
```bash
cp /dev/stdin "$KARPATHY_CACHE" < <(cat <<'EOF'
<fetched content>
EOF
)
# or write via Write tool — either is fine; the important thing is it replaces the old cache atomically
```

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

If A or B: add the entry to `~/.claude/skills/sync-skills/sources.json` using jq so the file stays valid JSON:
```bash
NEW_ENTRY='{"id":"<id>","name":"<name>","type":"git-repo","description":"<desc>","local_path":"<path>","auto_apply":false}'
cp "$SOURCES_FILE" "$SOURCES_FILE.bak-$SYNC_DATE"
jq --argjson entry "$NEW_ENTRY" '.sources += [$entry]' "$SOURCES_FILE" > "$SOURCES_FILE.tmp" \
  && mv "$SOURCES_FILE.tmp" "$SOURCES_FILE" \
  || { echo "ERROR: failed to update sources.json — backup at $SOURCES_FILE.bak-$SYNC_DATE"; }
```
If A: also run `git -C "<local_path>" fetch origin 2>&1` to establish the remote baseline.

---

## Step 6 — MCP Assessment

For each MCP found in settings.json / settings.local.json:

```bash
echo "=== MCP Assessment ==="

# Merge both settings files — read each, combine mcpServers keys
for SETTINGS_F in ~/.claude/settings.json ~/.claude/settings.local.json; do
  [ -f "$SETTINGS_F" ] || continue
  jq -r --arg src "$SETTINGS_F" '
    .mcpServers // {} | to_entries[] |
    "\($src)|\(.key)|\(.value.command // "")|\(.value.url // "")"
  ' "$SETTINGS_F" 2>/dev/null
done | while IFS='|' read settings_src name cmd url; do
  if [ -n "$url" ]; then
    # URL-based MCP — cannot check binary; just report it
    echo "MCP $name [url]: $url (from $settings_src) — cannot verify binary"
    continue
  fi
  if [ -z "$cmd" ]; then
    echo "MCP $name: no command or url defined (from $settings_src)"
    continue
  fi

  # cmd may be an absolute path OR a PATH command (npx, node, uvx, python3, etc.)
  if [[ "$cmd" == /* ]]; then
    # Absolute path — check it exists and is executable
    if [ -x "$cmd" ]; then
      echo "MCP $name: OK (absolute path $cmd)"
      MCP_DIR=$(dirname "$cmd")
      if git -C "$MCP_DIR" rev-parse --git-dir >/dev/null 2>&1; then
        echo "  -> git repo: $(git -C "$MCP_DIR" remote get-url origin 2>/dev/null)"
        echo "  -> last commit: $(git -C "$MCP_DIR" log --oneline -1 2>/dev/null)"
      fi
    elif [ -f "$cmd" ]; then
      echo "MCP $name: WARNING — exists but not executable: $cmd"
    else
      echo "MCP $name: WARNING — file not found: $cmd"
    fi
  else
    # PATH-based command (npx, node, uvx, python3, etc.)
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "MCP $name: OK (PATH command: $cmd)"
    else
      echo "MCP $name: WARNING — command not on PATH: $cmd"
    fi
  fi
done
```

Report: list all MCPs with their status (healthy / not-executable / missing / url-based / PATH command).
For MCPs with absolute-path git repos that have new upstream commits: offer to add to sources.json tracking.

---

## Step 7 — Write Sync Report

Write a complete markdown report to `~/Obsidian/Builds/02-Areas/Sync-Reports/$SYNC_DATE.md` using the Write tool (do NOT use a shell heredoc — the empty-heredoc pattern silently truncates any existing same-day report before the content is ready).

If the file already exists (same-day re-run), append a `## Re-run — <SYNC_TS>` section rather than overwriting.

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

Collect the actual status strings from each step (the values you recorded in Steps 2–4), then write:

```bash
# GSTACK_STATUS, MATT_STATUS, KARPATHY_STATUS must be set to the actual outcomes
# from Steps 2, 3, 4 respectively before running this block.
# Valid values: UPGRADED | UP_TO_DATE | SKIPPED | BASELINE_SAVED | CHANGED | ERROR

mkdir -p ~/.claude/sync-skills/state  # ensure dir exists (created in Step 0, but be safe)
cat > "$STATE_FILE" << EOF
{
  "last_run": "$SYNC_TS",
  "results": {
    "gstack": "$GSTACK_STATUS",
    "mattpocock-skills": "$MATT_STATUS",
    "karpathy-claude": "$KARPATHY_STATUS"
  }
}
EOF
if [ $? -eq 0 ]; then
  echo "State saved to $STATE_FILE"
else
  echo "WARNING: failed to write state file — next run will show last_run=never"
fi
```

---

## Step 9 — Final Summary

Print a clean terminal summary using ONLY the actual results from Steps 2–6. Do NOT copy the example below — substitute real values. The example shows the format, not the content.

```
=== /sync-skills Complete ===

Source                   Status           Detail
------------------------------------------------------------
gstack                   <$GSTACK_STATUS>  <old ver → new ver, or current ver>
mattpocock/skills        <$MATT_STATUS>   <N new commits pulled, or up-to-date, or skipped>
Karpathy CLAUDE.md       <$KARPATHY_STATUS> <N principles assessed, or baseline saved>
<each UNTRACKED source>  UNTRACKED        <added to tracking / ignored>
<each MCP>               <OK / WARNING>   <detail>

Changes written:
  ~/.claude/CLAUDE.md    <"N lines added/changed" or "no changes">
  sources.json           <"N sources added" or "unchanged">

Report: ~/Obsidian/Builds/02-Areas/Sync-Reports/<SYNC_DATE>.md

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
