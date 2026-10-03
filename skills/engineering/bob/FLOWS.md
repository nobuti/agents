# Flows

Principles index behind `/bob`. A **flow** is a path through the skills: one **main flow**, two **on-ramps** merging onto it, everything else standalone or a vocabulary layer. Playbooks in [playbooks/](playbooks/) are the executable form.

## Main flow: idea → ship

1. **`/grill-with-docs`** sharpens the idea by interview and leaves a paper trail in `<root>/GLOSSARY.md` and `<root>/adr/`. No repo? `/grill-me` (stateless). Both run `/grilling`.
2. **Runnable answer needed** (state, business logic, a UI you must see)? Detour: `/handoff` out → `/prototype` → `/handoff` back.
3. **Multi-session build?**
   - Yes → `/to-spec`, then `/to-tickets` (tracer-bullet tickets with blocking edges). Build with `/implement` per ticket (`/clear` between), or `/implement-spec` for the whole spec on one integration branch (parallel implementers over the ready frontier).
   - No → `/implement` in the same window.

   Building drives **`/tdd`** (red-green slices) and closes with **`/code-review`** (Standards + Spec). `/pr` shapes the PR body.
4. **`/retro`** reviews the session and proposes environment changes (checks, standards, pointers), not code. Run it before clearing.

### Context hygiene

Keep steps 1-3 in one unbroken window (no compact/clear before `/to-tickets`). Each `/implement` starts fresh from its ticket. Stay inside the **[smart zone](https://www.aihero.dev/ai-coding-dictionary/smart-zone)** (~150k tokens); near the edge, `/compact` at the nearest phase boundary.

## On-ramps

- **Incoming raw issues** → `/triage`. Never triage `/to-tickets` output.
- **Something broken** → `/diagnosing-bugs` (tight feedback loop first, regression test after). Hands off to `/improve-codebase-architecture` when no seam exists to lock the bug down.
- **Huge foggy effort** → `/wayfinder`: decisions, not deliverables. Hands off at `/to-spec`, never straight to `/implement` unless the effort was small.

## Codebase health

`/improve-codebase-architecture` surfaces deepening opportunities; the chosen one enters the main flow at `/grill-with-docs`. Design it on `/codebase-design`.

## Vocabulary underneath

- **`/domain-modeling`**: domain language, glossary, ADRs.
- **`/codebase-design`**: deep-module vocabulary (module, interface, depth, seam, adapter, leverage, locality).

## Phase boundaries

At the boundary between phases choose: Continue, `/clear`, `/handoff`, subagent, `/compact` (default, bottom of the tree). Read [PHASE-BOUNDARIES.md](PHASE-BOUNDARIES.md) for the ordered tree. Decide at a boundary; mid-phase, continue or split into subagents.

## Standalone

- `/grill-me`: stateless interview, no repo.
- `/grilling`: the interview primitive.
- `/prototype`: throwaway program answering one design question; kept as a primary source on `prototype/<name>`.
- `/research`: background agent reading primary sources into a cited file.
- `/wait-what`: re-pitch a message that didn't land, in plain glossary terms.
- `/writing-for-agents`: writing skills, AGENTS.md, CLAUDE.md.
