---
name: prompt-refine
description: Sharpen a prompt for delegating to Claude Code or an agent — build one from scratch or critique a draft against a context checklist.
disable-model-invocation: true
---

Route based on what's provided:

- No input, or a short phrase describing an idea → **interview branch**.
- A pasted multi-line instruction block that reads like a finished prompt → **critique branch**.
- Ambiguous → ask once: "Is this a finished draft to critique, or a starting idea to build from?" Then route on the answer.

## Checklist

Every prompt for agent delegation needs:

1. **Objective** — the outcome, stated as a result ("tests pass for X"), not a task ("fix X")
2. **Scope boundary** — what files/systems are in play, what's explicitly out of bounds
3. **Constraints** — must-preserve behavior, style rules, things not to touch
4. **Success criteria** — how completion will be recognized, checkable
5. **Prior context** — decisions already made, things already tried or ruled out
6. **Negative space** — known wrong turns to avoid
7. **Output form** — code change vs. explanation vs. plan vs. options

## Interview branch

Run a `/grilling` session using the checklist above as the decision tree — walk each item one at a time, give a recommended answer, wait for confirmation before moving to the next.

Once `grilling` reaches shared understanding, assemble the finished prompt from the answers gathered, addressing every checklist item. Present it as the deliverable.

## Critique branch

Score the draft against each checklist item: met, weak, or missing. Report the gaps, then produce a rewritten version that fills them in — keep the user's intent and voice, don't invent scope they didn't ask for.

## Both branches end here

Show the finished prompt. Offer to save it as a plain `.md` file (prompt text only) at a filename/path the user specifies. Don't save without asking, and never commit it.
