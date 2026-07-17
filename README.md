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
| `skills/` | Personal skills maintained in this repository. |

No personal `commands/` directory is currently tracked. `sync.sh` retains optional
command links for a future `commands/` directory.

## Personal skills

| Skill | Use it for |
| --- | --- |
| `deep-research-codebase` | Cited, read-only investigation of the current repository. |
| `documentation` | Creating, reorganizing, or reviewing technical documentation. |
| `explain-before-generate` | Building understanding before generating code or designs. |
| `grill-me` | Stress-testing a plan or design through a focused interview. |
| `skill-optimizer` | Improving skill activation, clarity, and regression checks. |
| `solid` | Code implementation, review, refactoring, debugging, and design. |
| `wrap` | Creating a handoff for a later agent session. |
| `writer-persona` | Content that should use the author's personal voice. |

## Agent synchronization

`sync.sh` only creates symlinks for agent configuration directories that already
exist:

| Agent | Linked content |
| --- | --- |
| Claude Code | `AGENTS.md` as `CLAUDE.md`, plus `skills/` and optional `commands/`. |
| Codex | `AGENTS.md`, `skills/`, and optional command files. |
| Cursor | Optional command files only. |
| pi | No links are created. This repository does not manage pi extensions. |

## External skills

External skills are managed directly with the [Vercel Skills CLI](https://github.com/vercel-labs/skills). This repository does not maintain a vendor registry, synchronize third-party plugins, or configure agent package registries.

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

The Vercel CLI uses `~/.agents/skills` as its global canonical skill directory. In
this setup, review `git status` before committing after installing or updating
external skills.

## Updating

```bash
# Pull tracked instructions and personal skills
cd ~/Dev/agents && git pull && bash sync.sh

# Update globally installed external skills
npx skills update --global
```

## Optional RTK reference

`RTK.md` is reference material. Use RTK only after confirming that `rtk` is
installed and relevant to the active agent. Do not assume Claude Code hooks are
available.
