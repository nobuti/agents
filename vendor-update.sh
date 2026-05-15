#!/bin/bash
# Pull latest for each vendored skill repo declared in ~/.agents/vendors.conf.
# Run when you want fresh upstream skills. Then re-run sync.sh to reconcile
# new/removed skill symlinks.
set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-$HOME/.agents}"
VENDOR_DIR="$AGENTS_DIR/vendor"
VENDOR_CONF="$AGENTS_DIR/vendors.conf"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./scripts/lib/vendors.sh
source "$SCRIPT_DIR/scripts/lib/vendors.sh"

UPDATED=0; UNCHANGED=0; FAILED=0; WARNED=0
EXPECTED_VENDOR_REPOS=()

log_warning() {
    printf "  \033[31m!\033[0m %s\n" "$*"
    WARNED=$((WARNED+1))
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

update_vendor_repo() {
    local owner_repo="$1"
    local skills_subdir="$2"
    local repo_dir="$3"

    EXPECTED_VENDOR_REPOS+=("$repo_dir")

    if [ ! -d "$repo_dir/.git" ]; then
        log_warning "$repo_dir missing for $owner_repo; run setup.sh first"
        FAILED=$((FAILED+1))
        return
    fi

    printf "  %s ... " "$(basename "$repo_dir")"

    local before=""
    local after=""
    before="$(git -C "$repo_dir" rev-parse HEAD)"
    if ! git -C "$repo_dir" pull --ff-only --quiet 2>/dev/null; then
        printf "\033[31mFAILED\033[0m (non-fast-forward or network error)\n"
        FAILED=$((FAILED+1))
        return
    fi
    after="$(git -C "$repo_dir" rev-parse HEAD)"

    if [ "$before" = "$after" ]; then
        printf "\033[90munchanged\033[0m\n"
        UNCHANGED=$((UNCHANGED+1))
    else
        printf "\033[32mupdated\033[0m %s..%s\n" "${before:0:7}" "${after:0:7}"
        UPDATED=$((UPDATED+1))
    fi
}

report_orphaned_repo() {
    local repo_dir="$1"

    if array_contains "$repo_dir" "${EXPECTED_VENDOR_REPOS[@]}"; then
        return
    fi

    log_warning "$repo_dir is orphaned (not declared in vendors.conf)"
}

if [ ! -f "$VENDOR_CONF" ]; then
    echo "No vendors.conf found at $VENDOR_CONF — nothing to update."
    exit 0
fi

mkdir -p "$VENDOR_DIR"
vendor_each_config "$VENDOR_CONF" "$VENDOR_DIR" update_vendor_repo
vendor_each_git_repo_dir "$VENDOR_DIR" report_orphaned_repo

echo ""
echo "Done: $UPDATED updated, $UNCHANGED unchanged, $FAILED failed, $WARNED warnings"
if [ "$UPDATED" -gt 0 ]; then
    echo "Run sync.sh to reconcile any new/removed skills."
fi
