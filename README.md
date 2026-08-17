# agents

Shared AI coding agent instructions and skills. `~/.agents` is a symlink to this repo.

## Setup

```bash
git clone https://github.com/nobuti/agents.git ~/Dev/agents
bash ~/Dev/agents/setup.sh
```

## Tracked content

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Shared operating instructions and skill pipeline. |
| `RTK.md` | Optional RTK reference notes. |
| `claude/settings.json` | Claude Code global settings (permissions, hooks, statusLine, theme). |
| `claude/agents/` | Claude Code subagent definitions (explorer, researcher, reviewer). |
| `setup.sh` | Bootstrap: symlinks `~/.agents`, runs `sync.sh`. |
| `sync.sh` | Generates Claude instructions and wires shared Claude symlinks. |
| `check.sh` | Validates skill frontmatter, links, and script syntax. |
| `skills/` | Custom skills in this repo. |
| `.skill-lock.json` | Vercel Skills CLI lock file. |

## Skills

### Pipeline (Matt Pocock)

Engineering workflow skills installed via Vercel Skills CLI:

```bash
npx skills@latest add mattpocock/skills
```

Core pipeline: `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/implement` (which drives `/tdd` at seams, closes with `/code-review`). See `AGENTS.md` for the full pipeline reference.

### Custom skills

| Skill | Use it for |
| --- | --- |
| `deep-research-codebase` | Codebase archaeology: initiator matrices, data lifecycle, ASCII system maps. |
| `documentation` | Diátaxis framework (tutorials, how-to guides, reference, explanation). |
| `skill-optimizer` | Improving skill activation, clarity, and regression resilience. |
| `writer-persona` | Content in the author's personal voice. |

## Subagents

This is the Claude Code-specific implementation of the tool-agnostic
delegation principle in `AGENTS.md` — OpenCode, pi, and Codex each have
their own delegation mechanism and aren't covered here.

`claude/agents/` holds Claude Code subagent definitions, synced to
`~/.claude/agents/`. They exist to keep delegated work off the main
session's context and off its model tier — the orchestrator (the session
you're talking to) dispatches them, reads back a short report, and never
sees their raw tool output.

| Agent | Model | Tools | Use for |
| --- | --- | --- | --- |
| `explorer` | Haiku | Read, Grep, Glob | Mechanical lookups — "where is X", "does Y exist". No judgment calls. |
| `researcher` | Sonnet | WebFetch, WebSearch, Read, Grep, Glob, Write | Background research against primary sources, written up as a cited report. |
| `reviewer` | Sonnet | Read, Grep, Glob, Bash (read-only) | Auditing a diff or codebase region against a standard, spec, or heuristic. Never edits. |

Each agent pins its own model in its frontmatter, independent of whatever
model the orchestrating session is running. Switching the session to Opus
does not raise the cost of delegated lookups or reviews — only the
orchestrator's own reasoning gets more expensive.

Mapped to the installed skill pipeline: `explorer` backs `grilling`'s
fact-finding dispatch and `deep-research-codebase`'s parallel investigator
partitions; `researcher` backs `/research` and `wayfinder`'s research
tickets; `reviewer` backs `code-review`'s Standards/Spec axes and
`improve-codebase-architecture`'s codebase walk. `/implement` and `/tdd`
intentionally delegate to none of these — they run inline, because writing
code correctly depends on context accumulated earlier in the session
(grilling answers, the agreed spec) that a fresh subagent wouldn't have.

### When to reach for Opus instead of the default

The subagents above absorb the mechanical and read-only work at a fixed,
cheap tier. What's left for the orchestrating session is judgment: deciding
what to delegate, weighing conflicting subagent reports, and planning. That
remaining work is where Opus earns its cost premium — and only there.

**Switch the session to Opus (`/model opus`) before starting:**

- a `grilling` / `grill-with-docs` session with many branching decisions,
  especially ones that are expensive to redo if misjudged;
- reviewing or approving a large plan or ticket breakdown before
  implementation starts — this is the cheapest point in the pipeline to
  catch a mistake, so it's worth paying for the strongest judgment;
- `codebase-design`'s DESIGN-IT-TWICE, where comparing radically different
  interface designs on depth and seam placement is the entire point;
- diagnosing a hard, non-obvious bug (`diagnosing-bugs`) where the quality
  of the hypothesis matters more than the speed of forming one.

**Switch back to the default (Sonnet) once you move into:**

- `/implement` or `/tdd` loops — mechanical, well-specified, high-volume;
- routine fixes, quick lookups, or anything a subagent could handle instead.

Model choice is a per-session setting, not per-message — set it once at the
start of a judgment-heavy phase and switch back when that phase ends, rather
than leaving Opus on as the default driver for the whole workflow.

## External skills

External skills install into `skills/` (this repo). Two sources:

1. **Vercel Skills CLI** (recommended) — installs from GitHub repos into `skills/`, tracked via `.skill-lock.json`:
   ```bash
   npx skills@latest add mattpocock/skills
   npx skills list --global
   npx skills@latest update --global
   ```

   To update the installed skills, run:
   ```bash
   # Update all installed skills.
   npx skills@latest update --global

   # Update one installed skill by its skill name.
   npx skills@latest update tdd --global
   ```
   `mattpocock/skills` is a source repository, not an installed skill name. Do
   not pass it to `update`.

2. **Agent-native plugin managers** (e.g. Claude Code plugins) — managed outside this repo.

Review `git status` before committing after installing external skills.

## Agent synchronization

| Agent | Instructions | Skills | Subagents | Settings |
| --- | --- | --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` (generated) | `~/.claude/skills/` (symlink) | `~/.claude/agents/` (symlink) | `~/.claude/settings.json` (symlink) |
| OpenCode | `~/.claude/CLAUDE.md` + `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` | — | — |
| pi | `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` | — | — |

OpenCode also scans `~/.claude/skills/` for backwards compatibility; set `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` to skip it.

### Sync Claude Code

`setup.sh` runs the sync during initial setup. Run it again after:

- editing or pulling changes to `AGENTS.md`;
- changing the Claude generation behavior in `sync.sh`; or
- repairing the generated instructions or managed Claude links.

Run from the repository root:

```bash
bash sync.sh
```

Use `bash sync.sh --dry-run` to preview the changes.

The sync produces this result:

- It generates `~/.claude/CLAUDE.md` from `AGENTS.md`.
- It renames literal `AGENTS.md` references to `CLAUDE.md` in the generated file.
- It links Claude's skills, agents, and settings to their shared files in `~/.agents/`.
- It atomically replaces the old managed `CLAUDE.md` symlink.
- It updates only files marked as generated and preserves an unmanaged `CLAUDE.md`.

OpenCode and pi read `AGENTS.md` directly, so they do not need this sync.

## Updating

```bash
cd ~/Dev/agents && git pull && bash sync.sh
npx skills@latest update --global  # all external skills
```

## Validating

```bash
bash check.sh
```
