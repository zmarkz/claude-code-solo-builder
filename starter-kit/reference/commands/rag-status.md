---
description: Read-only health check of the project's local RAG index (LEANN). Reports freshness vs HEAD, recent reindex log, and MCP registration.
---

Run these checks and report — read-only, change nothing:

```bash
export PATH="$HOME/.local/bin:$PATH"

# 1. Indexes known to LEANN (across all projects)
leann list 2>/dev/null || echo "leann CLI not installed"

# 2. This project's index freshness vs HEAD
if [ -d .leann/indexes ]; then
  newest=$(find .leann/indexes -type f -exec stat -f %m {} + 2>/dev/null | sort -rn | head -1)
  head_ts=$(git log -1 --format=%ct 2>/dev/null || echo 0)
  [ "${head_ts:-0}" -gt "${newest:-0}" ] && echo "STALE: index older than HEAD" || echo "FRESH"
else
  echo "No .leann/ index in this project — run /rag-init"
fi

# 3. Recent reindex activity + stuck lock
[ -f .leann/reindex.log ] && tail -5 .leann/reindex.log
[ -f .leann/reindex.lock ] && echo "NOTE: reindex.lock present — if no reindex is running, remove it: rm .leann/reindex.lock"

# 4. MCP registration
claude mcp list 2>/dev/null | grep -i leann || echo "leann-server MCP not registered → claude mcp add --scope user leann-server -- leann_mcp"
```

End with ONE recommended remedy if anything is wrong (usually `/rag-init`, the
MCP add command, or removing a stale lock). Full guide: kit repo `docs/LOCAL-RAG.md`.
