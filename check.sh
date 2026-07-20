#!/bin/bash
# Validate the agents repository: frontmatter, links, shell scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
failures=0

echo "=== Frontmatter check ==="
for skill_dir in "$SKILLS_DIR"/*; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    skill_file="$skill_dir/SKILL.md"
    if [ ! -f "$skill_file" ]; then
        echo "FAIL: missing SKILL.md in $skill_name/"
        failures=$((failures + 1))
        continue
    fi

    fm_name=$(awk '/^---$/{c++;next} c==1 && /^name:/{sub(/^name:[[:space:]]*/,""); print; exit}' "$skill_file")
    if [ "$fm_name" != "$skill_name" ]; then
        echo "FAIL: $skill_name/SKILL.md name=\"$fm_name\" (expected \"$skill_name\")"
        failures=$((failures + 1))
    fi

    fm_desc=$(awk '/^---$/{c++;next} c==1 && /^description:/{print; exit}' "$skill_file")
    if [ -z "$fm_desc" ]; then
        echo "FAIL: $skill_name/SKILL.md missing description"
        failures=$((failures + 1))
    fi
done
echo "  $([ "$failures" -eq 0 ] && echo 'all passed' || echo "$failures failure(s)")"

echo ""
echo "=== Internal link check ==="
link_failures=0
for skill_dir in "$SKILLS_DIR"/*; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    skill_file="$skill_dir/SKILL.md"
    [ -f "$skill_file" ] || continue

    while IFS= read -r link; do
        [ -n "$link" ] || continue
        clean="${link%%#*}"
        [ -n "$clean" ] || continue
        target="$skill_dir/$clean"
        if [ ! -f "$target" ]; then
            echo "FAIL: $skill_name/SKILL.md links to $link (not found)"
            link_failures=$((link_failures + 1))
        fi
    done < <(grep -oP '\]\(\K[^)]+' "$skill_file" | grep -v '^https\?://' | grep -v '^/' || true)
done
echo "  $([ "$link_failures" -eq 0 ] && echo 'all passed' || echo "$link_failures failure(s)")"
failures=$((failures + link_failures))

echo ""
echo "=== Shell syntax check ==="
for script in setup.sh sync.sh check.sh; do
    target="$SCRIPT_DIR/$script"
    if [ -f "$target" ]; then
        bash -n "$target" || failures=$((failures + 1))
    fi
done
if command -v shellcheck &>/dev/null; then
    echo "  shellcheck found, running..."
    for script in setup.sh sync.sh check.sh; do
        target="$SCRIPT_DIR/$script"
        [ -f "$target" ] && shellcheck "$target" || true
    done
else
    echo "  shellcheck not installed (skipping)"
fi

echo ""
if [ "$failures" -eq 0 ]; then
    echo "All checks passed."
else
    echo "$failures check(s) failed."
    exit 1
fi
