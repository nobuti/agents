# agents

Personal instructions and skills shared by AI coding agents. This repository is the
source of truth for the tracked content linked from `~/.agents`.

## Setup

```bash
git clone https://github.com/nobuti/agents.git ~/Dev/agents
bash ~/Dev/agents/setup.sh
```

`setup.sh` links `~/.agents` to this repository, creates `~/Dev/artifacts/` for
handoff documents, then runs `sync.sh` to wire up Claude Code. It stops if
`~/.agents` is a real directory, so move that directory aside before setup.

## Tracked content

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Shared operating instructions. |
| `RTK.md` | Optional RTK reference notes. |
| `setup.sh` | Bootstrap script: symlinks `~/.agents` and runs `sync.sh`. |
| `sync.sh` | Ensures `~/.claude/` symlinks point to `~/.agents/` content. |
| `check.sh` | Validates skill frontmatter, links, and script syntax. |
| `skills/` | Personal skills maintained in this repository. |

## Personal skills

| Skill | Use it for |
| --- | --- |
| `code-review` | Reviewing diffs, PRs, or uncommitted changes for correctness and fit. |
| `deep-research-codebase` | Investigating how a system works: compact concept maps for learning, or deep traces with full citation-backed reports. |
| `documentation` | Creating, reorganizing, or reviewing technical documentation. |
| `grill-me` | Stress-testing a plan or design through a focused interview. |
| `skill-optimizer` | Improving skill activation, clarity, and regression checks. |
| `solid` | Code implementation, review, refactoring, debugging, and design. |
| `systematic-debugging` | Root-causing bugs through evidence, not guessing. |
| `wrap` | Creating a handoff for a later agent session. |
| `writer-persona` | Content that should use the author's personal voice. |

## Agent synchronization

`sync.sh` creates symlinks from `~/.claude/` to `~/.agents/`. Claude Code is the only
agent that needs this — it reads `~/.claude/` rather than `~/.agents/`.

OpenCode and pi auto-discover `~/.agents/` natively, so no additional wiring is
needed for them. OpenCode also scans `~/.claude/skills/` for backwards compatibility;
if you want to avoid that redundant scan, set `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1`.

| Agent | Instructions | Skills |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` (via symlink) | `~/.claude/skills/` (via symlink) |
| OpenCode | `~/.claude/CLAUDE.md` + `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` |
| pi | `AGENTS.md` (walk-up from CWD) | Auto-loads from `~/.agents/skills/` |

## External skills

External skills arrive through two channels:

1. **Agent-native plugin managers** (e.g. Claude Code plugins configured in
   `~/.claude/settings.json`) — managed outside this repository.
2. **Vercel Skills CLI** — optional; installs into `~/.agents/skills` (which lives in
   this repo). Review `git status` before committing after installing external skills
   this way.

```bash
# Find skills and inspect the Vercel catalog
npx skills find <query>
npx skills add vercel-labs/agent-skills --list

# Install selected skills globally
npx skills add vercel-labs/agent-skills --global --agent claude-code --agent pi

# Inspect, update, or remove globally installed skills
npx skills list --global
npx skills update --global
npx skills remove --global <skill-name>
```

## Updating

```bash
# Pull tracked instructions and personal skills
cd ~/Dev/agents && git pull && bash sync.sh

# Update globally installed external skills
npx skills update --global
```

## Validating

```bash
bash check.sh
# Checks: skill frontmatter names match directory names, internal markdown
# links resolve, and shell scripts pass syntax validation (and lint, when
# shellcheck is available).
```

## Optional RTK reference

`RTK.md` is reference material. Use RTK only after confirming that `rtk` is
installed and relevant to the active agent. Do not assume Claude Code hooks are
available.
