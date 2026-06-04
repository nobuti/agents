#!/bin/bash
# Bootstrap ~/.agents on a new machine.
# Run from the repo root: bash setup.sh
#
# Does three things:
#   1. Symlinks ~/.agents → this repo
#   2. Runs sync.sh to wire up agent configs
#   3. Runs vendor-sync.sh to reconcile vendor plugins/packages
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

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

echo ""

# ── 2. Run sync.sh ────────────────────────────────────────────────────
echo "Running sync.sh to wire up agent configs..."
bash "$REPO_DIR/sync.sh"

echo ""

# ── 3. Run vendor-sync.sh ─────────────────────────────────────────────
if [ -f "$REPO_DIR/vendor-sync.sh" ]; then
    echo "Running vendor-sync.sh to reconcile vendor plugins..."
    bash "$REPO_DIR/vendor-sync.sh"
fi

echo ""
echo "Done. ~/.agents is ready."
