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
| `setup.sh` | Bootstrap: symlinks `~/.agents`, runs `sync.sh`. |
| `sync.sh` | Wires `~/.claude/` symlinks to `~/.agents/`. |
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
   npx skills update --global
   ```

2. **Agent-native plugin managers** (e.g. Claude Code plugins in `~/.claude/settings.json`) — managed outside this repo.

Review `git status` before committing after installing external skills.

## Agent synchronization

| Agent | Instructions | Skills |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` (symlink) | `~/.claude/skills/` (symlink) |
| OpenCode | `~/.claude/CLAUDE.md` + `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` |
| pi | `AGENTS.md` (walk-up) | Auto-loads from `~/.agents/skills/` |

OpenCode also scans `~/.claude/skills/` for backwards compatibility; set `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` to skip it.

## Updating

```bash
cd ~/Dev/agents && git pull && bash sync.sh
npx skills update --global         # external skills
```

## Validating

```bash
bash check.sh
```
