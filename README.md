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

| Agent | Instructions | Skills | Settings |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` (generated) | `~/.claude/skills/` (symlink) | `~/.claude/settings.json` (symlink) |
| OpenCode | `~/.claude/CLAUDE.md` + `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` | — |
| pi | `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` | — |

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
- It links Claude's skills and settings to their shared files in `~/.agents/`.
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
