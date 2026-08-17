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
| `codex/agents/` | Codex custom agent definitions with pinned models and read-only sandboxes. |
| `setup.sh` | Bootstrap: symlinks `~/.agents`, runs `sync.sh`. |
| `sync.sh` | Generates Claude instructions and wires shared Claude and Codex symlinks. |
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

### Using Matt's skills with Paseo

Matt's skills define the engineering workflow. Paseo manages agents and workspaces.

```text
idea → grill → spec → tickets → implement → test → review → commit
```

Use them together with these rules:

- Keep `/implement` and `/tdd` in the main or top-level session. They need the context from the earlier planning work.
- Use Paseo agents for read-only research, advice, committees, and reviews. Keep delegation one level deep.
- Use a worktree before implementation. Never commit to `main`.
- `/handoff` writes a context file for a later session. `/paseo-handoff` starts another agent now.
- A heartbeat continues the same agent. A schedule starts a fresh agent.

Common flows:

```text
small change:  /grill-with-docs → /implement
feature:       /grill-with-docs → /to-spec → /to-tickets → /implement
hard decision: /paseo-committee → /to-spec
second opinion: /paseo-advisor
hard bug:      /diagnosing-bugs → /tdd → /code-review
```

Do not run `/implement` inside a Paseo child unless that agent has been detached and is now a top-level session. This avoids nested delegation when `/implement` starts `/code-review`.

### Custom skills

| Skill | Use it for |
| --- | --- |
| `deep-research-codebase` | Codebase archaeology: initiator matrices, data lifecycle, ASCII system maps. |
| `documentation` | Diátaxis framework (tutorials, how-to guides, reference, explanation). |
| `skill-optimizer` | Improving skill activation, clarity, and regression resilience. |
| `writer-persona` | Content in the author's personal voice. |

## Subagents

Claude Code and Codex implement the tool-agnostic delegation principle in
`AGENTS.md` with client-native agent definitions. They keep delegated work off
the main session's context and model tier: the orchestrator dispatches a narrow
task and receives a short report instead of raw tool output.

`claude/agents/` is synced to `~/.claude/agents/`; each file in
`codex/agents/` is linked into `~/.codex/agents/`. Per-file Codex links coexist
with existing personal agents and preserve conflicting user-owned files or
symlinks. Sync does not modify the user's `~/.codex/config.toml`.

| Agent | Claude model and tools | Codex model and sandbox | Use for |
| --- | --- | --- | --- |
| `explorer` | Haiku; Read, Grep, Glob | `gpt-5.6-luna`, low; read-only | Mechanical lookups — "where is X", "does Y exist". No judgment calls. |
| `researcher` | Sonnet; WebFetch, WebSearch, Read, Grep, Glob, Write | `gpt-5.6-terra`, medium; read-only with live web search | Background research against primary sources. Codex returns citations to the parent instead of writing files. |
| `reviewer` | Sonnet; Read, Grep, Glob, Bash (read-only) | `gpt-5.6-terra`, high; read-only | Auditing a diff or codebase region against a standard, spec, or heuristic. Never edits. |

Each client-specific definition pins its model independently of the
orchestrating session. Switching the main session to a stronger model does not
raise the cost tier of delegated lookups, research, or reviews.

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
| Codex | `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` | TOML symlinks in `~/.codex/agents/` | Existing user config is preserved |
| OpenCode | `~/.claude/CLAUDE.md` + `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` | — | — |
| pi | `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` | — | — |

OpenCode also scans `~/.claude/skills/` for backwards compatibility; set `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` to skip it.

### Sync agent configuration

`setup.sh` runs the sync during initial setup. Run it again after:

- editing or pulling changes to `AGENTS.md` or client-specific agent definitions;
- changing generation or linking behavior in `sync.sh`; or
- repairing generated instructions or managed Claude/Codex links.

Run from the repository root:

```bash
bash sync.sh
```

Use `bash sync.sh --dry-run` to preview the changes.

The sync produces this result:

- It generates `~/.claude/CLAUDE.md` from `AGENTS.md`.
- It renames literal `AGENTS.md` references to `CLAUDE.md` in the generated file.
- It links Claude's skills, agents, and settings to their shared files in `~/.agents/`.
- It links Codex's custom agents without modifying `~/.codex/config.toml`.
- It atomically replaces the old managed `CLAUDE.md` symlink.
- It updates only files marked as generated and preserves an unmanaged `CLAUDE.md`.

OpenCode, pi, and Codex read `AGENTS.md` directly. Codex sync only installs its custom agent definitions.

## Updating

```bash
cd ~/Dev/agents && git pull && bash sync.sh
npx skills@latest update --global  # all external skills
```

## Validating

```bash
bash check.sh
```
