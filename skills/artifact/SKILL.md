---
name: artifact
description: "Build a self-contained, visual HTML artifact for learning purposes: diagrams, rich layout, interactive explanations. Use for explainers, concept walkthroughs, or a visual repo overview for newcomers (architecture, core pieces, data flow)."
argument-hint: "What should the artifact explain, and for whom?"
---

Build a standalone HTML page that teaches something visually: an architecture overview, a concept explainer, a "how this system works" walkthrough. Optimize for a reader skimming diagrams first and reading prose second, not for a wall of text.

## Where it goes

Save to `~/Dev/artifacts/yyyy-mm-dd-[slug context]/` (create the directory if it doesn't exist yet), where `yyyy-mm-dd` is today's date and `[slug context]` is a short kebab-case slug describing the topic (e.g. `2026-09-16-payments-service-overview/`).

The folder holds everything the page needs:
- `index.html` — the artifact itself
- any local assets it references (images, exported data, extra JS/CSS files) sitting next to it

Keep the page working when opened directly as a local file (`file://`) — no build step, no server. All CSS/JS not loaded from a CDN goes inline or into files in that same folder, referenced with relative paths.

## Before writing anything

Read the `artifact-design` skill first and follow its design guidance (typography, palette, dark-mode tokens, phone-width layout). The *design bar* is the same as a published Artifact, but the *page contract* is not: this file is opened directly as `file://`, with no host wrapping it. So write a complete, standalone HTML document yourself — `<!doctype html>`, `<html>`, `<head>` with charset/viewport/title, and `<body>` — instead of a body-only fragment. Don't rely on artifact-design's "skeleton" section (the auto-injected reset, safe-area padding, CSP) — none of that is present here; port over what you need (the reset, dark-mode tokens, safe-area padding) by hand.

The same gap applies to Mermaid: a published Artifact renders `mermaid` fences natively, but a standalone file does not. Load the Mermaid UMD build from a CDN yourself and call `mermaid.initialize(...)` before any `.mermaid` block is read. Since the page must work in both themes, detect `prefers-color-scheme` in a small inline script and pass matching `themeVariables` (pulled from the same color tokens as the rest of the page) — otherwise diagrams stay light-themed inside a dark page.

If the task is a repo overview: don't guess at the architecture. Invoke the `explain-codebase` skill in deep-trace mode to do the research before drafting a single diagram — a confidently wrong diagram is worse than a plain list.

Use the research, not the report. `explain-codebase` produces a full markdown report (Evidence notes, Open questions, Tests and coverage limits, a completion checklist, etc.) meant to be read as text on its own — none of that ceremony belongs in the artifact. Pull only what feeds a diagram or a pointer:
- **System map** → the one-screen orientation diagram.
- **Component map** → one subsection per Core piece.
- **Workflow walkthrough / Data lifecycle** → the Key flows diagrams.
- The underlying `path:line` citations → the Where-to-start-reading pointers, and the trail every diagram claim must trace back to (see Sanity check below).

Its coverage gates (every initiator included/excluded/unresolved), parallel discovery-angle workers, and evidence-first citations already do what this section used to ask for by hand — splitting research by subsystem and tracing one feature end-to-end with file paths. Just scope the deep-trace request to the system, feature, or flow the artifact needs; let the skill's own investigation method handle the rest.

## Stack

- **Tailwind CDN** for layout, spacing, typography, and responsive structure. Use utility classes directly; don't hand-roll a layout system Tailwind already gives you.
- **Mermaid CDN** for diagrams where the content is genuinely graph-shaped: call graphs, module/dependency graphs, request/sequence flows, state machines, decision trees. If you'd naturally draw it as boxes-and-arrows on a whiteboard, it's a Mermaid candidate.
- **Hand-crafted CSS/SVG** for anything more editorial or spatial: a system's "mass" or footprint, a cross-section or layered view, a before/after or collapse/expand animation, a timeline, a custom icon-driven layout. Also reach for this when Mermaid's layout engine would fight you (e.g. you need precise positioning, nested containers, or a visual metaphor Mermaid can't express).
- Mixing both on one page is expected and good: e.g. a Mermaid sequence diagram for a request lifecycle next to a hand-built layered SVG showing the deployment topology.

Don't force every diagram into Mermaid just because it's available, and don't hand-build an SVG graph that Mermaid would render better and more maintainably.

This is plain HTML, not JSX — a literal `{` or `}` in prose or a code sample (a route param like `{id}`, an object literal like `{entity, kind}`) is written as-is or as `&lbrace;`/`&rbrace;`. Don't write `{'{'}`/`{'}'}` out of JSX habit; it renders as literal garbage text since there's no template compiler here.

## Structure for a repo/system overview

Adapt to what the codebase actually has, but a good default shape:
1. **One-screen orientation** — what this system is, in a sentence, plus a single high-level diagram (Mermaid graph or a hand-built box diagram) showing the major pieces and how they connect.
2. **Core pieces** — one section per major component/module, each with a short explanation and, where useful, a focused diagram (its own dependency slice, its internal flow) rather than repeating the whole system diagram.
3. **Key flows** — a couple of Mermaid sequence/flow diagrams for the paths a newcomer needs to trace first (a request end to end, the build/startup sequence, the main data flow).
4. **Where to start reading** — concrete file/directory pointers so the diagrams connect back to real code, not just abstractions.

Keep prose tight: captions and short paragraphs next to diagrams, not long-form essays. The diagram carries the explanation; the text orients the reader.

## Sanity check before finishing

Actually render the file once before calling it done — don't just re-read the HTML source. A quick recipe that works headlessly: install `playwright-core` into the scratchpad directory (`npm install --no-save playwright-core`) and point it at whatever Chromium is already on the machine (e.g. `chromium.launch({ executablePath: '/snap/bin/chromium' })` — check `which chromium`/`google-chrome` first) rather than downloading a browser. Screenshot the file at a normal desktop width, at phone width (~390px), and once with `colorScheme: 'dark'`. Keep the driver script and screenshots in the scratchpad directory, not in the artifact's own folder.

Look for: diagrams actually rendered (not raw `mermaid` text, no syntax errors), layout holding at phone width, dark mode not breaking contrast, literal `{`/`}` not leaking into the text (see above), and every claim in a diagram tracing back to something actually observed in the code (not inferred or assumed).
