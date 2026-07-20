---
name: wrap
description: Save a structured session handoff to ~/Dev/artifacts/<date>-<slug>/HANDOFF.md so a fresh agent can continue the work.
argument-hint: "<slug> — short kebab-case name for this handoff"
disable-model-invocation: true
---

When triggered, do the following in order:

## 1. Determine slug and path

If the user passed a slug argument, use it. If not, ask: "What slug for this handoff?" (kebab-case, e.g. `token-monitor-fix`).

Compute the artifact directory:
```
~/Dev/artifacts/$(date +%Y-%m-%d)-<slug>/
```

Create the directory if it doesn't exist. The target file is `HANDOFF.md` inside it.

If a HANDOFF.md already exists at that path, warn the user and ask whether to overwrite or pick a different slug.

## 2. Scan for related artifacts

Before writing, scan `~/Dev/artifacts/` for nearby artifacts matching the slug prefix or date:

```bash
ls ~/Dev/artifacts/<date>-<slug>/ 2>/dev/null
```

Note any existing SPEC.md, PLAN.md, TASKS.md, or IDEA.md files. Reference them by path in the handoff — do not duplicate their content.

## 3. Gather context

Collect:

- **Git state:** current branch, dirty files (`git status --short`), last 3 commits (`git log --oneline -3`)
- **Token usage:** if the agent exposes it (session footer, `/tokens`, status command), record current context tokens; otherwise write `n/a`.
- **Session summary:** what was accomplished, what's in progress, what's blocked
- **Key decisions:** any architectural/design choices made, with rationale
- **Open questions:** things not yet resolved

## 4. Write HANDOFF.md

Use this template. Replace bracketed placeholders. Keep sections concise — this is a handoff, not a novel.

```markdown
# Handoff: <slug>

**Date:** <YYYY-MM-DD>
**Branch:** `<branch-name>`
**Context:** <tokens>/<window> (<pct>% or n/a)

## Goal
[One sentence — what this session tried to accomplish]

## Progress
### Done
- [x] [completed item]
- [x] [completed item]

### In Progress
- [ ] [current work, file paths, current state]

### Blocked
- [blocker] — [reason]

## Key Decisions
- **[Decision]:** [Rationale]

## Open Questions
- [question not yet resolved]

## Git State
- Branch: `<branch>`
- Dirty: [clean] or [list of dirty files]
- Recent commits:
  - `<hash> <message>`
  - `<hash> <message>`
  - `<hash> <message>`

## Artifacts
- SPEC: `<path>` or none
- PLAN: `<path>` or none
- TASKS: `<path>` or none

## Suggested Skills
- `<skill-name>` — why the next agent should load it

## Next Steps
1. [Concrete, actionable step]
2. [Concrete, actionable step]
```

## 5. Redact and validate

- Strip API keys, tokens, passwords. Replace with `<REDACTED>`.
- Verify the file saved to the correct path.
- Print the path so the user can confirm.

## 6. Suggest next action

After saving, tell the user the handoff is ready. Suggest pointing the next agent at the file, e.g. `@~/Dev/artifacts/<date>-<slug>/HANDOFF.md`.
