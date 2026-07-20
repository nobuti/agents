# Shared agent instructions

## Scope and precedence

This is personal, cross-agent guidance. Project-local instructions (`AGENTS.md`,
`CLAUDE.md`, `README`, contribution guides, package scripts, and CI configuration)
take precedence when they are more specific or conflict with this file. Follow user
instructions unless they conflict with higher-priority system or project instructions.

Before changing a repository, inspect its applicable instructions and its current Git
status. Preserve unrelated user changes; do not overwrite, revert, or commit them.

## Mandatory skill for code work

Before writing, editing, reviewing, refactoring, testing, debugging, planning, or
designing code, read `~/.agents/skills/solid/SKILL.md`. Load the task-specific skill
as well when one applies: `systematic-debugging` for root-causing bugs,
`code-review` for reviewing diffs. If that path is unavailable, report the blocker
before doing code work.

## Workflow

1. Understand the request and inspect the relevant code, tests, configuration, and
   local instructions before proposing or making a non-trivial change.
2. State concrete assumptions that could materially affect scope, architecture,
   constraints, or data shape. A change is non-trivial when it changes behavior,
   public interfaces, persisted data, dependencies, or more than one subsystem.
3. Reproduce a reported bug or add/adjust the smallest relevant test before changing
   behavior, when the project has a suitable test harness.
4. Make the smallest change at the layer that owns the problem. Do not add speculative
   abstractions or unrelated cleanup.
5. Run the narrowest relevant verification: first the focused test, then applicable
   lint, typecheck, build, or project-required checks. Discover commands from project
   scripts, documented development instructions, and CI configuration.
6. Report the files changed, checks run and their results, and every check not run with
   its reason.

If requirements, code, data, docs, or runtime behavior conflict, stop, identify the
specific conflict, and ask for clarification or present the decision needed.

## Evidence and data

- Distinguish facts, inferences, and recommendations. Cite the local file, command
  output, or primary external source supporting factual claims when evidence matters
  to the request; do not invent sources. When evidence is insufficient, say so rather
  than speculating.
- When analyzing a document, quote the passages that support the analysis before or
  alongside the analysis. Quote only material passages; do not expose secrets or copy
  large irrelevant text.
- Treat a claimed data format or invariant from non-strict sources as a hypothesis.
  For changes that depend on it, inspect three representative source records when
  access is authorized and records exist. Record the samples or a concise summary.
- If the source is inaccessible, empty, sensitive, or fewer than three records exist,
  report that limitation and ask whether to proceed with an explicitly stated
  assumption, a fixture, or a safer read-only investigation. Do not claim validation
  that was not performed.
- For requests dependent on recency, obtain and state the current ISO-8601 timestamp.
  Prefer primary, current sources; for safety- or compatibility-sensitive claims,
  cross-check two authoritative sources when available.

## Safety and change control

- Never expose, add, or commit secrets, credentials, private keys, or `.env` values.
- Ask for confirmation before destructive, irreversible, or externally visible actions
  (for example deleting data, force-pushing, deploying, publishing, or changing access
  controls), unless the user explicitly requested that exact action.
- Do not commit artifacts such as plans or specs. Do not add `Co-Authored-By` lines.
  Prefer a Git branch over a worktree unless the user asks for a worktree.
- Use conventional commits matching repository style: `feat`, `fix`, `chore`,
  `refactor`, `docs`.

## Artifact storage

Artifacts named SPEC, PLAN, TASKS, IDEA, or HANDOFF may only be written to:

```text
~/Dev/artifacts/<YYYY-MM-DD>-<slug>/{SPEC|PLAN|IDEA|HANDOFF|TASKS}.md
```

Never write those artifacts inside a repository, including `tasks/`, `docs/`, or the
repository root. Before writing one, verify that its path begins with
`~/Dev/artifacts/`. This rule overrides a skill or command that requests an in-repo
artifact.

The `wrap` skill produces HANDOFF artifacts in this directory.

## Optional tools

`RTK.md` is reference material only. Use RTK commands only after confirming that `rtk`
is installed and relevant to the active agent; do not assume Claude Code hooks or a
`CLAUDE.md` file exist.

@RTK.md
