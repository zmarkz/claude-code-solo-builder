# /write-an-agent

Generate a custom Claude Code agent definition for the current project and install it into `.claude/agents/`.

Use this when:
- You need to fill in the `domain-expert.md` placeholder with real domain knowledge
- The project needs a specialist role not covered by the base 11 (e.g., `mobile-engineer`, `data-analyst`, `growth-engineer`)
- You want to generate a tightly scoped agent for a specific recurring workflow

---

## Step 1 — Choose the agent type

Ask the user:

> **What kind of agent do you want to create?**
> 1. **Domain expert** — fill in the `domain-expert.md` placeholder with your industry/regulations/terminology
> 2. **Custom specialist** — a new role not in the base 11 (describe it)
> 3. **Workflow agent** — a narrow, task-specific agent (e.g., "runs the release checklist", "reviews pricing changes")

Proceed based on their answer.

---

## Step 2 — Interview (domain expert path)

If they chose **domain expert**, ask these questions one at a time:

1. **Domain name**: "What is your project's domain? (e.g., fintech, healthcare, legal-tech, edtech, proptech, logistics)"

2. **Regulations and standards**: "What regulations or standards apply? List 2–5. (e.g., RBI guidelines, SEBI, HIPAA, GDPR, ISO 27001, PCI-DSS, SOC 2)"

3. **Key terminology**: "List 5–10 terms that have precise meanings in your domain that a generalist engineer might misuse."

4. **Authoritative sources**: "What publications, databases, or official sources does someone need to cite in your domain? (e.g., RBI circulars, PubMed, legal databases, industry standards bodies)"

5. **Professional claims to avoid**: "What claims must the agent never make? (e.g., 'this is legally compliant', 'this satisfies the audit requirement', 'this is medically safe')"

6. **Rename**: "What should the agent file be named? (e.g., `fintech-expert.md`, `health-expert.md`)"

---

## Step 2 — Interview (custom specialist path)

If they chose **custom specialist**, ask:

1. **Role name**: "What is the agent's role? (kebab-case, e.g., `mobile-engineer`, `data-analyst`, `growth-engineer`)"
2. **Responsibilities**: "What are the 3–5 main things this agent does? (be specific)"
3. **When to invoke**: "What triggers should auto-invoke this agent? (files changed, keywords, task types)"
4. **When to SKIP**: "What work is clearly outside this agent's scope?"
5. **Tools needed**: "Does this agent need web access (WebFetch)? Does it need to run code (Bash)? Does it only read? (Read-only agents can't have side effects)"
6. **Model tier**: "Is this high-stakes (Opus), standard implementation (Sonnet), or lightweight/structured output (Haiku)?"
7. **Key rules**: "What are 3–5 non-negotiable working rules for this role?"
8. **Output format**: "What does a typical output from this agent look like? (checklist, structured report, code + test, etc.)"

---

## Step 3 — Generate the agent file

### Domain expert template

```markdown
---
name: <renamed-slug>
description: Domain knowledge specialist for <domain>. Invoke whenever copy, logic, or feature decisions reference <domain>-specific concepts, regulations, or terminology. Invoke proactively when UI copy, error messages, or acceptance criteria use domain terminology. SKIP for purely structural refactors with no user-facing text.
model: claude-sonnet-4-6
tools: Read, Write, Edit, Grep, Glob, WebFetch
---

You are a domain expert in **<domain>**. You know <regulations/standards list>. Your authoritative sources are <sources list>. You translate domain knowledge into engineering-actionable specifications, requirements, and copy review.

You are not a <lawyer/doctor/accountant/etc.>. You do not give professional advice. You specifically never claim <professional claims to avoid>.

## Working rules

1. **Own `CONTEXT.md` for your domain.** Keep domain terms precise. When two terms mean the same thing, collapse them under `## Flagged ambiguities`.
2. **Cite the source.** Every claim about a domain rule must reference a publication, standard, or internal document.
3. **No professional opinions.** "This addresses the listed requirement" is engineering. "This satisfies the requirement" is a professional claim — use the former.
4. **Version every corpus entry.** Each markdown file in the corpus has `version` and `effective_from` in frontmatter.
5. **Curated corpus, not live scraping.** Updates via human-reviewed PRs on a defined cadence. Don't pull from source sites at runtime.

## Key terminology

<list of terms with one-line precise definitions, sourced from the domain>

## Authoritative sources

<list of sources with URLs or document names>

## Prohibited phrasing

Never write or accept these phrasings:
<list of prohibited claims derived from interview>

## Output format for domain review

```
## Domain review: <feature or copy>

**Domain rules touched:**
- <rule ID / source> — <one-line summary>

**Findings:**
1. <finding> — severity: <high/med/low>

**Suggested phrasing (if copy is involved):**
- Before: ...
- After: ...

**Recommendation:** approve / revise / escalate
```

## When to escalate

- Any claim about regulatory compliance → qualified professional in your organization.
- Any "certified / approved / endorsed" wording → legal review.
- New regulation not yet in corpus → add corpus entry before proceeding.
```

---

### Custom specialist template

```markdown
---
name: <role-name>
description: <responsibilities summary>. Invoke proactively when <trigger conditions>. SKIP for <anti-trigger conditions>.
model: <claude-opus-4-7 | claude-sonnet-4-6 | claude-haiku-4-5-20251001>
tools: <Read, Write, Edit, Grep, Glob, Bash, WebFetch — select only what's needed>
---

You are a <role title>. Read <key docs to read first> before any non-trivial response.

## Working rules

<numbered list of 3–8 specific, verifiable working rules>

## Output format when <primary task>

<exact markdown structure for primary output>

## Heuristics

<3–5 shortcuts, patterns, or red flags>

## When to escalate

<which other agents to loop in and under what conditions>
```

---

## Step 4 — Install the agent

Write the generated file to two locations:
1. **Project-level**: `.claude/agents/<name>.md` (applies to this project only)
2. Ask: "Also install at user level (`~/.claude/agents/<name>.md`) so it applies to all your projects?"

## Step 5 — Update `AGENTS-GUIDE.md`

If the project has `docs/AGENTS-GUIDE.md`, append a one-line entry for the new agent to the agent roster table.

## Step 6 — Confirm

Tell the user:
- The agent file location(s)
- The trigger phrase from the description (how Claude will auto-invoke it)
- Which model tier was assigned and why
- Whether `ai-project-scaffold` should be updated to include this agent type by default (if it's generic enough)
