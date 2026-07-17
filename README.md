# agents

Personal skill pack and config shared across AI coding agents. Works with Claude Code, pi, and anything else that reads `~/.agents`.

## What this is

I use multiple AI coding tools and got tired of copying the same skills and instructions between `.claude/`, `.codex/`, and `.cursor/`.

This repo is the single source of truth for **personal** content. Each agent tool gets symlinks to that content. Change something once, it shows up everywhere.

## Setup

Clone and run setup. That is the whole process.

```bash
git clone https://github.com/nobuti/agents.git ~/Dev/agents
bash ~/Dev/agents/setup.sh
```

`setup.sh` does two things:

1. Symlinks `~/.agents` to the repo
2. Runs `sync.sh` to wire up personal symlinks for every agent tool it finds

The script is idempotent. Running it twice does nothing harmful.

## Structure

```
agents/
├── AGENTS.md              # Shared instructions all agents follow
├── RTK.md                 # Personal reference notes
├── setup.sh               # Bootstrap for new machines (idempotent)
├── sync.sh                # Reconcile personal symlinks after changes
├── commands/              # Personal commands (pr, commits)
└── skills/                # Personal skills (tracked in git)
    ├── caveman/
    ├── caveman-help/
    ├── deep-research-codebase/
    ├── dev-workflow/
    ├── documentation/
    ├── explain-before-generate/
    ├── grill-me/
    ├── scope-xray/
    ├── skill-optimizer/
    ├── solid/
    ├── to-prd/
    └── writer-persona/
```

## Managing external skills

External skills are managed directly with the [Vercel Skills CLI](https://github.com/vercel-labs/skills), not by this repository. Discover and install only the skills and agents you need:

```bash
# Discover skills and inspect a source before installing
npx skills find <query>
npx skills add vercel-labs/agent-skills --list

# Install selected skills globally for specific agents
npx skills add vercel-labs/agent-skills --global --agent claude-code --agent codex --agent pi

# Inspect, update, or remove globally installed skills
npx skills list --global
npx skills update --global
npx skills remove --global <skill-name>
```

The CLI uses `~/.agents/skills` as its global canonical skill directory. After this repository is linked there, review `git status` before committing installed external skills. Do not add a vendor registry or a synchronization script here.

## Updating

```bash
# Personal skills and config
cd ~/Dev/agents && git pull && bash sync.sh

# External skills managed by the Vercel Skills CLI
npx skills update --global
```

## How it works

Each agent tool has its own config directory with specific file expectations. Claude Code reads `CLAUDE.md`, `skills/`, and `commands/`. Codex reads `AGENTS.md` and `skills/`. pi reads `AGENTS.md` and `skills/`.

Instead of duplicating files, `sync.sh` creates symlinks from each tool directory back into this repo.

```
~/.agents/                          -> ~/Dev/agents/
.claude/CLAUDE.md                   -> ~/.agents/AGENTS.md
.claude/skills/                     -> ~/.agents/skills/
.claude/commands/                   -> ~/.agents/commands/
.codex/AGENTS.md                    -> ~/.agents/AGENTS.md
.codex/skills/                      -> ~/.agents/skills/
```

External skills are installed and updated by the Vercel Skills CLI. This repository neither configures agent package registries nor synchronizes third-party plugins.

## On a new machine

Same setup command. Works from scratch.

```bash
git clone https://github.com/nobuti/agents.git ~/Dev/agents
bash ~/Dev/agents/setup.sh
```

If `~/.agents` already exists as a real directory, setup will refuse to overwrite it. Move it aside first.

## What the skills cover

- **caveman** - Compressed communication mode. Cuts tokens by skipping filler
- **caveman-help** - Quick reference for caveman commands and variants
- **deep-research-codebase** - Multi-angle, citation-verified research over the current repo (the local-source counterpart of `/deep-research`)
- **dev-workflow** - Personal dev lifecycle reference for phases and commands
- **documentation** - Writing guides and patterns
- **explain-before-generate** - Understand before generating code
- **grill-me** - Stress-test plans through interrogation
- **scope-xray** - Pre-implementation scope forecast: renders a radiographic X-ray of SPEC+TASKS (blast radius, dependency shape, PR-boundary plan) so you cut PRs before coding
- **skill-optimizer** - Improve and benchmark skill packs
- **solid** - SOLID principles and clean code references
- **to-prd** - Writing PRDs and implementation plans
- **writer-persona** - Personal voice and tone rules for writing

Discover additional skills with `npx skills find <query>` and manage them with the Vercel Skills CLI.
