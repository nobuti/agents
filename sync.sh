#!/bin/bash
# Sync shared agent content from ~/.agents/ to Claude Code.
# Idempotent. Safe to run multiple times.
#
# OpenCode and pi already auto-discover ~/.agents/skills/ and
# ~/.agents/AGENTS.md natively -- no sync needed for them.
set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-$HOME/.agents}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

created=0
existed=0
dryruns=0

ensure_symlink() {
    local target="$1" link_path="$2"
    local label="$3"

    if [ -L "$link_path" ]; then
        local current
        current="$(readlink "$link_path")"
        if [ "$current" = "$target" ]; then
            printf "  = %s -> %s\n" "$label" "$current"
            existed=$((existed + 1))
            return
        fi
        if [ ! -e "$link_path" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                printf "  ~ %s -> %s (replace broken)\n" "$label" "$target"
                dryruns=$((dryruns + 1))
            else
                rm "$link_path"
                ln -s "$target" "$link_path"
                printf "  + %s -> %s (replaced broken link)\n" "$label" "$target"
                created=$((created + 1))
            fi
            return
        fi
        printf "  ! %s -> %s (wrong target, expected %s)\n" "$label" "$current" "$target"
        return
    fi

    if [ -e "$link_path" ]; then
        printf "  ! %s exists (not a symlink), skipping\n" "$label"
        return
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        printf "  ~ %s -> %s\n" "$label" "$target"
        dryruns=$((dryruns + 1))
    else
        ln -s "$target" "$link_path"
        printf "  + %s -> %s\n" "$label" "$target"
        created=$((created + 1))
    fi
}

echo "Syncing Claude Code config..."

ensure_symlink "$AGENTS_DIR/AGENTS.md"  "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"
ensure_symlink "$AGENTS_DIR/skills"    "$CLAUDE_DIR/skills"    "skills   "

echo ""
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run: no filesystem changes made."
fi
echo "Done: $created created, $existed unchanged, $dryruns dry-run."
