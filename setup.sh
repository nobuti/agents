#!/bin/bash
# Bootstrap ~/.agents on a new machine.
# Run from the repo root: bash setup.sh
#
# Does three things:
#   1. Symlinks ~/.agents → this repo
#   2. Clones vendor repos into vendor/
#   3. Runs sync.sh to wire everything up to .claude, .codex, .opencode, .cursor
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./scripts/lib/vendors.sh
source "$REPO_DIR/scripts/lib/vendors.sh"

# ── 1. Create ~/.agents symlink ───────────────────────────────────────
if [ -L "$HOME/.agents" ]; then
    current="$(readlink "$HOME/.agents")"
    if [ "$current" = "$REPO_DIR" ]; then
        printf "\033[90m=\033[0m ~/.agents already points to this repo\n"
    else
        printf "\033[33m-\033[0m ~/.agents -> %s (repointing)\n" "$current"
        rm "$HOME/.agents"
        ln -s "$REPO_DIR" "$HOME/.agents"
        printf "\033[32m+\033[0m ~/.agents -> %s\n" "$REPO_DIR"
    fi
elif [ -d "$HOME/.agents" ]; then
    printf "\033[31m!\033[0m ~/.agents exists as a real directory.\n"
    printf "    Either move it aside or run from a clean machine.\n"
    exit 1
else
    ln -s "$REPO_DIR" "$HOME/.agents"
    printf "\033[32m+\033[0m ~/.agents -> %s\n" "$REPO_DIR"
fi

# ── 2. Clone vendor repos ─────────────────────────────────────────────
VENDOR_DIR="$REPO_DIR/vendor"
VENDOR_CONF="$REPO_DIR/vendors.conf"
mkdir -p "$VENDOR_DIR"

setup_vendor_repo() {
    local owner_repo="$1"
    local skills_subdir="$2"
    local dest="$3"

    echo "Vendor: $owner_repo"

    if [ -d "$dest/.git" ]; then
        printf "  \033[90m=\033[0m already cloned\n"
        return
    fi

    printf "  \033[32m+\033[0m cloning\n"
    git clone --quiet "$(vendor_clone_url "$owner_repo")" "$dest"
}

if [ ! -f "$VENDOR_CONF" ]; then
    echo "No vendors.conf found, skipping vendor setup."
else
    vendor_each_config "$VENDOR_CONF" "$VENDOR_DIR" setup_vendor_repo
fi

echo ""

# ── 3. Run sync.sh ────────────────────────────────────────────────────
echo "Running sync.sh to wire up agent configs..."
bash "$REPO_DIR/sync.sh"

echo ""
echo "Done. ~/.agents is ready."
