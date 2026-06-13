# agents

Personal skill pack and config shared across AI coding agents. Works with Claude Code, pi, and anything else that reads `~/.agents`.

## What this is

I use multiple AI coding tools and got tired of copying the same skills and instructions between `.claude/`, `.codex/`, and `.cursor/`.

This repo is the single source of truth for **personal** content. Vendor skills and commands are managed through each agent's native package/plugin system. Each agent tool gets symlinks to the personal content. Change something once, it shows up everywhere.

## Setup

Clone and run setup. That is the whole process.

```bash
git clone https://github.com/nobuti/agents.git ~/Dev/agents
bash ~/Dev/agents/setup.sh
```

`setup.sh` does three things:

1. Symlinks `~/.agents` to the repo
2. Runs `sync.sh` to wire up personal symlinks for every agent tool it finds
3. Runs `vendor-sync.sh` to reconcile vendor plugins/packages with each agent's native system

The script is idempotent. Running it twice does nothing harmful.

## Structure

```
agents/
├── AGENTS.md              # Shared instructions all agents follow
├── RTK.md                 # Personal reference notes
├── setup.sh               # Bootstrap for new machines (idempotent)
├── sync.sh                # Reconcile personal symlinks after changes
├── vendor-sync.sh         # Reconcile vendor plugins/packages per agent
├── vendors.conf           # Vendor registry (single source of truth)
├── commands/              # Personal commands (pr, commits)
└── skills/                # Personal skills (tracked in git)
    ├── caveman/
    ├── caveman-help/
    ├── deep-research-codebase/
    ├── dev-workflow/
    ├── documentation/
    ├── explain-before-generate/
    ├── grill-me/
    ├── skill-optimizer/
    ├── solid/
    ├── to-prd/
    └── writer-persona/
```

## Managing vendors

All vendor packages are declared in one file: `vendors.conf`.

```
# vendor_id:agents:install_spec
addyosmani/agent-skills:pi:git:github.com/addyosmani/agent-skills
addyosmani/agent-skills:claude:plugin:agent-skills@addy-agent-skills
```

Format is `vendor_id:agents:install_spec`. Each line declares one vendor for one or more agents. The install spec is agent-native — `git:...` for pi, `plugin:...` for Claude.

`vendor-sync.sh` is idempotent and safe to run multiple times.

- **pi**: Writes desired packages to `~/.pi/agent/settings.json`. pi auto-installs missing packages on startup.
- **Claude Code**: Reads `~/.claude/plugins/installed_plugins.json` and reports status. Prints exact `/plugin install ...` and `/plugin remove ...` commands for any drift.

To add a vendor, add lines to `vendors.conf` and run `vendor-sync.sh`.

To remove one, delete the lines and run `vendor-sync.sh`.

To preview changes without mutating anything:

```bash
bash vendor-sync.sh   # safe; pi settings are idempotent writes
```

## Updating

```bash
# Personal skills and config
cd ~/Dev/agents && git pull && bash sync.sh

# Vendor plugins/packages
bash vendor-sync.sh
```

For pi vendors, `pi update --extensions` also works after `vendor-sync.sh` has written the package to settings.

For Claude vendors, run `/plugin update <name>` inside a claude session.

## How it works

Each agent tool has its own config directory with specific file expectations. Claude Code reads `CLAUDE.md`, `skills/`, and `commands/`. Codex reads `AGENTS.md` and `skills/`. pi reads `AGENTS.md` and `skills/`.

Instead of duplicating files, `sync.sh` creates symlinks from each tool directory back into this repo.

```
~/.agents/          -> ~/Dev/agents/
.claude/CLAUDE.md   -> ~/.agents/AGENTS.md
.claude/skills/     -> ~/.agents/skills/
.claude/commands/   -> ~/.agents/commands/
.codex/AGENTS.md    -> ~/.agents/AGENTS.md
.codex/skills/      -> ~/.agents/skills/
```

Vendor content lives in agent-native directories (pi packages in `~/.pi/agent/git/`, Claude plugins in `~/.claude/plugins/cache/`), not in this repo.

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
- **skill-optimizer** - Improve and benchmark skill packs
- **solid** - SOLID principles and clean code references
- **to-prd** - Writing PRDs and implementation plans
- **writer-persona** - Personal voice and tone rules for writing

Vendor skills (API design, testing, CI/CD, code review, security, performance, planning, spec-driven development, and more) are installed through `vendor-sync.sh` into each agent's native package/plugin system.
