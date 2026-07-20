# agents

Personal instructions and skills shared by AI coding agents. This repository is the
source of truth for the tracked content linked from `~/.agents`.

## Setup

```bash
git clone https://github.com/nobuti/agents.git ~/Dev/agents
bash ~/Dev/agents/setup.sh
```

`setup.sh` links `~/.agents` to this repository, then runs `sync.sh`. It stops if
`~/.agents` is a real directory, so move that directory aside before setup.

## Tracked content

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Shared operating instructions. |
| `RTK.md` | Optional RTK reference notes. |
| `setup.sh` | Bootstrap script for `~/.agents`. |
| `sync.sh` | Reconciles supported agent symlinks. |
| `check.sh` | Validates skill frontmatter, links, and script syntax. |
| `skills/` | Personal skills maintained in this repository. |

No personal `commands/` directory is currently tracked. `sync.sh` creates command
symlinks only when `~/.agents/commands` exists on disk.

## Personal skills

| Skill | Use it for |
| --- | --- |
| `code-review` | Reviewing diffs, PRs, or uncommitted changes for correctness and fit. |
| `deep-research-codebase` | Cited, read-only investigation of the current repository. |
| `documentation` | Creating, reorganizing, or reviewing technical documentation. |
| `explain-before-generate` | Building understanding before generating code or designs. |
| `grill-me` | Stress-testing a plan or design through a focused interview. |
| `skill-optimizer` | Improving skill activation, clarity, and regression checks. |
| `solid` | Code implementation, review, refactoring, debugging, and design. |
| `systematic-debugging` | Root-causing bugs through evidence, not guessing. |
| `wrap` | Creating a handoff for a later agent session. |
| `writer-persona` | Content that should use the author's personal voice. |

## Agent synchronization

`sync.sh` only creates symlinks for agent configuration directories that already
exist:

| Agent | Linked content |
| --- | --- |
| Claude Code | `AGENTS.md` as `CLAUDE.md`, plus `skills/` and optional `commands/`. |
| Codex | `AGENTS.md`, `skills/`, and optional prompt files (`~/.codex/prompts`). |
| Cursor | Optional command files only. |
| OpenCode | Reads `~/.claude/CLAUDE.md` and `~/.claude/skills` through Claude-compatible discovery. No direct links managed by this repo. |
| pi | No links are created. This repository does not manage pi extensions. |

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

# Install selected skills globally for specific agents
npx skills add vercel-labs/agent-skills --global --agent claude-code --agent codex --agent pi

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
