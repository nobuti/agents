---
name: scope-xray
description: "Pre-implementation scope forecast. Reads SPEC.md + TASKS.md and renders a radiographic X-ray of the work BEFORE any code: blast radius, dependency shape, per-task scope/test-weight forecast, and a PR-boundary plan. Verdict is a human gate — proceed with cuts, or split the spec. Trigger: /scope-xray, 'x-ray the scope', 'is this scope too big', 'check PR boundaries before coding', 'pre-flight scope', 'slice analysis', after TASKS.md and before implementation."
metadata:
  tags: scope, pre-flight, pr-boundaries, slicing, planning, review-load, artifact
---

# Scope X-ray — Pre-flight

Runs in the gap **between `TASKS.md` and the first line of code**. It makes the scope of
planned work legible at a glance so the human can answer two questions before coding:

1. **Is this too big?** → if so, split the SPEC and go back to spec phase.
2. **Where are the PR seams?** → so the work doesn't collapse into one unreviewable PR.

It produces a visual Artifact (a radiographic "X-ray") plus a PR-boundary table. This is a
**decision gate, not automation** — the output is a map; the human judges.

> Why it exists: producing code is cheap; review is the bottleneck. Big PRs disperse knowledge
> and exhaust reviewers. The plan already slices work into tasks — this step turns those tasks
> into PR boundaries *before* the diff exists, when moving a seam is just editing a plan.

---

## Inputs

The feature's `SPEC.md` and `TASKS.md`. Per the artifact convention these live at
`~/Omnia/artifacts/<YYYY-MM-DD>-<slug>/`. Use the dir for the feature in play; if ambiguous,
pick the most recent under `~/Omnia/artifacts/` and confirm the slug with the user.

**Hard stop:** if `TASKS.md` doesn't exist yet, do not invent tasks. Tell the user to run their
planning step first — this skill reads a plan, it doesn't create one.

---

## Step 1 — Extract (from the plan, verbatim)

Pull only what the plan actually states. Do not estimate line counts — they don't exist yet.

Per task: **id**, **name**, **scope band** (S/M/L/XL), **files likely touched**,
**dependencies**, and any **behavior-preserving** note. From `SPEC.md`: whether the rollout is a
**flagless atomic cutover** (grep for "no feature flag", "hard cutover", "cutover").

## Step 2 — Derive

**Domains** — from each file's path, not guesses:

| Path shape | Domain |
|---|---|
| `lib/models/<x>/...` | `<x>` model (e.g. `credit-model`) |
| `app/api/<x>/...` route/handler | `<x>-api` (e.g. `checkout-api`, `webhook-api`) |
| `lib/product-analytics/...`, `*/schemas.ts` (analytics) | `analytics` |
| else | top meaningful path segment |

A task's domains = the set over its files. Matrix intensity per cell:
`core` (new primary logic) · `edit` (modifies existing) · `edge` (small touch) · `del` (deletions).

**Scope band → strip width weight:** S=1 · M=2.5 · L=4.5 · XL=7. Normalize across tasks to %.

**Test-weight forecast** (a forecast from task nature — render it hatched, never as fact):

| Task nature | Forecast | Fill |
|---|---|---|
| service/repository/handler with branches, money path, external API, integration test | high | ~75% |
| pure refactor, data builder, pure-logic extraction | med | ~55% |
| routing/dispatch/wiring, type/schema/config | low–med | ~40% |
| deletions/cleanup only | none | removal hatch |

**Dependency shape:** build the DAG from `dependencies`. Report max parallel width. Each task
depending on the previous = "pure sequential chain · 0 parallel".

## Step 3 — Assign PR strategy (per task)

| Condition | Strategy chip |
|---|---|
| behavior-preserving refactor (no behavior change) | `standalone → main` — **ship first** |
| independent (no deps, single domain, not in the cutover) | `standalone → main` |
| part of a flagless atomic cutover chain | `integration branch` |
| isolatable behind a flag the SPEC permits | `flag-gated → main` |
| tiny dependent cleanup | fold into integration branch / stacked |

Rule of thumb surfaced as a flag, never auto-applied: behavior-preserving refactor **always**
leaves on its own PR, before the feature that motivated it.

## Step 4 — Verdict (the gate)

- **SPLIT THE SPEC** (back to spec phase) if any of: dispersion HIGH (≥half the tasks cross
  >1 domain, or >4 overlapping domains), more than ~8 tasks, or any XL task.
- **PROCEED WITH CUTS** otherwise — state the seam (e.g. "T1 standalone, T2–Tn via integration
  branch").

Count "flags raised": behavior-preserving refactor, oversize task, test-heavy forecast,
cross-domain task. These populate the hero counter.

## Step 5 — Render

1. Copy `template.html` (the radiographic shell — keep the CSS verbatim).
2. Replace each region between `<!-- DATA: x -->` / `<!-- /DATA -->` markers with the derived
   values. The matrix column count and chain length are dynamic — generate those rows/columns
   following the existing pattern, not blind token swap.
3. Write to the scratchpad dir, then publish with the `Artifact` tool: `favicon: "🩻"`,
   a stable label like `pre-flight-v1`. Redeploy the same file path on iteration to keep the URL.
4. In chat, return the Artifact URL **and** the PR-boundary table (task → strategy → why),
   then the verdict line.

## Step 6 — Persist (durable handoff)

The Artifact is hosted and the scratchpad HTML is ephemeral — neither survives the session, and
a later `/wrap` only scans the artifact dir. So also write a local **`SCOPE.md`** next to the
plan, at `~/Omnia/artifacts/<YYYY-MM-DD>-<slug>/SCOPE.md`. This is what makes the verdict and PR
seam durable and auto-referenced by `/wrap`'s artifact scan.

Use this shape — text only, no HTML; it mirrors the X-ray's conclusions, not its visuals:

```markdown
# Scope X-ray — <feature slug>

**Date:** <YYYY-MM-DD>
**Source:** SPEC.md + TASKS.md
**Artifact:** <claude.ai X-ray URL>   _(hosted, may expire — this file is the durable record)_

## Verdict
<PROCEED WITH CUTS | SPLIT THE SPEC> — <one line: the seam, e.g. "T1 standalone → main; T2–T5 via integration branch">

## Forecast
- Tasks: <n> · Files (projected): <n> · Domains: <list>
- Dependency shape: <pure sequential chain | max parallel width n>
- Dispersion: <low | high> — <why>
- Flags raised: <behavior-preserving refactor, oversize task, test-heavy, cross-domain…>

## PR boundary plan
| Task | Name | Scope | Test-weight (forecast) | Strategy | Why |
|------|------|-------|------------------------|----------|-----|
| T1 | … | S | med | standalone → main | behavior-preserving — ship first |
| T2 | … | M | high | integration branch | part of flagless atomic cutover |
| …  | … | … | … | … | … |

## Notes
Magnitudes are forecasts from scope bands, not measured lines. Re-run after implementation if
the shape drifts (new domain, new parallel branch → re-evaluate the verdict).
```

Do not commit `SCOPE.md` to any repo — it lives only under `~/Omnia/artifacts/`, like the rest
of the plan. Print its path in chat alongside the Artifact URL.

## Honesty rules (do not violate)

- Pre-impl has **no measured lines**. Magnitudes come from scope bands and are forecasts.
  Keep the strip hatched and the "projected, not measured" note visible.
- Show only the domains the *plan* lists. Don't add a domain the diff might create later.
- If the plan is too thin to derive a shape (no scope bands, no file lists), say so and ask the
  user to enrich `TASKS.md` rather than fabricating a clean-looking X-ray.

---

## Worked example

`template.html` ships filled with a real case (`auto-topup → stripe invoices`, 5 tasks): a pure
sequential chain, low dispersion, T1 behavior-preserving (→ main first), T2–T5 atomic cutover
(→ integration branch). Use it as the reference for structure and tone, then overwrite its data.
