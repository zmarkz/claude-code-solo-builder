# AI Model Routing Pattern

> The most important cost optimization in any AI-enabled app: never send every query to the expensive model.

---

## The Mandatory Rule

**Every app that makes an AI call MUST route through a classifier. Apps MUST NOT call Anthropic/OpenAI/Ollama directly.**

This rule exists because:
1. 85-93% of queries are "simple" and can be answered by a free local model
2. Direct API calls couple your business logic to a specific model provider
3. Without routing, costs scale linearly with usage — with routing, they're near-constant

---

## The Classification Pattern

```
User query
    │
    ▼
classifyQuery(message)
    │
    ├── COMPLEX → Claude Sonnet (paid, ~$0.001–0.003)
    │   analyze, recommend, decide, sell, buy, risk,
    │   plan, forecast, rebalance, should I, compare,
    │   strategy, tax, deep dive, outlook, action plan,
    │   which is best/worst, portfolio health
    │
    └── SIMPLE  → Local Qwen via Ollama (FREE, $0)
        what is, how many, show me, list, allocation,
        explain, define, total value, how much, summary,
        what does, meaning, count, sector

DEFAULT → COMPLEX (use Claude if unsure)
```

---

## Implementation

### Query Classifier

```typescript
// Keyword-based classification (fast, no AI cost for the routing itself)
const COMPLEX_KEYWORDS = [
  "analyze", "analyse", "recommend", "sell", "buy", "rebalance",
  "should i", "compare", "risk", "strategy", "tax", "harvest",
  "what-if", "which stock", "best", "worst", "portfolio health",
  "deep dive", "outlook", "forecast", "action plan", "decide",
  "evaluate", "assess"
]

const SIMPLE_KEYWORDS = [
  "what is", "how many", "show me", "list", "allocation", "explain",
  "define", "total value", "how much", "summary", "what does",
  "meaning", "sector", "count", "display", "tell me about"
]

export function classifyQuery(message: string): "COMPLEX" | "SIMPLE" {
  const lower = message.toLowerCase()
  
  // Check COMPLEX first (higher priority)
  const isComplex = COMPLEX_KEYWORDS.some(k => lower.includes(k))
  if (isComplex) return "COMPLEX"
  
  const isSimple = SIMPLE_KEYWORDS.some(k => lower.includes(k))
  if (isSimple) return "SIMPLE"
  
  // Default to COMPLEX — safer choice
  return "COMPLEX"
}
```

### Agent Farm Router (Backend)

```typescript
import Anthropic from "@anthropic-ai/sdk"

const TEMPLATE_COMPLEX = {
  provider: "anthropic",
  model: "claude-sonnet-4-6",
  systemPrompt: `You are a financial analyst. Return ONLY valid JSON in this format:
{
  "summary": { "totalValue": "...", "pnl": "...", "keyInsight": "..." },
  "sections": [
    { "type": "table", "title": "...", "columns": [...], "rows": [[...]] },
    { "type": "recommendations", "items": [{"action": "BUY/SELL/HOLD", "reason": "..."}] },
    { "type": "warning", "text": "..." },
    { "type": "disclaimer", "text": "AI-generated. Not investment advice." }
  ]
}`,
}

const TEMPLATE_SIMPLE = {
  provider: "ollama",
  model: "qwen2.5-coder:14b",
  baseUrl: "http://localhost:11434",
}

export async function routeQuery(message: string, context: string) {
  const complexity = classifyQuery(message)
  
  console.log(`[ROUTING] query="${message.slice(0,50)}" → ${complexity}`)
  const start = Date.now()
  
  if (complexity === "SIMPLE") {
    // Stream from local Qwen
    const response = await fetch("http://localhost:11434/api/generate", {
      method: "POST",
      body: JSON.stringify({
        model: TEMPLATE_SIMPLE.model,
        prompt: `${context}\n\nUser: ${message}`,
        stream: true,
      }),
    })
    console.log(`[RESULT]  SIMPLE → Qwen local | STREAMING_MARKDOWN | cost=₹0.00`)
    return { type: "stream", response }
    
  } else {
    // Call Claude with structured output
    const client = new Anthropic()
    const result = await client.messages.create({
      model: TEMPLATE_COMPLEX.model,
      max_tokens: 4096,
      system: [
        {
          type: "text",
          text: TEMPLATE_COMPLEX.systemPrompt,
          cache_control: { type: "ephemeral" }, // Cache the system prompt
        },
      ],
      messages: [{ role: "user", content: `${context}\n\nUser: ${message}` }],
    })
    
    const elapsed = Date.now() - start
    const outputChars = result.content[0].type === "text" ? result.content[0].text.length : 0
    const inputTokens = result.usage.input_tokens
    const outputTokens = result.usage.output_tokens
    const costInr = ((inputTokens * 0.000003 + outputTokens * 0.000015) * 84).toFixed(4)
    
    console.log(`[RESULT]  COMPLEX → Claude | ${elapsed}ms | ${outputChars}chars | ~₹${costInr} | JSON_STRUCTURED`)
    
    return { type: "structured", content: result.content[0] }
  }
}
```

### Frontend Rendering

```tsx
// COMPLEX → StructuredResponse component
// SIMPLE → MarkdownMessage component (streaming)

type Message =
  | { type: "structured"; data: StructuredResponse }
  | { type: "stream"; content: string }

function ChatMessage({ message }: { message: Message }) {
  if (message.type === "structured") {
    return <StructuredResponse data={message.data} />
  }
  return <MarkdownMessage content={message.content} />
}

// StructuredResponse renders sections as cards, tables, badges
function StructuredResponse({ data }: { data: StructuredResponse }) {
  return (
    <div>
      <SummaryCard summary={data.summary} />
      {data.sections.map((section, i) => (
        <Section key={i} section={section} />
      ))}
    </div>
  )
}
```

---

## Local Model Setup (Ollama)

```bash
# Install Ollama
brew install ollama
ollama serve &

# Pull models
ollama pull qwen2.5-coder:14b    # Primary local model (~9GB)
ollama pull nomic-embed-text      # Embeddings for RAG (~274MB)
# Optional: smaller/faster
ollama pull qwen2.5-coder:7b     # Faster, slightly less capable
# Optional: for coding-specific tasks
ollama pull deepseek-coder-v2    # Strong at code tasks
```

**Hardware requirements for qwen2.5-coder:14b:**
- RAM: 16GB minimum, 32GB recommended
- Storage: 9GB
- M1/M2/M4 Mac: runs well via Metal acceleration
- CPU-only x86: runs but slowly (30-60s per response)

**Alternative local models:**
| Model | Size | Best for |
|-------|------|---------|
| `qwen2.5-coder:14b` | 9GB | General purpose, code |
| `qwen3-coder:32b` | 20GB | Better quality, needs 32GB RAM |
| `llama3.1:8b` | 5GB | Fast, good for explanations |
| `gemma2:9b` | 6GB | Good reasoning, fast |

---

## Response Format: Structured JSON (COMPLEX)

For COMPLEX queries, always request structured JSON:

```json
{
  "summary": {
    "totalValue": "₹1.37Cr",
    "pnl": "+₹46.1L",
    "pnlPct": "+50.89%",
    "holdingsCount": 29,
    "keyInsight": "10 out of 29 holdings are in the red"
  },
  "sections": [
    {
      "type": "table",
      "title": "Sell Immediately",
      "emoji": "🔴",
      "columns": ["Stock", "Loss", "Return", "Reason"],
      "rows": [
        ["ITC", "-₹13.8K", "-32%", "No catalyst"],
        ["Reliance", "-₹8.2K", "-18%", "Margin pressure"]
      ]
    },
    {
      "type": "recommendations",
      "title": "Buy / Add More",
      "emoji": "🟢",
      "items": [
        {"stock": "HDFC Bank", "action": "BUY", "reason": "Rate cut tailwind"}
      ]
    },
    {
      "type": "warning",
      "text": "IT sector 28% concentration — consider reducing to 20%"
    },
    {
      "type": "disclaimer",
      "text": "AI-generated analysis. Not investment advice."
    }
  ]
}
```

**Why structured JSON over streaming prose:**
- Deterministic rendering (no layout decisions made by the model)
- Cacheable (same schema = prompt cache hit)
- Separable (summary renders first, sections load progressively)
- Auditable (log the entire JSON for compliance/debugging)

---

## Routing for Different App Types

### Portfolio / Finance Apps
```typescript
COMPLEX: analyze, sell, buy, recommend, risk, tax, rebalance
SIMPLE: what is, list, total, how many, show me
```

### Customer Support Apps
```typescript
COMPLEX: escalate, refund, dispute, resolve, investigate, what went wrong
SIMPLE: status, order number, tracking, FAQ, how do I
```

### Developer Tools
```typescript
COMPLEX: review, audit, refactor, design, architect, security
SIMPLE: what does this do, explain, show me, what is, list
```

### Content / Writing Apps
```typescript
COMPLEX: write, create, draft, generate, improve, rewrite
SIMPLE: summarize, extract, count, format, list
```

---

## Loop-Role Model Routing (developer harness — distinct from the above)

Everything above routes **product** AI calls (your app's features, via the Agent Farm). This
section is a *different axis*: which model each **swarm role** uses when you build software with
Claude Code (Modes 1–3 in `docs/SWARM-ORCHESTRATION.md`). It keeps the parallel-loop token
multiplier in check — you pay Opus rates only for the two roles that are *not* parallelized.

| Loop role | Model | Why |
|---|---|---|
| Orchestrator (decompose, DAG, integrate decisions) | Opus 4.8 | Judgment-heavy, low token volume |
| Reviewer / integrator | Opus 4.8 | Quality gate + cross-leaf contract tests |
| Feature leaf (build a slice) | Sonnet 4.6 | The throughput workhorse — most leaves |
| Grind leaf (migrations, boilerplate, renames) | Haiku 4.5 / local Qwen | High volume, low judgment → near-zero cost |

In `/orchestrate-loops`, the orchestrator sets each leaf's model by this table based on the task's
nature. Since most leaves are Sonnet and grind leaves are local/Haiku, a wide overnight fan-out
stays affordable while the expensive Opus roles run singly.

### Fast mode changes the Opus calculus (Opus 4.8)

The split above — "Opus only for orchestrator/reviewer, Sonnet for the bulk" — was designed when
Opus was the *slow, expensive* tier and pushing implementation onto Sonnet bought real wall-clock.
**Opus 4.8 fast mode** (toggle with `/fast`, or per-agent where supported) gives Opus-class
reasoning at much higher throughput **without downgrading the model** — it stays Opus, just faster.
That weakens the original justification for the Sonnet split:

- **Interactive driving, orchestrator, reviewer** → Opus 4.8 **with fast mode on** is now the
  sensible default. You no longer pay the old latency tax for Opus judgment.
- **Feature leaves** → still Sonnet 4.6 by default for token economy on wide fan-outs; promote a
  leaf to Opus 4.8 (fast) when the slice is genuinely judgment-heavy (auth, money, schema design).
- **Grind leaves** → unchanged: Haiku 4.5 / local Qwen.

This is the *developer-harness* axis only. It does **not** change the product routing above
(`classifyQuery` → Sonnet vs local Qwen), which is about your app's runtime AI calls and stays as
is. Keep the two axes separate.

---

## Cost Monitoring and Logging

Log every routing decision:

```typescript
// Log format (parseable with grep/awk)
console.log(`[ROUTING] query="${message.slice(0,60)}" → ${complexity} → ${model}`)
console.log(`[RESULT]  ${complexity} → ${model} | ${elapsed}ms | ${chars}chars | ~₹${cost} | ${format}`)

// Monthly cost aggregation
// grep "[RESULT]" app.log | grep -v "₹0" | awk -F"₹" '{sum+=$2} END {print "Monthly:", sum}'
```

**Alert thresholds:**
- Single call > ₹1 ($0.012) → investigate (probably too much context in the prompt)
- Daily total > ₹50 ($0.60) → check if routing is working
- COMPLEX ratio > 20% → re-examine classification keywords

---

## Fallback Handling

Always handle the case where local Ollama is unavailable:

```typescript
async function routeWithFallback(message: string, context: string) {
  const complexity = classifyQuery(message)
  
  if (complexity === "SIMPLE") {
    try {
      return await callOllama(message, context)
    } catch (err) {
      console.warn("[ROUTING] Ollama unavailable, falling back to Claude for simple query")
      // Fall through to Claude
    }
  }
  
  // COMPLEX or fallback from SIMPLE
  return await callClaude(message, context)
}
```

---

*See also: `docs/TOKEN-EFFICIENCY.md` for the broader cost savings strategy, `PLAYBOOK.md` Part 3.10 for the mandatory routing rule.*
