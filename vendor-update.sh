#!/bin/bash
# Pull latest for each vendored skill repo under ~/.agents/vendor/.
# Run when you want fresh upstream skills. Then re-run sync.sh to reconcile
# new/removed skill symlinks.
set -euo pipefail

VENDOR_DIR="$HOME/.agents/vendor"

if [ ! -d "$VENDOR_DIR" ]; then
    echo "No vendor dir at $VENDOR_DIR — nothing to update."
    exit 0
fi

UPDATED=0; UNCHANGED=0; FAILED=0

for repo in "$VENDOR_DIR"/*/; do
    [ -d "$repo/.git" ] || continue
    name="$(basename "$repo")"
    printf "  %s ... " "$name"

    before="$(git -C "$repo" rev-parse HEAD)"
    if ! git -C "$repo" pull --ff-only --quiet 2>/dev/null; then
        printf "\033[31mFAILED\033[0m (non-fast-forward or network error)\n"
        FAILED=$((FAILED+1))
        continue
    fi
    after="$(git -C "$repo" rev-parse HEAD)"

    if [ "$before" = "$after" ]; then
        printf "\033[90munchanged\033[0m\n"
        UNCHANGED=$((UNCHANGED+1))
    else
        printf "\033[32mupdated\033[0m %s..%s\n" "${before:0:7}" "${after:0:7}"
        UPDATED=$((UPDATED+1))
    fi
done

echo ""
echo "Done: $UPDATED updated, $UNCHANGED unchanged, $FAILED failed"
[ "$UPDATED" -gt 0 ] && echo "Run sync.sh to reconcile any new/removed skills."
