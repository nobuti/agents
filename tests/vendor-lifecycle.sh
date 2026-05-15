#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_exists() {
    [ -e "$1" ] || fail "expected path to exist: $1"
}

assert_not_exists() {
    [ ! -e "$1" ] && [ ! -L "$1" ] || fail "expected path to be absent: $1"
}

assert_contains() {
    local needle="$1"
    local file="$2"
    grep -F "$needle" "$file" >/dev/null || fail "expected '$needle' in $file"
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -F "$needle" "$file" >/dev/null; then
        fail "did not expect '$needle' in $file"
    fi
}

make_repo() {
    local repo="$1"
    mkdir -p "$repo/commands" "$repo/skills/local-skill" "$repo/vendor"

    cp "$PROJECT_ROOT/setup.sh" "$repo/setup.sh"
    cp "$PROJECT_ROOT/sync.sh" "$repo/sync.sh"
    cp "$PROJECT_ROOT/vendor-update.sh" "$repo/vendor-update.sh"
    if [ -f "$PROJECT_ROOT/scripts/lib/vendors.sh" ]; then
        mkdir -p "$repo/scripts/lib"
        cp "$PROJECT_ROOT/scripts/lib/vendors.sh" "$repo/scripts/lib/vendors.sh"
    fi

    cat > "$repo/AGENTS.md" <<'EOF'
fixture agents
EOF
    cat > "$repo/commands/pr.md" <<'EOF'
fixture pr
EOF
    cat > "$repo/commands/commits.md" <<'EOF'
fixture commits
EOF
    cat > "$repo/skills/local-skill/SKILL.md" <<'EOF'
local skill
EOF
}

make_fake_git() {
    local bin_dir="$1"
    mkdir -p "$bin_dir"
    cat > "$bin_dir/git" <<'EOF'
#!/bin/bash
set -euo pipefail

log_line() {
    if [ -n "${FAKE_GIT_LOG:-}" ]; then
        echo "$*" >> "$FAKE_GIT_LOG"
    fi
}

repo_dir=""
if [ "${1:-}" = "-C" ]; then
    repo_dir="$2"
    shift 2
fi

command="${1:-}"
shift || true

case "$command" in
    clone)
        if [ "${1:-}" = "--quiet" ]; then
            shift
        fi
        url="$1"
        dest="$2"
        mkdir -p "$dest/.git"
        echo "deadbee" > "$dest/.git/HEAD_VALUE"
        log_line "clone $url $dest"
        ;;
    pull)
        log_line "pull ${repo_dir}"
        ;;
    rev-parse)
        if [ "${1:-}" = "HEAD" ]; then
            if [ -f "$repo_dir/.git/HEAD_VALUE" ]; then
                cat "$repo_dir/.git/HEAD_VALUE"
            else
                echo "deadbee"
            fi
        else
            echo "unsupported rev-parse args: $*" >&2
            exit 1
        fi
        ;;
    *)
        echo "unsupported git command: $command $*" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$bin_dir/git"
}

create_vendor_repo() {
    local repo_root="$1"
    local owner_repo="$2"
    local skills_subdir="$3"
    local skill_name="$4"
    local repo_dir="$repo_root/vendor/${owner_repo//\//-}"

    mkdir -p "$repo_dir/.git" "$repo_dir/$skills_subdir/$skill_name"
}

run_test() {
    local name="$1"
    shift
    echo "== $name =="
    "$@"
}

test_sync_prunes_stale_vendor_symlink_by_default() {
    local tmp
    tmp="$(mktemp -d)"
    local repo="$tmp/repo"
    local home="$tmp/home"

    make_repo "$repo"
    mkdir -p "$home"
    ln -s "$repo" "$home/.agents"

    cat > "$repo/vendors.conf" <<'EOF'
owner/repo:skills
EOF
    create_vendor_repo "$repo" "owner/repo" "skills" "active-skill"
    mkdir -p "$repo/vendor/stale-repo/.git" "$repo/vendor/stale-repo/skills/stale-skill"
    ln -s "$repo/vendor/stale-repo/skills/stale-skill/" "$repo/skills/stale-skill"

    HOME="$home" bash "$repo/sync.sh" >/tmp/vendor-sync.out 2>&1 || {
        cat /tmp/vendor-sync.out >&2
        fail "sync.sh failed unexpectedly"
    }

    assert_exists "$repo/skills/active-skill"
    assert_not_exists "$repo/skills/stale-skill"
}

test_sync_dry_run_keeps_stale_vendor_symlink() {
    local tmp
    tmp="$(mktemp -d)"
    local repo="$tmp/repo"
    local home="$tmp/home"

    make_repo "$repo"
    mkdir -p "$home"
    ln -s "$repo" "$home/.agents"

    cat > "$repo/vendors.conf" <<'EOF'
owner/repo:skills
EOF
    create_vendor_repo "$repo" "owner/repo" "skills" "active-skill"
    mkdir -p "$repo/vendor/stale-repo/.git" "$repo/vendor/stale-repo/skills/stale-skill"
    ln -s "$repo/vendor/stale-repo/skills/stale-skill/" "$repo/skills/stale-skill"

    HOME="$home" bash "$repo/sync.sh" --dry-run >/tmp/vendor-sync-dry.out 2>&1 || {
        cat /tmp/vendor-sync-dry.out >&2
        fail "sync.sh --dry-run failed unexpectedly"
    }

    assert_exists "$repo/skills/stale-skill"
}

test_sync_fails_on_duplicate_vendor_skill_names() {
    local tmp
    tmp="$(mktemp -d)"
    local repo="$tmp/repo"
    local home="$tmp/home"
    local output="$tmp/output.log"

    make_repo "$repo"
    mkdir -p "$home"
    ln -s "$repo" "$home/.agents"

    cat > "$repo/vendors.conf" <<'EOF'
owner/one:skills
owner/two:skills
EOF
    create_vendor_repo "$repo" "owner/one" "skills" "same-skill"
    create_vendor_repo "$repo" "owner/two" "skills" "same-skill"

    if HOME="$home" bash "$repo/sync.sh" >"$output" 2>&1; then
        cat "$output" >&2
        fail "sync.sh should fail on duplicate vendor skill names"
    fi

    assert_contains "same-skill" "$output"
}

test_setup_does_not_pull_existing_vendor_repos() {
    local tmp
    tmp="$(mktemp -d)"
    local repo="$tmp/repo"
    local home="$tmp/home"
    local fake_bin="$tmp/bin"
    local git_log="$tmp/git.log"

    make_repo "$repo"
    make_fake_git "$fake_bin"
    : > "$git_log"
    mkdir -p "$home" "$repo/vendor/owner-repo/.git" "$repo/vendor/owner-repo/skills/existing-skill"
    echo "deadbee" > "$repo/vendor/owner-repo/.git/HEAD_VALUE"

    cat > "$repo/vendors.conf" <<'EOF'
owner/repo:skills
EOF

    PATH="$fake_bin:$PATH" FAKE_GIT_LOG="$git_log" HOME="$home" bash "$repo/setup.sh" >/tmp/setup.out 2>&1 || {
        cat /tmp/setup.out >&2
        fail "setup.sh failed unexpectedly"
    }

    assert_not_contains "pull $repo/vendor/owner-repo" "$git_log"
    assert_not_contains "clone https://github.com/owner/repo $repo/vendor/owner-repo" "$git_log"
}

test_vendor_update_reports_orphaned_repos() {
    local tmp
    tmp="$(mktemp -d)"
    local repo="$tmp/repo"
    local home="$tmp/home"
    local fake_bin="$tmp/bin"
    local output="$tmp/output.log"

    make_repo "$repo"
    make_fake_git "$fake_bin"
    mkdir -p "$home"
    ln -s "$repo" "$home/.agents"

    cat > "$repo/vendors.conf" <<'EOF'
owner/repo:skills
EOF
    mkdir -p "$repo/vendor/owner-repo/.git" "$repo/vendor/orphan-repo/.git"
    echo "deadbee" > "$repo/vendor/owner-repo/.git/HEAD_VALUE"
    echo "deadbee" > "$repo/vendor/orphan-repo/.git/HEAD_VALUE"

    PATH="$fake_bin:$PATH" HOME="$home" bash "$repo/vendor-update.sh" >"$output" 2>&1 || {
        cat "$output" >&2
        fail "vendor-update.sh failed unexpectedly"
    }

    assert_contains "orphan" "$output"
}

run_test "sync prunes stale vendored skill symlinks by default" test_sync_prunes_stale_vendor_symlink_by_default
run_test "sync keeps stale vendored symlink in dry-run mode" test_sync_dry_run_keeps_stale_vendor_symlink
run_test "sync fails on duplicate vendor skill names" test_sync_fails_on_duplicate_vendor_skill_names
run_test "setup skips pull for existing vendor repos" test_setup_does_not_pull_existing_vendor_repos
run_test "vendor-update reports orphaned repos" test_vendor_update_reports_orphaned_repos

echo "PASS"
