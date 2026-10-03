#!/usr/bin/env bash
# Set up this repo on a machine. Safe to re-run.
#   1. Expose every skills/**/SKILL.md as a flat skills/<name> symlink so Claude Code discovers it.
#   2. Link each of those into ~/.claude/skills/<name>.
#   3. Link CLAUDE.md into ~/.claude/CLAUDE.md.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
root="$repo/skills"
cd "$root"

# drop previous links (only symlinks), then recreate
find . -maxdepth 1 -type l -delete
: > .gitignore

find . -mindepth 3 -name SKILL.md -not -path './synced/*' -print0 | sort -z |
while IFS= read -r -d '' f; do
  dir="$(dirname "$f")"; name="$(basename "$dir")"
  if [ -e "$name" ] || [ -L "$name" ]; then
    echo "skip $dir: '$name' already exists" >&2; continue
  fi
  ln -s "${dir#./}" "$name"
  echo "/$name" >> .gitignore
done

# link each skill into ~/.claude/skills; drop stale links that point into this repo, never touch anything else
dest="$HOME/.claude/skills"
mkdir -p "$dest"
for l in "$dest"/*; do
  [ -L "$l" ] || continue
  case "$(readlink "$l")" in "$root"/*) [ -e "$l" ] || rm "$l" ;; esac
done
for l in "$root"/*; do
  [ -L "$l" ] || continue
  name="$(basename "$l")"
  if [ -L "$dest/$name" ] && [ "$(readlink "$dest/$name")" = "$root/$name" ]; then
    continue
  elif [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
    echo "skip $dest/$name: already exists" >&2
  else
    ln -s "$root/$name" "$dest/$name"
    echo "+ $dest/$name"
  fi
done

# link CLAUDE.md; never overwrite a real file
target="$HOME/.claude/CLAUDE.md"
mkdir -p "$HOME/.claude"
if [ -L "$target" ] && [ "$(readlink "$target")" = "$repo/CLAUDE.md" ]; then
  echo "= $target already linked"
elif [ -e "$target" ] && [ ! -L "$target" ]; then
  echo "! $target exists and is not a symlink; move it aside and re-run" >&2
  exit 1
else
  ln -sfn "$repo/CLAUDE.md" "$target"
  echo "+ $target -> $repo/CLAUDE.md"
fi
