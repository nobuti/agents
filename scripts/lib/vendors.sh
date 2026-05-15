#!/bin/bash

vendor_trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

vendor_repo_dir_name() {
    local owner_repo="$1"
    printf '%s' "${owner_repo//\//-}"
}

vendor_repo_dir_path() {
    local vendor_dir="$1"
    local owner_repo="$2"
    printf '%s/%s' "$vendor_dir" "$(vendor_repo_dir_name "$owner_repo")"
}

vendor_clone_url() {
    local owner_repo="$1"
    printf 'https://github.com/%s' "$owner_repo"
}

vendor_each_config() {
    local config_path="$1"
    local vendor_dir="$2"
    local callback="$3"
    local raw_line=""
    local entry=""
    local owner_repo=""
    local skills_subdir=""
    local repo_dir=""
    local line_no=0

    [ -f "$config_path" ] || return 0

    while IFS= read -r raw_line || [ -n "$raw_line" ]; do
        line_no=$((line_no + 1))
        entry="$(vendor_trim "$raw_line")"

        case "$entry" in
            ''|\#*) continue ;;
        esac

        case "$entry" in
            *:*) ;;
            *)
                echo "Invalid vendors.conf line $line_no: expected owner/repo:skillsSubdir" >&2
                return 1
                ;;
        esac

        owner_repo="${entry%%:*}"
        skills_subdir="${entry#*:}"

        if [ -z "$owner_repo" ] || [ -z "$skills_subdir" ]; then
            echo "Invalid vendors.conf line $line_no: expected owner/repo:skillsSubdir" >&2
            return 1
        fi

        case "$owner_repo" in
            */*) ;;
            *)
                echo "Invalid vendors.conf line $line_no: owner/repo missing slash" >&2
                return 1
                ;;
        esac

        repo_dir="$(vendor_repo_dir_path "$vendor_dir" "$owner_repo")"
        "$callback" "$owner_repo" "$skills_subdir" "$repo_dir" "$line_no"
    done < "$config_path"
}

vendor_each_git_repo_dir() {
    local vendor_dir="$1"
    local callback="$2"
    local repo_dir=""

    [ -d "$vendor_dir" ] || return 0

    for repo_dir in "$vendor_dir"/*; do
        [ -d "$repo_dir/.git" ] || continue
        "$callback" "$repo_dir"
    done
}
