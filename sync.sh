#!/bin/bash
# Sync shared agent content from ~/.agents/ to all agent config directories.
# Idempotent. Safe to run multiple times.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

AGENTS_DIR="${AGENTS_DIR:-$HOME/.agents}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_DIR:-$HOME/.codex}"
CURSOR_DIR="${CURSOR_DIR:-$HOME/.cursor}"
AGENTS_MD="$AGENTS_DIR/AGENTS.md"
COMMANDS_DIR="$AGENTS_DIR/commands"
SKILLS_DIR="$AGENTS_DIR/skills"

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

# Counters
CREATED=0; EXISTED=0; CLEANED=0; WARNED=0; DRYRUNS=0; ERRORS=0

log() {
    local tag="$1"; shift
    case "$tag" in
        CREATED)  printf "  \033[32m+\033[0m %s\n" "$*"; CREATED=$((CREATED+1)) ;;
        EXISTS)   printf "  \033[34m=\033[0m %s\n" "$*"; EXISTED=$((EXISTED+1)) ;;
        CLEANED)  printf "  \033[33m-\033[0m %s\n" "$*"; CLEANED=$((CLEANED+1)) ;;
        WARNING)  printf "  \033[31m!\033[0m %s\n" "$*"; WARNED=$((WARNED+1)) ;;
        ERROR)    printf "  \033[31mX\033[0m %s\n" "$*"; ERRORS=$((ERRORS+1)) ;;
        DRYRUN)   printf "  \033[35m~\033[0m %s\n" "$*"; DRYRUNS=$((DRYRUNS+1)) ;;
        *)        printf "  %s\n" "$*" ;;
    esac
}

remove_path() {
    local path="$1" kind="$2"
    if [ "$DRY_RUN" -eq 1 ]; then
        log DRYRUN "$path ($kind)"
        return
    fi
    case "$kind" in
        dir) rm -rf "$path" ;;
        *)   rm -f "$path" ;;
    esac
}

create_symlink() {
    local target="$1" link_path="$2"
    if [ "$DRY_RUN" -eq 1 ]; then
        log DRYRUN "$link_path -> $target"
        return
    fi
    ln -s "$target" "$link_path"
}

ensure_symlink() {
    local target="$1" link_path="$2"

    if [ -L "$link_path" ]; then
        local current_target
        current_target="$(readlink "$link_path")"
        if [ "$current_target" = "$target" ]; then
            log EXISTS "$link_path"
            return
        fi
        if [ ! -e "$link_path" ]; then
            remove_path "$link_path" file
            create_symlink "$target" "$link_path"
            log CREATED "$link_path -> $target (replaced broken link)"
            return
        fi
        log WARNING "$link_path -> $current_target (wrong target, expected $target)"
        return
    fi

    if [ -e "$link_path" ]; then
        log WARNING "$link_path exists (not a symlink), skipping"
        return
    fi

    create_symlink "$target" "$link_path"
    log CREATED "$link_path -> $target"
}

cleanup_glob() {
    local dir="$1" pattern="$2"
    for item in "$dir"/$pattern; do
        [ -e "$item" ] || [ -L "$item" ] || continue
        if [ -d "$item" ] && [ ! -L "$item" ]; then
            remove_path "$item" dir
        else
            remove_path "$item" file
        fi
        log CLEANED "$item"
    done
}

# ── Phase 1: Clean up broken symlinks and backup artifacts ──────────

echo "Phase 1: Clean up broken symlinks and backup artifacts"

if [ -d "$CLAUDE_DIR" ]; then
    echo "  Claude Code:"
    for item in CLAUDE.md commands skills; do
        target="$CLAUDE_DIR/$item"
        if [ -L "$target" ] && [ ! -e "$target" ]; then
            remove_path "$target" file
            log CLEANED "$target (broken symlink)"
        fi
    done
    cleanup_glob "$CLAUDE_DIR" "CLAUDE.md.backup.*"
    cleanup_glob "$CLAUDE_DIR" "commands.backup.*"
    cleanup_glob "$CLAUDE_DIR" "skills.backup.*"
    cleanup_glob "$CLAUDE_DIR" "settings.json.backup.*"
fi

if [ -d "$CODEX_DIR" ]; then
    echo "  Codex:"
    for item in AGENTS.md skills; do
        target="$CODEX_DIR/$item"
        if [ -L "$target" ] && [ ! -e "$target" ]; then
            remove_path "$target" file
            log CLEANED "$target (broken symlink)"
        fi
    done
    cleanup_glob "$CODEX_DIR" "AGENTS.md.backup.*"
    cleanup_glob "$CODEX_DIR" "skills.backup.*"
    cleanup_glob "$CODEX_DIR" "config.toml.backup.*"
fi

echo ""

# ── Phase 2: Create symlinks ────────────────────────────────────────

echo "Phase 2: Create symlinks"

# Claude Code
if [ -d "$CLAUDE_DIR" ]; then
    echo "  Claude Code:"
    ensure_symlink "$AGENTS_MD" "$CLAUDE_DIR/CLAUDE.md"
    ensure_symlink "$COMMANDS_DIR" "$CLAUDE_DIR/commands"
    ensure_symlink "$SKILLS_DIR" "$CLAUDE_DIR/skills"
fi

# Codex
if [ -d "$CODEX_DIR" ]; then
    echo "  Codex:"
    ensure_symlink "$AGENTS_MD" "$CODEX_DIR/AGENTS.md"
    ensure_symlink "$SKILLS_DIR" "$CODEX_DIR/skills"
    if [ -d "$CODEX_DIR/command" ]; then
        cmd_path=""; cmd_name=""
        for cmd_path in "$COMMANDS_DIR"/*.md; do
            [ -e "$cmd_path" ] || continue
            cmd_name="$(basename "$cmd_path")"
            ensure_symlink "$cmd_path" "$CODEX_DIR/command/$cmd_name"
        done
    fi
fi

# Cursor
if [ -d "$CURSOR_DIR" ]; then
    echo "  Cursor:"
    if [ -d "$CURSOR_DIR/commands" ]; then
        cmd_path=""; cmd_name=""
        for cmd_path in "$COMMANDS_DIR"/*.md; do
            [ -e "$cmd_path" ] || continue
            cmd_name="$(basename "$cmd_path")"
            ensure_symlink "$cmd_path" "$CURSOR_DIR/commands/$cmd_name"
        done
    fi
fi

echo ""

# ── Summary ─────────────────────────────────────────────────────────

if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run: no filesystem changes made."
fi

echo "Done: $CREATED created, $EXISTED unchanged, $CLEANED cleaned, $WARNED warnings, $DRYRUNS dry-run actions, $ERRORS errors"
[ "$ERRORS" -eq 0 ]
