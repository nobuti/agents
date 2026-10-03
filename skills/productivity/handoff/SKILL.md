---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it to the folder the user specified or `~/Dev/artifacts` otherwise (create the directory if it doesn't exist yet) - not the current workspace.

Name the file `yyyy-mm-dd-[slug context].md`, where `yyyy-mm-dd` is today's date and `[slug context]` is a short, kebab-case slug describing the conversation's topic (e.g. `2026-09-16-auth-migration-handoff.md`).

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
