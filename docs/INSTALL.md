# Installation Guide

> Complete setup: Claude Code → settings → skills → first project.
> Core setup takes ~15 minutes. Optional modules (vault, local models) add more.

---

## Prerequisites

Before starting, ensure you have:

```bash
# Check versions
node --version          # Need 22+
git --version           # Need 2.30+
gh --version            # GitHub CLI
pnpm --version          # Optional but recommended

# Install if missing (macOS):
brew install node git gh
npm install -g pnpm
```

- [Claude Code](https://claude.ai/code) installed and authenticated
- GitHub account with `gh auth login` completed

Optional: [Obsidian](https://obsidian.md/) — only needed for the vault module (`docs/VAULT.md`).

---

## Phase 1 — Claude Code Settings (5 minutes)

`install.sh` / `make install` propagate the repo's skills, agents, commands, workflows, and hook
scripts into `~/.claude`. They **never** touch your live `~/.claude/settings.json` or
`~/.claude/CLAUDE.md` — you own those. Copy the templates once and edit them by hand.

### Step 1 — Install global settings

```bash
# Copy and edit global settings
cp settings/settings.json.template ~/.claude/settings.json

# Edit: change preferredNotifChannel to your terminal
# Options: "ghostty", "iterm", "terminal", "wezterm"
nano ~/.claude/settings.json
```

The template wires the SessionStart hooks to `$HOME/.claude/scripts/…` — there are no path
placeholders to replace. `make install` copies those scripts into `~/.claude/scripts/`.

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

### Step 4 — (Optional) Module config

Only if you plan to use an optional module (e.g. the vault): copy the config template.

```bash
cp settings/solo-builder.config.template ~/.claude/solo-builder.config
# Edit: set VAULT_PATH (and VAULT_REINDEX_CMD if you use knowledge-graph)
```

Leave it unset and the modules stay dormant. Details in `docs/VAULT.md`.

---

## Phase 2 — Skills Installation (10 minutes)

### Step 5 — Install the starter kit + agents/commands/workflows

`make install` is the canonical, idempotent installer. It installs the `ai-project-scaffold` skill
plus all agents, commands, workflows, and hook scripts at user level, so improvements propagate to
every project.

```bash
make install

echo "✓ ai-project-scaffold installed"
ls ~/.claude/agents/    # Should show 11 .md files
ls ~/.claude/commands/  # Should show 18 .md files
```

### Step 6 — Install mattpocock/skills (optional)

mattpocock's session-layer skills now ship as a **Claude Code plugin** — the whole suite installs at once:

```bash
claude plugin marketplace add mattpocock/skills      # add the marketplace once
claude plugin install mattpocock-skills@mattpocock   # installs the suite
```

The suite includes:
- `grill-with-docs` — pre-implementation interview
- `diagnosing-bugs` — structured debug loop
- `improve-codebase-architecture` — weekly refactor ritual
- `handoff` — human-readable session compaction

`caveman` (token compression) is **not** in the plugin — mattpocock deleted it upstream, so it's kept as a frozen local skill under `~/.claude/skills/`, invoked by name.

```bash
# Verify in Claude Code: run `/plugin` → Installed, and confirm `mattpocock-skills` is listed
```

### Step 7 — Install gstack (optional but recommended)

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

### Step 8 — Configure /sync-skills (optional)

`make install` already installs `/sync-skills`. It keeps your tools current: gstack,
mattpocock/skills, and the Karpathy CLAUDE.md baseline. Run it monthly.

```bash
# Verify sources.json is present — the skill blocks without it
ls ~/.claude/skills/sync-skills/sources.json
```

`sources.json` ships pre-configured for gstack, mattpocock/skills, and the Karpathy CLAUDE.md URL.
Edit it to add or remove sources before the first run.

```bash
# First run (establishes baseline — no changes applied yet)
# Inside Claude Code: /sync-skills
```

---

## Phase 3 — Optional: Vault / Knowledge Module

The vault grounds every AI call in your prior decisions (Obsidian + Context7 + optional
knowledge-graph MCP). It is entirely optional and stays dormant until you set `VAULT_PATH` in
`~/.claude/solo-builder.config`.

**Setup guide: `docs/VAULT.md`** — covers the vault structure, the MCP servers (Context7,
filesystem, knowledge-graph), and the auto-indexing hooks.

---

## Phase 4 — Local Model Setup (optional, 30 minutes)

Optional — powers the local-model routing pattern (`PLAYBOOK.md` §3.10) and the embeddings the RAG
module will use.

### Step 9 — Install Ollama

```bash
brew install ollama

# Start the server (add to login items for persistent run)
ollama serve &

# Pull models (9GB download — schedule for good internet)
ollama pull qwen2.5-coder:14b   # Primary local model
ollama pull nomic-embed-text     # For RAG embeddings

# Local RAG module (per-project semantic code search — docs/LOCAL-RAG.md)
uv tool install leann-core --with leann --with docx2txt
claude mcp add --scope user leann-server -- leann_mcp

# Test
ollama run qwen2.5-coder:14b "What is 2+2?"
```

**Hardware check:**
- Minimum: 16GB RAM
- Recommended: 32GB RAM (M1/M2/M4 Mac or 32GB PC)
- For qwen3-coder:32b: 64GB RAM

---

## Phase 5 — First Project (10 minutes)

### Step 10 — Start a new project with the scaffold

```bash
mkdir ~/builds/my-first-app && cd ~/builds/my-first-app
claude
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
ls ~/.claude/commands/ | grep -c ".md"       # Should be 18 files

# 2. CLAUDE.md is within limit
wc -l ~/.claude/CLAUDE.md                    # Should be ≤200 lines

# 3. Ollama running (if installed)
curl -s http://localhost:11434/api/tags | python3 -m json.tool | grep name

# 4. GitHub auth
gh auth status                               # Should show "Logged in to github.com"

# 5. Claude Code version (check agent teams support)
claude --version                             # Should be ≥2.1.32 for agent teams
```

---

## Troubleshooting

**`/ai-project-scaffold` not found:**
```bash
# Check installation
ls ~/.claude/skills/ai-project-scaffold/SKILL.md
# If missing: re-run make install
```

**CLAUDE.md not loading:**
```bash
# Claude Code loads CLAUDE.md from the project root and ~/.claude/
# Verify path
cat ~/.claude/CLAUDE.md | wc -l    # Should exist and be ≤200
```

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
# Pull the latest kit and re-propagate to ~/.claude
cd /path/to/claude-code-solo-builder
git pull
make install      # idempotent — re-syncs agents, commands, workflows, scripts, skills

# Update gstack
/gstack-upgrade   # in Claude Code

# Update mattpocock skills (plugin)
claude plugin update mattpocock-skills
```

---

*See also: `docs/VAULT.md` for the vault module, `docs/NEW-PROJECT.md` for project setup, `docs/SETTINGS-AND-THEMES.md` for configuration reference.*
