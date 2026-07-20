---
name: explain-before-generate
description: Explains concepts before writing code. Use when the user is new to a library, framework, API, repository, or domain; says explain first, help me understand, teach me, or map this at a conceptual level; or when generation would hide a design decision the user should understand first. For citation-backed end-to-end workflow traces with a full report, use deep-research-codebase instead.
---

# Explain Before Generate

## Activation Signals

Use this skill when the task is learning-shaped:

- New library, framework, API, repository, architecture, domain model, or system.
- Prompts like "explain first", "help me understand", "what am I missing", "map this", "teach me", "before coding", "learning mode".
- Requests to inspect docs/code, compare approaches, trace behavior, explain constraints, or build a mental model.
- Generation request where code would hide an important concept or design choice.

## When to delegate to deep-research-codebase

Use deep-research-codebase when the request asks for a system-wide, citation-backed report with mandatory coverage matrices (end-to-end trace, every initiator, data lifecycle). Use this skill for lightweight understanding: a concept map, a trace, a walkthrough — without the full report apparatus.

## Non-Negotiables

1. Explain before generating.
2. Quote source before analysis when source material exists.
3. Say "I don't have enough information to answer that" when sources do not support an answer.
4. Generate only after the user asks to switch modes or the concept gap is small and named.

## Source Order

Use primary sources first:

- Repository: local code, tests, config, docs, commit history when needed.
- Library/API: official docs, source, type definitions, changelog when version-sensitive.
- System/domain: internal docs, schemas, runbooks, observed behavior.

Keep quotes short and exact. Explain what each quote implies. If evidence is missing, name the missing source.

## Workflow

| Step | Action | Output |
|------|--------|--------|
| 1 | Identify gap | What user is trying to learn; what remains unknown |
| 2 | Inspect sources | File/doc refs plus short quotes |
| 3 | Map concepts | Names, roles, data flow, lifecycle, contracts, invariants, failure modes |
| 4 | Check understanding | One concrete implication or local verification step |
| 5 | Switch deliberately | Explain next, ask targeted question, or generate with stated basis |

Prefer text diagrams, bullet maps, call traces, and small examples over full implementations while learning.

## Response Shape

Use this order:

1. `Source`: short quote or file/doc reference.
2. `Concept`: explanation of what the quote means.
3. `Mental model`: relationships, sequence, or rule of thumb.
4. `Next`: smallest useful follow-up: inspect, verify, ask, or implement.

## Generation Gate

Before generating substantial code or files, check:

- Does the user understand the relevant concepts, API shape, and constraints?
- Has source evidence been inspected rather than assumed?
- Would generation hide an important design choice?
- Can a smaller explanation, trace, or example answer the learning need better?

If any answer is yes, stay in inquiry mode and explain first.

## Integrated Examples

### Unfamiliar Repository

User: "Before coding, help me understand how auth works here."

Response:

1. Quote auth route, middleware, session config, and tests.
2. Explain request lifecycle from login to protected route access.
3. Map key contracts: token/session storage, expiry, refresh, error states.
4. Give one verification step, such as running the existing auth test or tracing one request.
5. Do not patch auth until the user asks for implementation.

### Library Generation Request

User: "Generate a Fastify plugin for this, but I don't know Fastify."

Response:

1. Quote official plugin-registration docs or local plugin examples.
2. Explain plugin lifecycle, encapsulation, decoration, and error path.
3. Show a tiny annotated skeleton only if it clarifies the concept.
4. Ask whether to generate production code after the concept map is clear.

## Mode Switch

Stay in inquiry mode for: "explain first", "help me understand", "what am I missing", "map this", "teach me", "before coding".

Generate after: "now implement it", "generate the patch", "write the code", "make the change", "I understand, proceed".
