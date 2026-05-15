#!/bin/bash
# Sync shared agent content from ~/.agents/ to all agent config directories.
# Idempotent. Safe to run multiple times.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./scripts/lib/vendors.sh
source "$SCRIPT_DIR/scripts/lib/vendors.sh"

AGENTS_DIR="${AGENTS_DIR:-$HOME/.agents}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_DIR:-$HOME/.codex}"
OPENCODE_DIR="${OPENCODE_DIR:-$HOME/.opencode}"
CURSOR_DIR="${CURSOR_DIR:-$HOME/.cursor}"

AGENTS_MD="$AGENTS_DIR/AGENTS.md"
COMMANDS_DIR="$AGENTS_DIR/commands"
SKILLS_DIR="$AGENTS_DIR/skills"
VENDOR_DIR="$AGENTS_DIR/vendor"
AGENTS_REAL_DIR="$AGENTS_DIR"
if [ -d "$AGENTS_DIR" ]; then
    AGENTS_REAL_DIR="$(cd "$AGENTS_DIR" && pwd -P)"
fi
VENDOR_REAL_DIR="$AGENTS_REAL_DIR/vendor"

SHARED_COMMANDS=(pr.md commits.md)
VENDOR_CONF="$AGENTS_DIR/vendors.conf"

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
CREATED=0; EXISTED=0; CLEANED=0; RESTORED=0; WARNED=0; DRYRUNS=0; ERRORS=0

EXPECTED_VENDOR_REPOS=()
DESIRED_VENDOR_SKILL_NAMES=()
DESIRED_VENDOR_SKILL_TARGETS=()
DESIRED_VENDOR_SKILL_LINKS=()

log() {
    local tag="$1"; shift
    case "$tag" in
        CREATED)  printf "  \033[32m+\033[0m %s\n" "$*"; CREATED=$((CREATED+1)) ;;
        EXISTS)   printf "  \033[34m=\033[0m %s\n" "$*"; EXISTED=$((EXISTED+1)) ;;
        CLEANED)  printf "  \033[33m-\033[0m %s\n" "$*"; CLEANED=$((CLEANED+1)) ;;
        RESTORED) printf "  \033[36mR\033[0m %s\n" "$*"; RESTORED=$((RESTORED+1)) ;;
        WARNING)  printf "  \033[31m!\033[0m %s\n" "$*"; WARNED=$((WARNED+1)) ;;
        ERROR)    printf "  \033[31mX\033[0m %s\n" "$*"; ERRORS=$((ERRORS+1)) ;;
        DRYRUN)   printf "  \033[35m~\033[0m %s\n" "$*"; DRYRUNS=$((DRYRUNS+1)) ;;
        SKIP)     printf "  \033[90m.\033[0m %s\n" "$*" ;;
        *)        printf "  %s\n" "$*" ;;
    esac
}

array_contains() {
    local needle="$1"
    shift
    local item=""
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

find_desired_skill_index() {
    local needle="$1"
    local i=0
    for ((i = 0; i < ${#DESIRED_VENDOR_SKILL_NAMES[@]}; i++)); do
        if [ "${DESIRED_VENDOR_SKILL_NAMES[$i]}" = "$needle" ]; then
            printf '%s' "$i"
            return 0
        fi
    done
    return 1
}

remove_path() {
    local path="$1"
    local kind="$2"

    if [ "$DRY_RUN" -eq 1 ]; then
        log DRYRUN "$path ($kind)"
        return
    fi

    case "$kind" in
        dir) rm -rf "$path" ;;
        *) rm -f "$path" ;;
    esac
}

copy_file() {
    local from="$1"
    local to="$2"

    if [ "$DRY_RUN" -eq 1 ]; then
        log DRYRUN "$to from $from"
        return
    fi

    cp "$from" "$to"
}

create_symlink() {
    local target="$1"
    local link_path="$2"

    if [ "$DRY_RUN" -eq 1 ]; then
        log DRYRUN "$link_path -> $target"
        return
    fi

    ln -s "$target" "$link_path"
}

clone_vendor_repo() {
    local owner_repo="$1"
    local repo_dir="$2"

    mkdir -p "$VENDOR_DIR"

    if [ "$DRY_RUN" -eq 1 ]; then
        log DRYRUN "$repo_dir (clone $(vendor_clone_url "$owner_repo"))"
        return 0
    fi

    git clone --quiet "$(vendor_clone_url "$owner_repo")" "$repo_dir"
    log CREATED "$repo_dir (cloned)"
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
    local dir="$1"
    local pattern="$2"
    local item=""

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

restore_backup() {
    local backup="$1"
    local target="$2"

    if [ ! -f "$backup" ]; then
        return
    fi

    if [ -L "$target" ] && [ ! -e "$target" ]; then
        remove_path "$target" file
    fi

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        return
    fi

    copy_file "$backup" "$target"
    log RESTORED "$target from $backup"
}

collect_vendor_state() {
    local owner_repo="$1"
    local skills_subdir="$2"
    local repo_dir="$3"
    local line_no="$4"
    local src=""
    local skill_dir=""
    local skill_name=""

    EXPECTED_VENDOR_REPOS+=("$repo_dir")

    if [ -e "$repo_dir" ] && [ ! -d "$repo_dir/.git" ]; then
        log ERROR "$repo_dir exists but is not a git repo (vendors.conf line $line_no)"
        return
    fi

    if [ ! -d "$repo_dir/.git" ]; then
        clone_vendor_repo "$owner_repo" "$repo_dir"
    fi

    if [ ! -d "$repo_dir/.git" ]; then
        log WARNING "$repo_dir missing; cannot inspect skills for $owner_repo during dry run"
        return
    fi

    src="$repo_dir/$skills_subdir"
    if [ ! -d "$src" ]; then
        log ERROR "$src not found for $owner_repo (vendors.conf line $line_no)"
        return
    fi

    for skill_dir in "$src"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name="$(basename "$skill_dir")"

        local existing_index=""
        if existing_index="$(find_desired_skill_index "$skill_name")"; then
            local existing_target="${DESIRED_VENDOR_SKILL_TARGETS[$existing_index]}"
            log ERROR "duplicate vendor skill '$skill_name': $existing_target and $skill_dir"
            continue
        fi

        DESIRED_VENDOR_SKILL_NAMES+=("$skill_name")
        DESIRED_VENDOR_SKILL_TARGETS+=("$skill_dir")
        DESIRED_VENDOR_SKILL_LINKS+=("$SKILLS_DIR/$skill_name")
    done
}

report_orphaned_vendor_repo() {
    local repo_dir="$1"

    if array_contains "$repo_dir" "${EXPECTED_VENDOR_REPOS[@]}"; then
        return
    fi

    log WARNING "$repo_dir is orphaned (not declared in vendors.conf)"
}

validate_vendor_skill_link() {
    local target="$1"
    local link_path="$2"
    local current_target=""

    if [ -L "$link_path" ]; then
        current_target="$(readlink "$link_path")"
        if [ "$current_target" = "$target" ]; then
            return
        fi
        if [ ! -e "$link_path" ]; then
            return
        fi
        log ERROR "$link_path points to $current_target (expected $target)"
        return
    fi

    if [ -e "$link_path" ]; then
        log ERROR "$link_path exists and is not a vendor symlink"
    fi
}

apply_vendor_skill_link() {
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
            remove_path "$link_path" file
            create_symlink "$target" "$link_path"
            log CREATED "$link_path -> $target (replaced broken link)"
            return
        fi
    fi

    if [ -e "$link_path" ]; then
        return
    fi

    create_symlink "$target" "$link_path"
    log CREATED "$link_path -> $target"
}

prune_stale_vendor_skill_links() {
    local skill_path=""
    local skill_name=""
    local current_target=""
    local resolved_target=""
    local is_vendor_target=0

    [ -d "$SKILLS_DIR" ] || return

    for skill_path in "$SKILLS_DIR"/*; do
        [ -L "$skill_path" ] || continue
        current_target="$(readlink "$skill_path")"
        resolved_target=""
        is_vendor_target=0

        case "$current_target" in
            "$VENDOR_DIR"/*) is_vendor_target=1 ;;
        esac

        if [ -d "$current_target" ]; then
            resolved_target="$(cd "$current_target" && pwd -P)"
            case "$resolved_target" in
                "$VENDOR_REAL_DIR"/*) is_vendor_target=1 ;;
            esac
        fi

        [ "$is_vendor_target" -eq 1 ] || continue

        skill_name="$(basename "$skill_path")"
        if array_contains "$skill_name" "${DESIRED_VENDOR_SKILL_NAMES[@]}"; then
            continue
        fi

        remove_path "$skill_path" file
        log CLEANED "$skill_path (stale vendor skill symlink)"
    done
}

validate_vendor_skill_links() {
    local i=0
    for ((i = 0; i < ${#DESIRED_VENDOR_SKILL_NAMES[@]}; i++)); do
        validate_vendor_skill_link "${DESIRED_VENDOR_SKILL_TARGETS[$i]}" "${DESIRED_VENDOR_SKILL_LINKS[$i]}"
    done
}

apply_vendor_skill_links() {
    local i=0
    for ((i = 0; i < ${#DESIRED_VENDOR_SKILL_NAMES[@]}; i++)); do
        apply_vendor_skill_link "${DESIRED_VENDOR_SKILL_TARGETS[$i]}" "${DESIRED_VENDOR_SKILL_LINKS[$i]}"
    done
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

# ── Phase 2.5: Vendor skill repos ───────────────────────────────────

echo "Phase 2.5: Vendor skill repos"

if [ -f "$VENDOR_CONF" ]; then
    vendor_each_config "$VENDOR_CONF" "$VENDOR_DIR" collect_vendor_state
else
    log SKIP "No vendors.conf found"
fi

vendor_each_git_repo_dir "$VENDOR_DIR" report_orphaned_vendor_repo
validate_vendor_skill_links

if [ "$ERRORS" -eq 0 ]; then
    apply_vendor_skill_links
    prune_stale_vendor_skill_links
fi

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

if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run: no filesystem changes made."
fi

echo "Done: $CREATED created, $EXISTED unchanged, $CLEANED cleaned, $RESTORED restored, $WARNED warnings, $DRYRUNS dry-run actions, $ERRORS errors"
[ "$ERRORS" -eq 0 ]
