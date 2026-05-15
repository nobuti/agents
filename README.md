# agents

Personal skill pack and config shared across AI coding agents. Works with Claude Code, Codex, Opencode, Cursor, and anything else that reads `~/.agents`.

## What this is

I use multiple AI coding tools and got tired of copying the same skills and instructions between `.claude/`, `.codex/`, `.opencode/`, and `.cursor/`.

This repo is the single source of truth. Everything lives here. Each agent tool gets a symlink. Change something once, it shows up everywhere.

## Setup

Clone and run setup. That is the whole process.

```bash
git clone https://github.com/nobuti/agents.git ~/Dev/agents
bash ~/Dev/agents/setup.sh
```

`setup.sh` does three things:

1. Symlinks `~/.agents` to the repo
2. Clones vendor repos listed in `vendors.conf`
3. Runs `sync.sh` to wire up symlinks for every agent tool it finds

The script is idempotent. Running it twice does nothing harmful.

## Structure

```
agents/
├── AGENTS.md              # Shared instructions all agents follow
├── RTK.md                 # Personal reference notes
├── setup.sh               # Bootstrap for new machines (idempotent)
├── sync.sh                # Reconcile symlinks after changes
├── vendor-update.sh       # Pull latest from upstream vendor repos
├── vendors.conf           # Vendor registry (single source of truth)
├── commands/              # Shared commands (pr, commits)
├── skills/                # Personal skills (tracked in git)
│   ├── caveman/
│   ├── dev-workflow/
│   ├── documentation/
│   ├── explain-before-generate/
│   ├── grill-me/
│   ├── skill-optimizer/
│   ├── solid/
│   └── writer-persona/
└── vendor/                # Third-party repos (cloned, not tracked)
    └── addyosmani-agent-skills/
```

## Managing vendors

All vendor repos are declared in one file: `vendors.conf`.

```
# owner/repo:skillsSubdir
addyosmani/agent-skills:skills
```

Format is `owner/repo:skillsSubdir`. The repo gets cloned into `vendor/` and each directory inside `skillsSubdir/` is symlinked into `skills/`.

To add a vendor, add one line to `vendors.conf` and run setup.

```bash
echo "owner/repo:skills" >> vendors.conf
bash setup.sh
```

To remove one, delete the line from `vendors.conf`, remove the symlink from `skills/`, and delete the repo directory from `vendor/`.

## Updating

Pull vendor changes, then reconcile symlinks.

```bash
bash vendor-update.sh
bash sync.sh
```

`vendor-update.sh` pulls each vendor repo with `--ff-only`. `sync.sh` creates any new symlinks that appeared from upstream updates. Both scripts are safe to run multiple times.

## How it works

Each agent tool has its own config directory with specific file expectations. Claude Code reads `CLAUDE.md` and `skills/`. Codex reads `AGENTS.md` and `skills/`. Opencode reads `AGENTS.md`. Cursor reads `commands/`.

Instead of duplicating files, `sync.sh` creates symlinks from each tool directory back into this repo. The `commands/` directory is shared across all of them. The skills directory is shared too, with vendor skills symlinked in.

```
~/.agents/          -> ~/Dev/agents/
.claude/CLAUDE.md   -> ~/.agents/AGENTS.md
.claude/skills/     -> ~/.agents/skills/
.claude/commands/   -> ~/.agents/commands/
.codex/AGENTS.md    -> ~/.agents/AGENTS.md
.codex/skills/      -> ~/.agents/skills/
.opencode/AGENTS.md -> ~/.agents/AGENTS.md
.cursor/commands/   -> ~/.agents/commands/pr.md (etc)
```

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
- **dev-workflow** - Personal dev lifecycle reference for phases and commands
- **documentation** - Writing guides and patterns
- **explain-before-generate** - Understand before generating code
- **grill-me** - Stress-test plans through interrogation
- **skill-optimizer** - Improve and benchmark skill packs
- **solid** - SOLID principles and clean code references
- **writer-persona** - Personal voice and tone rules for writing

Vendor skills cover the rest: API design, testing, CI/CD, code review, security, performance, planning, spec-driven development, and more.
