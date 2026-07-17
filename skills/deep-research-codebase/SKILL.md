---
name: deep-research-codebase
description: Investigates a specified system or workflow in the current codebase and produces a citation-backed mental model. Use for end-to-end flow tracing, architecture mapping, subsystem comprehension, and deep codebase research. Produces mandatory ASCII maps; initiator, data-lifecycle, and adjacent-process coverage; product/customer and failure-impact context; runtime constraints; test coverage; and explicit unknowns. Read-only; works with or without parallel workers.
---

# Deep Research: Codebase

Build an accurate, end-to-end mental model of a specified part of the current repository. This is investigation only: read, trace, verify, and report; never edit code or propose patches.

A complete workflow trace maps every materially distinct discovered initiation path to its shared pipeline and terminal effects, including material decisions and failure paths. Do not substitute a list of files or isolated facts for that trace.

## Use and boundaries

Use this skill for requests such as:
- “How does X work end to end?”
- “Map the Y workflow/system.”
- “Help me understand this subsystem.”
- “Research how Z is implemented across this repository.”

For a single fact answerable with one or two reads, answer directly instead.

Investigate only the current repository unless the user explicitly asks to include external sources. Do not infer behavior from how a framework normally works.

## Non-negotiables

1. **Read-only.** Do not edit files, run mutating commands, or propose implementation patches.
2. **Evidence first.** Cite every factual claim with `path:line` evidence from this repository. Mark conclusions that combine evidence as **inferred** and cite all supporting locations.
3. **No invented links.** If a call, data transformation, runtime behavior, or boundary cannot be established, mark it **unknown**.
4. **Discover all initiators before tracing.** Starting from the shared entry point, coordinator, queue/topic, or persisted state transition, search upstream for every materially distinct initiation path in scope. Cover UI actions, API clients/routes, CLI commands, schedulers/crons, event producers/consumers, webhooks, startup hooks, and domain/onboarding flows. Record every candidate in the Initiator coverage matrix before selecting a representative path.
5. **Identify each initiator.** For each included candidate, establish who or what starts it and how: user/persona and UI action, HTTP/API client, CLI invocation, scheduler/cron, event producer, webhook, startup hook, or another system. Cite the initiating code, trigger boundary, and internal entry point; mark any unproven segment **unknown**.
6. **Trace data, not just functions.** For every material input, state transition, and output, identify its schema/type, identifiers, owner, transformation, persistence store/table/collection, and known consumers. A workflow that persists data is incomplete without its persistence model and downstream reads.
7. **Place the workflow in the system.** Establish the application capability and user outcome it serves, its upstream producers, sibling processes sharing the same domain/state, and downstream consumers/handoffs. Do not claim product criticality or customer impact without local evidence; state it as unknown when it cannot be shown.
8. **Trace the whole path.** Map each distinct initiator to the convergence point, then map the shared path: initiator → trigger → entry → coordination → work/data transformation → state or external boundary → terminal effect. Include material error, retry, and no-op branches when evidence exists.
9. **Separate facts from gaps.** Tests, configuration, static source, and observed runtime behavior have different evidentiary strength. State what was not verified.
10. **Protect scope.** Exclude generated, vendored, and dependency directories unless they are the subject or are required to establish the trace.

## Scope and repository baseline

1. Identify the repository root, package/workspace in scope, current revision, and whether unrelated local changes exist.
2. Restate the target system and requested depth. For a deep workflow request, default to all materially distinct internal initiation paths that converge on the workflow; do not silently narrow to one production path. If the user explicitly limits the scope, list excluded initiators and why.
3. Define the trace boundary: initiating actor(s), trigger(s), internal entry point(s), convergence point(s), expected terminal effect(s), and relevant runtime contexts (browser/UI, HTTP, job, CLI, event consumer, startup hook, etc.).
4. Choose 3–6 investigation angles appropriate to the target. Cover all applicable lenses: application/customer context, initiator discovery, entry points, orchestration, data lifecycle and persistence, adjacent processes and consumers, configuration, failure impact, observability, and tests. For each omitted lens, state why it does not apply or is unverified.

If a conclusion depends on a claimed data-shape invariant, inspect three representative authorized records when they exist. If fewer records exist or they are inaccessible or sensitive, state that limitation rather than claiming validation.

## Investigation method

### 1. Inventory and application context
Locate the owning package, entry points, configuration, schemas/types, database schema/migrations, repository/query code, tests, UI surfaces, jobs/schedulers, event/queue definitions, and relevant documentation. Find evidence of the application capability and user outcome: product copy, UI routes/components, API contracts, domain terminology, and tests. Identify likely generated files and ignore them unless needed.

### 2. Discover initiation paths (coverage gate)
Before following the shared path, work backward and search broadly for initiation candidates. Search for direct/transitive callers; imports and exports; route clients and form/mutation handlers; queue publishers and consumers; event names/producers; cron/schedule registration; CLI/startup registrations; state transitions; and tests/fixtures that instantiate the workflow.

Build an **Initiator coverage matrix**. A candidate is not resolved merely because another path reaches the same coordinator.

| Initiator/actor | Trigger and boundary | Path to convergence point | Status | Evidence |
|---|---|---|---|---|
| <user/system> | <UI action, cron, event, API, etc.> | <calls/publishes/enqueues to shared point> | included / excluded by user scope / unresolved | `<repo-relative-path>:line` |

Every discovered candidate must be **included**, **explicitly excluded by user scope**, or **unresolved** with the search limitation that prevented verification. Do not call the workflow complete while discovered candidates are merely mentioned in Open questions.

### 3. Trace initiation and entry
For every included candidate, establish the actor or system, trigger mechanism, and boundary that accepts it. For UI flows, trace the user action, event handler, client request, and server entry. For scheduled/event-driven flows, trace the scheduler or producer, registration/configuration, consumer, and handler. Trace each path only until it reaches a documented convergence point; then trace the shared path once. If source cannot prove the real-world actor, state the narrowest supported conclusion instead.

### 4. Trace the shared path
Follow the actual call or event path from the convergence point through completion. At each hop, capture:
- component/function and responsibility;
- input and output contract or transformation;
- caller/callee or producer/consumer relationship;
- state mutation, external call, emitted event, observable signal, or returned result.

### 5. Trace the data lifecycle (coverage gate)
Build a **Data lifecycle matrix** for the material domain data. Follow data from input through in-memory transformations, state transitions, persistence, and downstream reads. Inspect type/schema definitions, ORM/repository code, migrations/DDL, query code, and consumer code—not only the write call.

| Domain data | Shape/type and identifiers | Created or transformed by | Persisted store/table/collection | Read by / user-visible outcome | Evidence |
|---|---|---|---|---|---|
| <e.g. result, status, entity> | <schema/type, IDs, cardinality> | <function/component> | <database and relation> | <consumer/UI/API/job> | `<repo-relative-path>:line` |

List every database, cache, queue, file store, or external service that is a material source of truth or observable output. If the code only establishes a write but not its schema or reader, mark that row **incomplete**. Inspect three representative authorized persisted records only when the research makes a data-shape or data-quality claim; otherwise state that the matrix is static-source evidence.

### 6. Map process neighborhood and impact
Find processes immediately before, alongside, and after the target: upstream producers, sibling workflows sharing domain objects or state, and downstream jobs/readers. Trace their relationship through shared data, events, queues, state transitions, or explicit calls. Then establish customer and operational impact from evidence: which UI/API states expose success/failure, what stale/missing data users receive, whether a retry/recovery path exists, and what capability is blocked or degraded. Do not label a workflow “core,” “primary,” or “critical” based on intuition; explain the strongest source-supported impact instead.

### 7. Trace meaningful alternatives
Trace only branches material to the requested workflow: validation failures, retries, fallback providers, empty/no-op outcomes, asynchronous handoffs, authorization gates, and terminal errors.

### 8. Establish runtime context
Inspect configuration, feature flags, environment coupling, dependency injection, observability, and tests. Distinguish static reachability from behavior that requires a running service or unavailable infrastructure.

### 9. Verify and synthesize
Re-open the sources supporting the final path. Reject or qualify a claim when its citation does not actually support it. Merge duplicate findings into a coherent explanation rather than repeating file summaries.

## Parallel work is optional

Use the strongest available read-only capability. The skill must succeed with a single investigator.

If reliable isolated workers are available, they may investigate independent discovery angles in parallel. Do not require a specific worker type, tool, command, or orchestration API.

- Default to sequential investigation.
- Use at most 2–3 concurrent workers unless the environment exposes a lower safe limit.
- For deep requests, use available workers first for bounded **coverage discovery**, not independent summaries of the same shared path. Useful partitions are: (1) reverse call graph, routes, queues, events, and all initiators; (2) domain types, persistence schemas, writes, and downstream readers; (3) UI/product context, state visibility, sibling workflows, and downstream jobs.
- Give each worker one bounded question and require the relevant Initiator, Data lifecycle, or Process neighborhood matrix with repository-relative `path:line` evidence.
- Treat worker output as leads, not final evidence; the primary investigator deduplicates candidates, resolves coverage status, follows the critical links, and verifies report citations.
- Do not create a second fan-out to verify every finding.
- If a worker is unavailable, fails, or times out, continue inline and record the unexamined coverage as a gap.

## Required report

```md
# Codebase research: <system or question>
Repository: <root> · Package/workspace: <scope> · Revision: <SHA>
Working tree: <clean | relevant local changes noted> · Date: <ISO-8601>
Initiation coverage: <complete | scoped by user | incomplete> · Scope assumption: <only when needed>

## Direct answer
<3–6 sentences explaining the application capability/user outcome, all included initiation paths, shared coordination, data outputs, adjacent-process handoffs, and the strongest evidenced failure impact. If any coverage gate is incomplete, start by saying what remains unresolved; do not present the result as the complete workflow.>

## Application and customer context
- **Capability and user outcome:** <what the application enables and what a user/system observes on success, with evidence>
- **Operational role:** <source-supported role in the wider application; do not assert “core/critical” without evidence>
- **Failure and recovery impact:** <customer-visible state/API outcome, stale/missing data, recovery/retry path, or `Unknown`, with evidence>

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
1. **Initiators, triggers, and convergence** — <account for each included UI action, API, schedule, event, CLI, hook, or system actor; identify where paths merge, with citations>
2. **Shared coordination and decisions** — <explanation with citations>
3. **Data transformations and state transitions** — <input → transformations → typed/domain output with citations>
4. **Persistence, external boundaries, observability, and terminal effects** — <explanation with citations>
5. **Failure, retry, authorization, and no-op paths** — <only evidenced paths>

## Data lifecycle
| Domain data | Shape/type and identifiers | Created or transformed by | Persisted store/table/collection | Read by / user-visible outcome | Evidence |
|---|---|---|---|---|---|

## Process neighborhood
| Relationship | Process | Shared data/event/state | Ordering and effect on this workflow | Evidence |
|---|---|---|---|---|
| Upstream producer / sibling / downstream consumer | <process> | <boundary> | <before, parallel, after, blocks, enriches, consumes> | `<repo-relative-path>:line` |

Explain which sibling processes are separate branches versus required downstream handoffs; include adjacent extraction/enrichment jobs, consumers, and UI/API readers where applicable.

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

The **Application and customer context**, **Initiator coverage**, **Data lifecycle**, **Process neighborhood**, and **System map** are mandatory for deep workflow/system questions. Use the portable ASCII diagram above as the required format. Mermaid is optional only when the environment renders it. Every node must cite its source directly or have a numbered legend that does. The map must show every included initiation path before it merges into the shared pipeline and every material downstream handoff after it; do not collapse a UI/onboarding path into a generic “operator” label. Mark unsupported links as `Unknown`; do not omit them to make the flow appear complete. 

## Completion check

Before responding, verify:

- [ ] The target repository, revision, and scope are stated.
- [ ] An Initiator coverage matrix accounts for every discovered candidate as included, explicitly excluded by user scope, or unresolved.
- [ ] `Initiation coverage` is `complete` only when no discovered candidate is unresolved; otherwise it is `scoped by user` or `incomplete`, and the Direct answer says so.
- [ ] Every included initiator has an actor/system, trigger mechanism, path to convergence, and repository-relative `path:line` evidence; generic labels do not replace concrete UI/domain flows.
- [ ] The shared path is closed from each included initiator through persisted/output data to terminal consumer or downstream handoff, or every unknown link is explicit.
- [ ] A Data lifecycle matrix identifies material types/schemas, IDs, transformations, stores/tables, and readers; writes without established schema or reader are marked incomplete.
- [ ] A Process neighborhood matrix distinguishes upstream producers, sibling processes, and downstream consumers/handoffs, including their ordering and shared boundaries.
- [ ] Application/customer context explains the source-supported success outcome and failure/recovery impact; unproven product criticality is `Unknown`.
- [ ] The mandatory ASCII diagram, coverage matrices, and walkthrough agree.
- [ ] Initiation, application context, components, data lifecycle, process neighborhood, configuration, observability, tests, and material alternatives are covered or explicitly marked inapplicable/unverified.
- [ ] Every factual claim has valid local evidence; inferences are labeled.
- [ ] The report names evidence gaps and does not replace them with framework assumptions.
- [ ] No file was modified.
