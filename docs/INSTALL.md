# Installation Guide

> Complete setup: Claude Code → skills → Obsidian vault → Context7 → first project.
> Estimated time: 45-90 minutes.

---

## Prerequisites

Before starting, ensure you have:

```bash
# Check versions
node --version          # Need 18+
git --version           # Need 2.30+
gh --version            # GitHub CLI
pnpm --version          # Optional but recommended

# Install if missing (macOS):
brew install node git gh
npm install -g pnpm
```

- [Claude Code](https://claude.ai/code) installed and authenticated
- [Obsidian](https://obsidian.md/) installed
- GitHub account with `gh auth login` completed

---

## Phase 1 — Claude Code Settings (5 minutes)

### Step 1 — Install global settings

```bash
# Copy and edit global settings
cp settings/settings.json.template ~/.claude/settings.json

# Edit: change preferredNotifChannel to your terminal
# Options: "ghostty", "iterm", "terminal", "wezterm"
nano ~/.claude/settings.json
```

### Step 2 — Install machine-specific permissions

```bash
cp settings/settings.local.json.template ~/.claude/settings.local.json
# Add your project-specific domain allowlists to the allow list
# Edit the deny/ask sections to match your risk tolerance
```

### Step 3 — Install your personal CLAUDE.md

```bash
# If you don't have one yet:
cp settings/CLAUDE.md.template ~/.claude/CLAUDE.md

# If you already have one — review the template and add missing sections
# DO NOT replace your existing CLAUDE.md without reviewing it first
```

**Critical:** Keep `~/.claude/CLAUDE.md` under 200 lines. Every extra line costs tokens on every session.

---

## Phase 2 — Skills Installation (10 minutes)

### Step 4 — Install the starter kit skill

```bash
mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/commands

# Install the skill
cp -r starter-kit ~/.claude/skills/ai-project-scaffold

# Dual-residency: also install components at user level
# This means improvements propagate to all projects automatically
cp starter-kit/reference/agents/*.md ~/.claude/agents/
cp starter-kit/reference/commands/*.md ~/.claude/commands/

echo "✓ ai-project-scaffold installed"
ls ~/.claude/agents/    # Should show 11 .md files
ls ~/.claude/commands/  # Should show 9 .md files
```

### Step 5 — Install mattpocock/skills

```bash
npx skills@latest add mattpocock/skills
```

When prompted, select these skills:
- `grill-with-docs` — pre-implementation interview
- `diagnose` — structured debug loop
- `zoom-out` — broader context orientation
- `improve-codebase-architecture` — weekly refactor ritual
- `handoff` — human-readable session compaction
- `caveman` — token compression mode

```bash
echo "✓ mattpocock skills installed"
ls ~/.claude/skills/ | grep -E "grill|diagnose|zoom|improve|handoff|caveman"
```

### Step 6 — Install gstack (optional but recommended)

gstack provides ~30 additional skills for shipping, reviewing, QA, and SEO.

Follow the gstack installation documentation. After installation:

```bash
ls ~/.claude/skills/gstack/   # Should show 30+ skill directories
```

Key gstack skills you'll use most:
- `/review` — pre-landing PR review
- `/ship` — deployment workflow
- `/qa` — full QA cycle
- `/browse` — web browsing (always use instead of direct browser tools)
- `/plan-ceo-review` — CEO-mode scope review
- `/plan-eng-review` — engineering architecture review

---

## Phase 3 — Obsidian Vault Setup (20 minutes)

### Step 7 — Create the vault structure

```bash
mkdir -p ~/Obsidian/Builds/{00-Inbox,01-Projects,02-Areas,03-Resources,04-Archive,05-Patterns}
mkdir -p ~/Obsidian/Builds/.claude/skills
cd ~/Obsidian/Builds && git init -b main
```

### Step 8 — Open in Obsidian

1. Open Obsidian
2. File → Open folder → select `~/Obsidian/Builds`
3. Install recommended plugins (Settings → Community plugins → Browse):
   - **Dataview** — query notes like a database
   - **Templater** — note templates with auto-fill
   - **Git** — auto-sync to GitHub

### Step 9 — Create vault CLAUDE.md

Create `~/Obsidian/Builds/.claude/CLAUDE.md`:
```markdown
# Vault: ~/Obsidian/Builds/

This vault follows the Karpathy Six rules:
1. Five page types: entity, concept, synthesis, source, report
2. Search before write — always kg_search before creating
3. Backlinks mandatory — every note links to ≥1 other note
4. Contradictions flagged on the page, never silently overwritten
5. Attribution in frontmatter (created_by, last_edited_by)
6. One vault — no subvaults, no parallel hierarchies

When adding notes:
- Active projects → 01-Projects/<project-name>/
- Patterns → 05-Patterns/
- New ideas → 00-Inbox/ (process weekly)
- Killed apps → 04-Archive/ (keep forever)
```

### Step 10 — Set up vault backup

```bash
cd ~/Obsidian/Builds
git add . && git commit -m "vault: initial structure"

# Create private GitHub repo for the vault
gh repo create vault-builds --private --push --source=.
echo "✓ Vault backed up to GitHub"
```

---

## Phase 4 — MCP Server Setup (15 minutes)

### Step 11 — Install Context7

Context7 fetches fresh library docs at query time.

```bash
# Add to Claude Code via settings (claude.json or /config command):
# Navigate to: claude.ai/code → Settings → MCP Servers → Add Server
# Or edit ~/.claude/claude.json directly
```

Add to your MCP config:
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

Test: Open Claude Code, ask about a library. It should silently use Context7.

### Step 12 — Install vault-files MCP

> **Note:** The `mcpvault` npm package does not exist. Use `@modelcontextprotocol/server-filesystem` (the official MCP filesystem server) instead.

```bash
# Easiest: use the Claude Code CLI
claude mcp add --scope user vault-files -- npx -y @modelcontextprotocol/server-filesystem /Users/YOUR_USERNAME/Obsidian/Builds
```

Or add manually to your MCP config:
```json
{
  "mcpServers": {
    "vault-files": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/YOUR_USERNAME/Obsidian/Builds"]
    }
  }
}
```

Replace `YOUR_USERNAME` with your actual username.

### Step 13 — Install knowledge-graph (optional, 30 minutes)

```bash
git clone https://github.com/obra/knowledge-graph-mcp.git ~/tools/knowledge-graph-mcp
cd ~/tools/knowledge-graph-mcp && npm install

# Add to MCP config:
{
  "mcpServers": {
    "knowledge-graph": {
      "command": "node",
      "args": ["/Users/YOUR_USERNAME/tools/knowledge-graph-mcp/index.js"],
      "env": {
        "KG_VAULT_PATH": "/Users/YOUR_USERNAME/Obsidian/Builds"
      }
    }
  }
}
```

After adding to config, in Claude Code run:
```
> /kg-index
```

Initial indexing takes ~30 minutes. Schedule a block for this.

---

## Phase 5 — Local Model Setup (optional, 30 minutes)

Required for AI routing with local Qwen (free tier of the classifier):

### Step 14 — Install Ollama

```bash
brew install ollama

# Start the server (add to login items for persistent run)
ollama serve &

# Pull models (9GB download — schedule for good internet)
ollama pull qwen2.5-coder:14b   # Primary local model
ollama pull nomic-embed-text     # For RAG embeddings

# Test
ollama run qwen2.5-coder:14b "What is 2+2?"
```

**Hardware check:**
- Minimum: 16GB RAM
- Recommended: 32GB RAM (M1/M2/M4 Mac or 32GB PC)
- For qwen3-coder:32b: 64GB RAM

---

## Phase 6 — Shell wrapper (2 minutes)

### Step 15 — Add the `cc` launcher to `~/.zshrc`

This replaces your normal Claude Code launch command. When you close a session, the knowledge-graph automatically re-indexes.

```bash
cat >> ~/.zshrc << 'EOF'

# claude wrapper: re-index knowledge-graph after every session ends
function ccc() {
  caffeinate -s claude --dangerously-skip-permissions "$@"
  bash /YOUR_HOME/builds/_platform/scripts/kg-reindex.sh
}
EOF
source ~/.zshrc
```

Replace `/YOUR_HOME` with your home path and adjust the `claude` flags to match how you normally launch it. From now on use `ccc` instead of `claude`.

---

## Phase 7 — First Project (10 minutes)

### Step 16 — Start a new project with the scaffold

```bash
mkdir ~/builds/my-first-app && cd ~/builds/my-first-app
cc
```

In Claude Code:
```
> /ai-project-scaffold
```

Answer the 11 questions. The scaffold generates everything in ~10 minutes.

```bash
# After scaffold completes:
chmod +x scripts/*.sh
git init -b main && git add . && git commit -m "chore: phase 0 scaffold"
pre-commit install   # if pre-commit is installed
```

Then start your first real session:
```
> /start-session
```

---

## Verification Checklist

Run these checks to verify the installation:

```bash
# 1. Skills installed correctly
ls ~/.claude/skills/ | grep -c "."           # Should be ≥3 directories
ls ~/.claude/agents/ | grep -c ".md"         # Should be 11 files
ls ~/.claude/commands/ | grep -c ".md"       # Should be 9 files

# 2. CLAUDE.md is within limit
wc -l ~/.claude/CLAUDE.md                    # Should be ≤200 lines

# 3. Vault structure exists
ls ~/Obsidian/Builds/                        # Should show the 6 directories

# 4. Ollama running (if installed)
curl -s http://localhost:11434/api/tags | python3 -m json.tool | grep name

# 5. GitHub auth
gh auth status                               # Should show "Logged in to github.com"

# 6. Claude Code version (check agent teams support)
claude --version                             # Should be ≥2.1.32 for agent teams
```

---

## Troubleshooting

**`/ai-project-scaffold` not found:**
```bash
# Check installation
ls ~/.claude/skills/ai-project-scaffold/SKILL.md
# If missing: re-run step 4
```

**CLAUDE.md not loading:**
```bash
# Claude Code loads CLAUDE.md from the project root and ~/.claude/
# Verify path
cat ~/.claude/CLAUDE.md | wc -l    # Should exist and be ≤200
```

**Context7 not fetching docs:**
- Check your MCP config is valid JSON
- Restart Claude Code after MCP config changes
- Test with: `> "Show me the latest Next.js 15 Image component API"` (should use context7)

**Ollama not responding:**
```bash
ollama serve &    # Start if not running
curl http://localhost:11434/api/tags    # Should return JSON with model list
```

**Agent teams not working:**
- Verify `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json
- Verify Claude Code version ≥2.1.32
- The feature is experimental — some operations may not parallelize correctly

---

## Updating the Setup

```bash
# Update starter kit components
cd /path/to/claude-code-solo-builder
git pull

# Re-install agents and commands (they're overwritten, not merged)
cp starter-kit/reference/agents/*.md ~/.claude/agents/
cp starter-kit/reference/commands/*.md ~/.claude/commands/

# Update gstack
/gstack-upgrade   # in Claude Code

# Update mattpocock skills
npx skills@latest add mattpocock/skills --update
```

---

*See also: `docs/OBSIDIAN-CONTEXT7.md` for vault deep-dive, `docs/NEW-PROJECT.md` for project setup, `docs/SETTINGS-AND-THEMES.md` for configuration reference.*
