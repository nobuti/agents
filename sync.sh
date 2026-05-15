#!/bin/bash
# Sync shared agent content from ~/.agents/ to all agent config directories.
# Idempotent. Safe to run multiple times.
set -euo pipefail

AGENTS_DIR="$HOME/.agents"
CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="$HOME/.codex"
OPENCODE_DIR="$HOME/.opencode"
CURSOR_DIR="$HOME/.cursor"

AGENTS_MD="$AGENTS_DIR/AGENTS.md"
COMMANDS_DIR="$AGENTS_DIR/commands"
SKILLS_DIR="$AGENTS_DIR/skills"
VENDOR_DIR="$AGENTS_DIR/vendor"

SHARED_COMMANDS=(pr.md commits.md)

# Vendor skill repos: "<owner>/<repo>:<skills-subdir>"
# Each <repo>'s <skills-subdir>/<name>/ is symlinked into $SKILLS_DIR/<name>.
# Updates are NOT performed here — run vendor-update.sh.
VENDOR_SKILLS=(
    "addyosmani/agent-skills:skills"
)

# Counters
CREATED=0; EXISTED=0; CLEANED=0; RESTORED=0; WARNED=0

log() {
    local tag="$1"; shift
    case "$tag" in
        CREATED)  printf "  \033[32m+\033[0m %s\n" "$*"; CREATED=$((CREATED+1)) ;;
        EXISTS)   printf "  \033[34m=\033[0m %s\n" "$*"; EXISTED=$((EXISTED+1)) ;;
        CLEANED)  printf "  \033[33m-\033[0m %s\n" "$*"; CLEANED=$((CLEANED+1)) ;;
        RESTORED) printf "  \033[36mR\033[0m %s\n" "$*"; RESTORED=$((RESTORED+1)) ;;
        WARNING)  printf "  \033[31m!\033[0m %s\n" "$*"; WARNED=$((WARNED+1)) ;;
        SKIP)     printf "  \033[90m.\033[0m %s\n" "$*" ;;
        *)        printf "  %s\n" "$*" ;;
    esac
}

# Create a symlink if it doesn't already exist and point to the right target.
ensure_symlink() {
    local target="$1"
    local link_path="$2"

    if [ -L "$link_path" ]; then
        local current_target
        current_target="$(readlink "$link_path")"
        if [ "$current_target" = "$target" ]; then
            log EXISTS "$link_path"
            return
        fi
        if [ ! -e "$link_path" ]; then
            # Broken symlink, replace it
            rm "$link_path"
            ln -s "$target" "$link_path"
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

    ln -s "$target" "$link_path"
    log CREATED "$link_path -> $target"
}

# Remove broken symlinks and backup artifacts matching a glob.
cleanup_glob() {
    local dir="$1"
    local pattern="$2"

    for item in "$dir"/$pattern; do
        [ -e "$item" ] || [ -L "$item" ] || continue
        if [ -d "$item" ] && [ ! -L "$item" ]; then
            rm -rf "$item"
        else
            rm -f "$item"
        fi
        log CLEANED "$item"
    done
}

# Restore a config file from backup, removing a broken symlink at the target path first.
restore_backup() {
    local backup="$1"
    local target="$2"

    if [ ! -f "$backup" ]; then
        return  # Backup already cleaned up or never existed
    fi

    # If target is a broken symlink, remove it
    if [ -L "$target" ] && [ ! -e "$target" ]; then
        rm "$target"
    fi

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        return  # Real file already in place
    fi

    cp "$backup" "$target"
    log RESTORED "$target from $backup"
}

# ── Phase 1: Restore local configs ──────────────────────────────────

echo "Phase 1: Restore local configs from backups"

if [ -d "$CLAUDE_DIR" ]; then
    restore_backup "$CLAUDE_DIR/settings.json.backup.1774334085086" "$CLAUDE_DIR/settings.json"
fi

if [ -d "$CODEX_DIR" ]; then
    restore_backup "$CODEX_DIR/config.toml.backup.1774334085087" "$CODEX_DIR/config.toml"
fi

echo ""

# ── Phase 2: Clean up broken symlinks and backup artifacts ──────────

echo "Phase 2: Clean up broken symlinks and backup artifacts"

if [ -d "$CLAUDE_DIR" ]; then
    echo "  Claude Code:"
    # Remove broken symlinks (CLAUDE.md, commands, skills already handled by ensure_symlink,
    # but clean them explicitly in case they're broken from the old migration)
    for item in CLAUDE.md commands skills; do
        target="$CLAUDE_DIR/$item"
        if [ -L "$target" ] && [ ! -e "$target" ]; then
            rm "$target"
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
            rm "$target"
            log CLEANED "$target (broken symlink)"
        fi
    done
    cleanup_glob "$CODEX_DIR" "AGENTS.md.backup.*"
    cleanup_glob "$CODEX_DIR" "skills.backup.*"
    cleanup_glob "$CODEX_DIR" "config.toml.backup.*"
fi

echo ""

# ── Phase 2.5: Vendor skill repos ───────────────────────────────────

echo "Phase 2.5: Vendor skill repos"

ensure_vendor_repo() {
    local owner_repo="$1"
    local dest="$2"

    if [ -d "$dest/.git" ]; then
        log EXISTS "$dest"
        return 0
    fi

    if [ -e "$dest" ]; then
        log WARNING "$dest exists (not a git repo), skipping"
        return 1
    fi

    mkdir -p "$VENDOR_DIR"
    if git clone --quiet "https://github.com/$owner_repo" "$dest"; then
        log CREATED "$dest (cloned)"
        return 0
    fi

    log WARNING "$dest clone failed"
    return 1
}

link_vendor_skills() {
    local repo_dir="$1"
    local skills_subdir="$2"
    local src="$repo_dir/$skills_subdir"

    if [ ! -d "$src" ]; then
        log WARNING "$src not found"
        return
    fi

    for skill_dir in "$src"/*/; do
        [ -d "$skill_dir" ] || continue
        local name
        name="$(basename "$skill_dir")"
        ensure_symlink "$skill_dir" "$SKILLS_DIR/$name"
    done
}

for entry in "${VENDOR_SKILLS[@]}"; do
    owner_repo="${entry%%:*}"
    skills_subdir="${entry##*:}"
    repo_dir="$VENDOR_DIR/${owner_repo//\//-}"
    echo "  $owner_repo:"
    ensure_vendor_repo "$owner_repo" "$repo_dir" || continue
    link_vendor_skills "$repo_dir" "$skills_subdir"
done

echo ""

# ── Phase 3: Create symlinks ────────────────────────────────────────

echo "Phase 3: Create symlinks"

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
        for cmd in "${SHARED_COMMANDS[@]}"; do
            ensure_symlink "$COMMANDS_DIR/$cmd" "$CODEX_DIR/command/$cmd"
        done
    fi
fi

# Opencode
if [ -d "$OPENCODE_DIR" ]; then
    echo "  Opencode:"
    ensure_symlink "$AGENTS_MD" "$OPENCODE_DIR/AGENTS.md"
    if [ -d "$OPENCODE_DIR/command" ]; then
        for cmd in "${SHARED_COMMANDS[@]}"; do
            ensure_symlink "$COMMANDS_DIR/$cmd" "$OPENCODE_DIR/command/$cmd"
        done
    fi
fi

# Cursor
if [ -d "$CURSOR_DIR" ]; then
    echo "  Cursor:"
    if [ -d "$CURSOR_DIR/commands" ]; then
        for cmd in "${SHARED_COMMANDS[@]}"; do
            ensure_symlink "$COMMANDS_DIR/$cmd" "$CURSOR_DIR/commands/$cmd"
        done
    fi
fi

echo ""

# ── Summary ─────────────────────────────────────────────────────────

echo "Done: $CREATED created, $EXISTED unchanged, $CLEANED cleaned, $RESTORED restored, $WARNED warnings"
