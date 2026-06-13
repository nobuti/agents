---
name: deep-research-codebase
description: Deep, multi-angle, citation-verified research over the CURRENT codebase (the repo the user is in). The local-source counterpart of /deep-research (which researches the web). Use when the user wants a thorough, grounded investigation of how something works across this repository — "deep research this codebase", "how does X work end to end here", "map how feature Y is implemented", "comprehensive investigation of this repo", "research how the auth/billing/pipeline flow works", "audit how Z is used across the code". Produces a cited report where every claim points to file:line. NOT for editing code, proposing refactors, or researching external topics.
---

# Deep Research: Codebase

The codebase counterpart of `/deep-research`. That skill fans out over the **web**; this one fans out over the **current repository**. Same harness shape — scope, parallel search, fetch/trace, adversarial verify, cited synthesis — but every source is a file in this repo and every claim resolves to a `file:line`.

This is **investigation only**. It reads, traces, verifies, and reports. It never edits code.

## When to use vs. neighbours

| Skill | Use it when |
|-------|-------------|
| **deep-research-codebase** (this) | You want a thorough, cited answer to "how does X work / where does Y live / how is Z used" **across this repo**. Output is a research report. |
| `/deep-research` | The question is about the **outside world** (libraries, vendors, facts). Output cites web URLs. |
| `explain-before-generate` | You're about to write code and need to understand a concept **first**. Output is a learning explanation, then you code. |
| `improve-codebase-architecture` | You want **refactoring opportunities** and proposed changes, not a neutral map. |

If the question is a single-fact lookup you can answer in one or two reads, just answer it — don't run the harness.

## Non-negotiables

These inherit from `AGENTS.md` and the `file_path:line` convention. They are the point of the skill:

1. **Read-only.** Never edit, never propose patches. Research produces understanding, not diffs.
2. **Every claim cites `file:line`.** No claim survives without a source in *this* repo. If you can't cite it, drop it (don't soften it).
3. **Quote before analyzing.** Extract the verbatim line(s) first, then explain what they imply. Paraphrase introduces drift.
4. **Ground in the actual source, not the framework.** "Next.js usually does X" is not a finding. "`app/api/foo/route.ts:12` calls `authenticatedRoute(...)`" is.
5. **Name the gaps.** Where evidence is missing, say so explicitly — an unanswered angle is a finding, not something to fill with a guess.

## Establish scope first

Before fanning out:

- **State the target repo explicitly.** Run `git rev-parse --show-toplevel` (or use cwd). The "current codebase" is that repo — say which one in the report header.
- **If the question is underspecified, ask 2–3 clarifying questions** before researching (which subsystem, what "works" means, depth wanted). Mirror `/deep-research`'s scoping gate.
- **If the repo ships a navigation skill** (e.g. Omnia's `/codebase-architecture`), load it before using the `Explore` agent — it knows directory structure the generic agent lacks.

## The five phases

### 1. Scope
Decompose the question into **4–6 investigation angles**. Good default angles:
- Entry points & top-level structure
- Core domain model / key abstractions
- Primary data & control flow for the feature in question
- Configuration, feature flags, environment coupling
- Tests — what behaviour they actually pin down
- Failure modes & error handling

Trim or add angles to fit the question. Small question → 2–3 angles; "comprehensive / exhaustive audit" → more.

### 2. Survey (parallel)
Launch **one read-only agent per angle, concurrently** — `Explore` for breadth (it returns conclusions, not file dumps), `general-purpose` for multi-step traces. Send them in a single message so they run in parallel. Each agent's brief: *investigate ONLY this repo, use Grep/Glob/Read, return falsifiable findings, every finding carries an exact `file:line` and a short verbatim quote.*

### 3. Trace
Take the strongest leads and read the real files yourself. Follow call paths across modules. Turn vague leads into **falsifiable claims** ("`X` is called from `Y:line` and writes to `Z`").

### 4. Verify (adversarial)
For each claim, **re-open the cited source and try to refute it.** Default to *rejected* if the citation is vague, missing, stale, or doesn't actually say what the claim says. This is the codebase analog of `/deep-research`'s "needs 2/3 refutes to kill" gate — a claim only enters the report if its `file:line` genuinely supports it. Hallucinated line numbers die here.

### 5. Synthesize
Merge duplicate findings, rank by confidence, write the report. Every claim keeps its citation. List open questions where an angle came back empty.

## Report shape

```
# Deep research: <question>
Repo: <git toplevel>   ·   Date: <ISO>

## Answer
<2–4 sentences answering the question directly, up front.>

## Findings
- **<claim>** — `path/to/file.ts:42` "<verbatim quote>" · confidence: high
- ...

## Map (optional)
<call trace / data flow as text diagram when it clarifies>

## Open questions
- <angle that lacked evidence; what would resolve it>
```

## Scaling up: orchestrated run

For a large or exhaustive audit, run the same shape as a deterministic `Workflow` (parallel survey → adversarial verify pipeline → synthesis). Workflows require explicit user opt-in ("use a workflow" / ultracode). A ready-to-run template lives in [`references/workflow-template.js`](references/workflow-template.js) — pass the question and the angles you decomposed in Scope as `args`.

For everyday questions, drive the phases inline with the `Agent` tool — no workflow needed.
