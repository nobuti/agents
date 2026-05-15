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
# Keep in sync with sync.sh VENDOR_SKILLS
VENDOR_DIR="$REPO_DIR/vendor"
VENDOR_SKILLS=(
    "addyosmani/agent-skills:skills"
)

mkdir -p "$VENDOR_DIR"

for entry in "${VENDOR_SKILLS[@]}"; do
    owner_repo="${entry%%:*}"
    dest="$VENDOR_DIR/${owner_repo//\//-}"
    echo "Vendor: $owner_repo"

    if [ -d "$dest/.git" ]; then
        printf "  \033[90m=\033[0m already cloned\n"
        git -C "$dest" pull --ff-only --quiet 2>/dev/null || \
            printf "  \033[33m!\033[0m pull failed — run vendor-update.sh later\n"
    else
        echo "  \033[32m+\033[0m cloning..."
        git clone --quiet "https://github.com/$owner_repo" "$dest"
    fi
done

echo ""

# ── 3. Run sync.sh ────────────────────────────────────────────────────
echo "Running sync.sh to wire up agent configs..."
bash "$REPO_DIR/sync.sh"

echo ""
echo "Done. ~/.agents is ready."
