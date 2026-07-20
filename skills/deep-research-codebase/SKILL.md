---
name: deep-research-codebase
description: Investigates how a system or workflow in the current repository works. Switches between two modes: a compact concept map (for learning, "explain first", understanding before coding) and a deep trace with a full citation-backed report, mandatory maps, and coverage matrices (for "how does X work end to end"). Read-only. Use when asked to map, trace, explain, or understand a workflow, subsystem, or architecture.
---

# Deep Research: Codebase

Build an accurate mental model of a specified part of the current repository. This is investigation only: read, trace, verify, and report; never edit code or propose patches.

The skill has two modes. When depth is unclear, default to compact — the user can escalate to a deep trace with "give me the full trace".

## Two modes

### Compact — understand before acting

For learning-shaped tasks: the user is new to a library, framework, API, repository, or domain; says "explain first", "help me understand", "teach me", "what am I missing"; or asks before coding. Also for concept-level questions that don't need every initiator mapped.

Deliver a **Source → Concept → Mental model → Next** response (see Compact mode below). Stay in inquiry mode — do not generate code until understanding is confirmed.

### Deep trace — end-to-end report

For system-wide investigation: "how does X work end to end", "map the Y workflow", "research how Z is implemented". Delivers the full report template with mandatory initiator coverage, data lifecycle, process neighborhood matrices, and ASCII system map.

Use deep trace when the user asks for a trace, a map, or a system explanation at depth, or escalates from compact mode with "give me the full trace".

## Non-negotiables (both modes)

1. **Read-only.** Do not edit files, run mutating commands, or propose implementation patches.
2. **Evidence first.** Cite every factual claim with `path:line` evidence from this repository. Mark conclusions that combine evidence as **inferred**.
3. **No invented links.** If a call, data transformation, runtime behavior, or boundary cannot be established, mark it **unknown**.
4. **Quote source before analysis.** When source material exists, show the exact passage before interpreting it. Keep quotes short.
5. **Say "I don't have enough information"** when sources do not support an answer. Name the missing source.
6. **Separate facts from gaps.** Tests, configuration, static source, and observed runtime behavior have different evidentiary strength. State what was not verified.
7. **Protect scope.** Exclude generated, vendored, and dependency directories unless they are the subject or are required to establish the trace.

Investigate only the current repository unless the user explicitly asks to include external sources. Do not infer behavior from how a framework normally works.

## Compact mode

### Source order

Use primary sources first:

- Repository: local code, tests, config, docs, commit history when needed.
- Library/API: official docs, source, type definitions, changelog when version-sensitive.
- System/domain: internal docs, schemas, runbooks, observed behavior.

If evidence is missing, name the missing source.

### Response shape

Use this order:

1. **Source** — short quote or file/doc reference from the repository.
2. **Concept** — explanation of what the source means, how it works, its role.
3. **Mental model** — relationships between concepts, data flow, lifecycle, contracts, invariants, failure modes. Prefer text diagrams, bullet maps, call traces, and small examples over full implementations.
4. **Next** — smallest useful follow-up: inspect a specific file, verify a claim, ask a targeted question, or implement.

### Generation gate

Before generating substantial code or files, check:

- Does the user understand the relevant concepts, API shape, and constraints?
- Has source evidence been inspected rather than assumed?
- Would generation hide an important design choice?

If any answer is yes, stay in inquiry mode and explain first. Switch to code generation only after the user says "now implement it", "generate the patch", "write the code", "make the change", or "I understand, proceed".

### Mode switch vocabulary

Stay in inquiry mode for: "explain first", "help me understand", "what am I missing", "map this", "teach me", "before coding".

Escalate to deep trace when the user says: "give me the full trace", "map everything", "end to end". A compact-mode response ends with "want the deep trace?" when the topic is complex enough to warrant one.

### Compact examples

**Unfamiliar repository:**
User: "Before coding, help me understand how auth works here."

Response:
1. Quote auth route, middleware, session config, and tests.
2. Explain request lifecycle from login to protected route access.
3. Map key contracts: token/session storage, expiry, refresh, error states.
4. Give one verification step, such as running the existing auth test.
5. Do not patch auth until the user asks for implementation.

**Library generation request:**
User: "Generate a Fastify plugin for this, but I don't know Fastify."

Response:
1. Quote official plugin-registration docs or local plugin examples.
2. Explain plugin lifecycle, encapsulation, decoration, and error path.
3. Show a tiny annotated skeleton only if it clarifies the concept.
4. Ask whether to generate production code after the concept map is clear.

## Deep trace mode

A complete workflow trace maps every materially distinct discovered initiation path to its shared pipeline and terminal effects, including material decisions and failure paths. Do not substitute a list of files or isolated facts for that trace.

### Additional non-negotiables (deep trace only)

8. **Discover all initiators before tracing.** Starting from the shared entry point, coordinator, queue/topic, or persisted state transition, search upstream for every materially distinct initiation path in scope. Cover UI actions, API clients/routes, CLI commands, schedulers/crons, event producers/consumers, webhooks, startup hooks, and domain/onboarding flows. Record every candidate in the Initiator coverage matrix before selecting a representative path.
9. **Identify each initiator.** For each included candidate, establish who or what starts it and how. Cite the initiating code, trigger boundary, and internal entry point; mark any unproven segment **unknown**.
10. **Trace data, not just functions.** For every material input, state transition, and output, identify its schema/type, identifiers, owner, transformation, persistence store/table/collection, and known consumers.
11. **Place the workflow in the system.** Establish the application capability and user outcome, its upstream producers, sibling processes, and downstream consumers/handoffs. Do not claim product criticality or customer impact without local evidence; state it as unknown.
12. **Trace the whole path.** Map each distinct initiator to the convergence point, then map the shared path: initiator → trigger → entry → coordination → work/data transformation → state or external boundary → terminal effect. Include material error, retry, and no-op branches when evidence exists.

### Scope and repository baseline

1. Identify the repository root, package/workspace in scope, current revision, and whether unrelated local changes exist.
2. Restate the target system and requested depth. Default to all materially distinct internal initiation paths that converge on the workflow; do not silently narrow to one production path. If the user explicitly limits the scope, list excluded initiators and why.
3. Define the trace boundary: initiating actor(s), trigger(s), internal entry point(s), convergence point(s), expected terminal effect(s), and relevant runtime contexts.
4. Choose 3–6 investigation angles. Cover all applicable lenses: application/customer context, initiator discovery, entry points, orchestration, data lifecycle and persistence, adjacent processes and consumers, configuration, failure impact, observability, and tests. For each omitted lens, state why.

If a conclusion depends on a claimed data-shape invariant, inspect three representative authorized records when they exist. If fewer records exist or they are inaccessible or sensitive, state that limitation.

### Investigation method

#### 1. Inventory and application context
Locate the owning package, entry points, configuration, schemas/types, database schema/migrations, repository/query code, tests, UI surfaces, jobs/schedulers, event/queue definitions, and relevant documentation. Find evidence of the application capability and user outcome. Identify likely generated files and ignore them.

#### 2. Discover initiation paths (coverage gate)
Search upstream for initiation candidates: direct/transitive callers, imports/exports, route clients and form/mutation handlers, queue publishers/consumers, event names/producers, cron/schedule registration, CLI/startup registrations, state transitions, and tests/fixtures that instantiate the workflow.

Build an **Initiator coverage matrix**:

| Initiator/actor | Trigger and boundary | Path to convergence point | Status | Evidence |
|---|---|---|---|---|
| <user/system> | <UI action, cron, event, API> | <calls/publishes/enqueues to shared point> | included / excluded by user scope / unresolved | `<repo-relative-path>:line` |

Every discovered candidate must be **included**, **explicitly excluded by user scope**, or **unresolved** with the search limitation that prevented verification.

#### 3. Trace initiation and entry
For every included candidate, establish the actor, trigger mechanism, and boundary. For UI flows, trace user action → event handler → client request → server entry. For scheduled/event-driven flows, trace scheduler/producer → registration → consumer → handler. Trace each path only until it reaches a documented convergence point; then trace the shared path once.

#### 4. Trace the shared path
Follow the call or event path from convergence point through completion. At each hop capture: component/function and responsibility; input/output contract; caller/callee relationship; state mutation, external call, emitted event, or returned result.

#### 5. Trace the data lifecycle (coverage gate)
Build a **Data lifecycle matrix** for the material domain data. Follow data from input through transformations, state transitions, persistence, and downstream reads.

| Domain data | Shape/type and identifiers | Created or transformed by | Persisted store/table/collection | Read by / user-visible outcome | Evidence |
|---|---|---|---|---|---|
| <result, status, entity> | <schema/type, IDs, cardinality> | <function/component> | <database and relation> | <consumer/UI/API/job> | `<repo-relative-path>:line` |

List every database, cache, queue, file store, or external service that is a material source of truth.

#### 6. Map process neighborhood and impact
Find processes before, alongside, and after the target. Trace their relationship through shared data, events, queues, state transitions, or explicit calls. Establish customer and operational impact from evidence.

#### 7. Trace meaningful alternatives
Trace material branches: validation failures, retries, fallback providers, empty/no-op outcomes, asynchronous handoffs, authorization gates, and terminal errors.

#### 8. Establish runtime context
Inspect configuration, feature flags, environment coupling, dependency injection, observability, and tests.

#### 9. Verify and synthesize
Re-open the sources supporting the final path. Reject or qualify a claim when its citation does not actually support it.

### Parallel work (optional)

The skill must succeed with a single investigator. If reliable isolated workers are available, they may investigate independent discovery angles in parallel. Default to sequential investigation; use at most 2–3 concurrent workers. Useful partitions: (1) reverse call graph, routes, queues, events, all initiators; (2) domain types, persistence schemas, writes, downstream readers; (3) UI/product context, state visibility, sibling workflows, downstream jobs. Treat worker output as leads, not final evidence.

### Deep trace report

```md
# Codebase research: <system or question>
Repository: <root> · Package/workspace: <scope> · Revision: <SHA>
Working tree: <clean | relevant local changes noted> · Date: <ISO-8601>
Initiation coverage: <complete | scoped by user | incomplete> · Scope assumption: <only when needed>

## Direct answer
<3–6 sentences explaining the application capability/user outcome, all included initiation paths, shared coordination, data outputs, adjacent-process handoffs, and the strongest evidenced failure impact. If any coverage gate is incomplete, start by saying what remains unresolved.>

## Application and customer context
- **Capability and user outcome:** <with evidence>
- **Operational role:** <source-supported role; do not assert "core/critical" without evidence>
- **Failure and recovery impact:** <customer-visible state, stale/missing data, recovery path, or Unknown>

## Initiator coverage
| Initiator/actor | Trigger and boundary | Path to convergence point | Status | Evidence |
|---|---|---|---|---|

## System map
```text
[Initiator A: actor/system\npath:line] -- <UI action, schedule, event, API call> --\
[Initiator B: actor/system\npath:line] -- <trigger> ------------------------------+--> [Convergence / internal entry\npath:line]
[Initiator C: actor/system\npath:line] -- <trigger> ------------------------------/            |
                                                                                                   v
[Coordinator\npath:line] --> [Work / transformation\npath:line] --> {Decision\npath:line}
                                                               | success --> [Persistence/external effect\npath:line] --> [Terminal response/event\npath:line]
                                                               ` failure --> [Error / retry / no-op\npath:line]

Show every included initiation path before it merges. Each bracket includes repository-relative `path:line`; mark unproven links as `Unknown`.
```

<!-- Optional when the renderer supports Mermaid: provide the same map as a Mermaid flowchart. -->

## Workflow walkthrough
1. **Initiators, triggers, and convergence** — account for each included path, with citations.
2. **Shared coordination and decisions** — explanation with citations.
3. **Data transformations and state transitions** — input → transformations → typed output.
4. **Persistence, external boundaries, and terminal effects** — with citations.
5. **Failure, retry, authorization, and no-op paths** — only evidenced paths.

## Data lifecycle
| Domain data | Shape/type and identifiers | Created or transformed by | Persisted store/table/collection | Read by / user-visible outcome | Evidence |
|---|---|---|---|---|---|

## Process neighborhood
| Relationship | Process | Shared data/event/state | Ordering and effect on this workflow | Evidence |
|---|---|---|---|---|
| Upstream producer / sibling / downstream consumer | <process> | <boundary> | <before, parallel, after, blocks, enriches, consumes> | `<repo-relative-path>:line` |

## Component map
| Component | Responsibility | Called by / trigger | Calls, owns, or emits | Evidence |
|---|---|---|---|---|

## Runtime and configuration
<Feature flags, environment dependencies, deployment/runtime assumptions, and what remains unverified.>

## Tests and coverage limits
<What tests prove, what behavior is only statically inferred, and important untested paths.>

## Evidence notes
- **Direct:** <facts explicitly established by source/test/config>
- **Inferred:** <conclusions derived from cited links>

## Open questions and coverage gaps
- <unknown link, inaccessible dependency, failed worker, or missing test; what would resolve it>
```

The **Direct answer**, **Initiator coverage**, **Data lifecycle**, **Process neighborhood**, and **System map** are mandatory. Use the portable ASCII diagram above. Every node must cite its source; mark unsupported links as `Unknown` — do not omit them to make the flow appear complete.

### Illustrative example (deep trace, miniature)

A filled-in fragment for a hypothetical "password reset" trace — showing the expected density:

~~~~
# Codebase research: password reset flow
Repository: myapp · Package: auth · Revision: abc1234
Initiation coverage: scoped by user

## Direct answer
Password reset is triggered by the UI "Forgot?" link (sends email) or the API
POST /auth/reset (for admins). Both converge on UserService.requestReset in
auth/service.ts:42, which writes a ResetToken to the `reset_tokens` table,
emits a "reset.requested" event, and the email job picks it up. Failure: stale
tokens persist until expiry; no retry path exists (auth/service.ts:56 logs and
swallows).

## System map
```
[Web: user clicks "Forgot?"
 ui/login.tsx:18] -- POST /api/reset --\
[API client: admin GUI
 routes/admin.ts:33]  -- POST /auth/reset ----+--> [UserService.requestReset
                                                         auth/service.ts:42]
                                                     |
                                                     v
                                [ResetToken: write to reset_tokens
                                 migrations/002.ts:12] --> [Event: reset.requested
                                                                      pubsub.ts:8]
                                                                    |
                                                                    v
                                                         [EmailJob.send
                                                          jobs/email.ts:22]
```

## Data lifecycle
| Domain data | Shape                            | Created by             | Persisted    | Read by       | Evidence           |
|-------------|----------------------------------|------------------------|--------------|---------------|--------------------|
| ResetToken  | {id, userId, token, expiresAt}   | UserService.requestReset | reset_tokens | EmailJob.send | auth/service.ts:42 |

## Process neighbourhood
| Relationship         | Process   | Shared boundary       | Effect            | Evidence        |
|----------------------|-----------|-----------------------|-------------------|-----------------|
| Downstream consumer  | EmailJob  | reset.requested event | Sends reset email | jobs/email.ts:22 |
~~~~

This is a fragment to illustrate the format and density, not a complete trace.

### Deep trace completion check

Before responding, verify:

- [ ] The target repository, revision, and scope are stated.
- [ ] An Initiator coverage matrix accounts for every discovered candidate as included, explicitly excluded by user scope, or unresolved.
- [ ] `Initiation coverage` is `complete` only when no discovered candidate is unresolved; otherwise `scoped by user` or `incomplete`, and the Direct answer says so.
- [ ] Every included initiator has an actor/system, trigger mechanism, path to convergence, and repository-relative `path:line` evidence.
- [ ] The shared path is closed from each included initiator through persisted/output data to terminal consumer, or every unknown link is explicit.
- [ ] A Data lifecycle matrix identifies material types/schemas, IDs, transformations, stores/tables, and readers.
- [ ] A Process neighborhood matrix distinguishes upstream producers, sibling processes, and downstream consumers/handoffs.
- [ ] Application/customer context explains the success outcome and failure/recovery impact; unproven criticality is `Unknown`.
- [ ] The mandatory ASCII diagram, coverage matrices, and walkthrough agree.
- [ ] Every factual claim has valid local evidence; inferences are labeled.
- [ ] No file was modified.
