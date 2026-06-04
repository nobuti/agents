#!/bin/bash
# vendor-sync.sh — manage vendor plugins/packages through each agent's native system.
# Idempotent. Safe to run multiple times.
#
# vendors.conf format (one per line):
#   vendor_id:agents:install_spec
#   vendor_id  — human name for logging
#   agents     — comma-separated: claude, pi
#   install_spec — agent-specific reference
#
# Example:
#   addyosmani/agent-skills:pi:git:github.com/addyosmani/agent-skills
#   addyosmani/agent-skills:claude:plugin:agent-skills@addy-agent-skills

set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-$HOME/.agents}"
VENDOR_CONF="$AGENTS_DIR/vendors.conf"

PI_DIR="${PI_DIR:-$HOME/.pi/agent}"
PI_SETTINGS="$PI_DIR/settings.json"

CLAUDE_PLUGINS_JSON="${CLAUDE_DIR:-$HOME/.claude}/plugins/installed_plugins.json"

# ── counters ──────────────────────────────────────────────────────
PI_ADDED=0; PI_REMOVED=0; PI_UNCHANGED=0
CLAUDE_INSTALLED=0; CLAUDE_MISSING=0; CLAUDE_ORPHAN=0
ERRORS=0

log() {
    local tag="$1"; shift
    case "$tag" in
        OK)      printf "  \033[32m✓\033[0m %s\n" "$*" ;;
        ADD)     printf "  \033[32m+\033[0m %s\n" "$*"; PI_ADDED=$((PI_ADDED+1)) ;;
        DEL)     printf "  \033[33m-\033[0m %s\n" "$*"; PI_REMOVED=$((PI_REMOVED+1)) ;;
        SKIP)    printf "  \033[90m=\033[0m %s\n" "$*"; PI_UNCHANGED=$((PI_UNCHANGED+1)) ;;
        INFO)    printf "  \033[34mℹ\033[0m %s\n" "$*" ;;
        WARN)    printf "  \033[31m!\033[0m %s\n" "$*"; ERRORS=$((ERRORS+1)) ;;
        ACTION)  printf "  \033[36m→\033[0m %s\n" "$*"; CLAUDE_MISSING=$((CLAUDE_MISSING+1)) ;;
        ORPHAN)  printf "  \033[33m~\033[0m %s\n" "$*"; CLAUDE_ORPHAN=$((CLAUDE_ORPHAN+1)) ;;
    esac
}

# ── helpers ─────────────────────────────────────────────────────────

trim() {
    local v="$1"
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    printf '%s' "$v"
}

# Parse vendors.conf into three parallel arrays.
# Each entry is: vendor_id agents install_spec
declare -a V_ID=()
declare -a V_AGENTS=()
declare -a V_SPEC=()

parse_vendors_conf() {
    local raw="" entry="" id="" agents="" spec="" line_no=0
    while IFS= read -r raw || [ -n "$raw" ]; do
        line_no=$((line_no + 1))
        entry="$(trim "$raw")"
        case "$entry" in
            ''|\#*) continue ;;
        esac

        # Expect exactly 3 colon-separated fields
        local f1 f2 f3 rest
        f1="${entry%%:*}"
        rest="${entry#*:}"
        f2="${rest%%:*}"
        f3="${rest#*:}"

        if [ -z "$f1" ] || [ -z "$f2" ] || [ "$f3" = "$rest" ]; then
            log WARN "vendors.conf line $line_no: expected vendor_id:agents:install_spec"
            continue
        fi

        V_ID+=("$f1")
        V_AGENTS+=("$f2")
        V_SPEC+=("$f3")
    done < "$VENDOR_CONF"
}

agent_in_list() {
    local needle="$1" list="$2"
    local IFS=',' p
    for p in $list; do
        [ "$(trim "$p")" = "$needle" ] && return 0
    done
    return 1
}

# ── pi ──────────────────────────────────────────────────────────────

sync_pi() {
    echo ""
    echo "pi"

    if [ ! -f "$PI_SETTINGS" ]; then
        log WARN "$PI_SETTINGS not found; skipping pi sync"
        return
    fi

    # Build desired pi package list from vendors.conf
    local desired=()
    local i
    for ((i = 0; i < ${#V_ID[@]}; i++)); do
        agent_in_list "pi" "${V_AGENTS[$i]}" || continue
        desired+=("${V_SPEC[$i]}")
    done

    if [ ${#desired[@]} -eq 0 ]; then
        log INFO "no pi vendors declared"
    fi

    # Read current packages array
    local current_json="[]"
    if jq -e 'has("packages")' "$PI_SETTINGS" >/dev/null 2>&1; then
        current_json="$(jq '.packages // []' "$PI_SETTINGS")"
    fi

    # Normalize current packages to plain strings (ignore filter objects for now)
    local current=()
    while IFS= read -r line; do
        [ -n "$line" ] && current+=("$line")
    done < <(jq -r '.[] | if type == "string" then . else .source end' <<< "$current_json" 2>/dev/null || true)

    # Determine packages to add and remove
    local to_add=() to_remove=()

    for d in "${desired[@]}"; do
        local found=0
        for c in "${current[@]}"; do
            [ "$c" = "$d" ] && { found=1; break; }
        done
        [ "$found" -eq 0 ] && to_add+=("$d")
    done

    for c in "${current[@]}"; do
        local found=0
        for d in "${desired[@]}"; do
            [ "$c" = "$d" ] && { found=1; break; }
        done
        [ "$found" -eq 0 ] && to_remove+=("$c")
    done

    # If no changes, report and exit
    if [ ${#to_add[@]} -eq 0 ] && [ ${#to_remove[@]} -eq 0 ]; then
        for d in "${desired[@]}"; do
            log SKIP "$d"
        done
        return
    fi

    # Build new packages array as JSON
    local new_packages="["
    local first=1
    for d in "${desired[@]}"; do
        [ "$first" -eq 1 ] || new_packages+=","
        new_packages+=$(jq -Rs '.[:-1]' <<< "$d")
        first=0
    done
    new_packages+="]"

    # Write back to settings.json
    local tmp
    tmp="$(mktemp)"
    jq --argjson pkgs "$new_packages" '.packages = $pkgs' "$PI_SETTINGS" > "$tmp"
    mv "$tmp" "$PI_SETTINGS"

    for a in "${to_add[@]}"; do
        log ADD "$a (pi will install on next startup)"
    done
    for r in "${to_remove[@]}"; do
        log DEL "$r (run: pi remove $r)"
    done
    for d in "${desired[@]}"; do
        local in_add=0 in_rem=0
        for a in "${to_add[@]}"; do [ "$a" = "$d" ] && in_add=1; done
        for r in "${to_remove[@]}"; do [ "$r" = "$d" ] && in_rem=1; done
        [ "$in_add" -eq 0 ] && [ "$in_rem" -eq 0 ] && log SKIP "$d"
    done
}

# ── claude ──────────────────────────────────────────────────────────

# Extract plugin name from install_spec like "plugin:agent-skills@addy-agent-skills"
claude_plugin_name_from_spec() {
    local spec="$1"
    case "$spec" in
        plugin:*)
            printf '%s' "${spec#plugin:}"
            ;;
        *)
            printf '%s' "$spec"
            ;;
    esac
}

# Extract marketplace from "agent-skills@addy-agent-skills" → "addy-agent-skills"
claude_marketplace_from_spec() {
    local name="$1"
    case "$name" in
        *@*)
            printf '%s' "${name#*@}"
            ;;
        *)
            printf '%s' "claude-plugins-official"
            ;;
    esac
}

# Check if marketplace is already registered in known_marketplaces.json
claude_marketplace_is_known() {
    local marketplace="$1"
    local known_json="${CLAUDE_DIR:-$HOME/.claude}/plugins/known_marketplaces.json"
    [ -f "$known_json" ] || return 1
    jq -e --arg m "$marketplace" 'has($m)' "$known_json" >/dev/null 2>&1
}

sync_claude() {
    echo ""
    echo "Claude Code"

    if [ ! -f "$CLAUDE_PLUGINS_JSON" ]; then
        log WARN "$CLAUDE_PLUGINS_JSON not found; skipping claude sync"
        return
    fi

    # Build desired plugin list
    local desired_names=() desired_specs=() desired_vids=()
    local i
    for ((i = 0; i < ${#V_ID[@]}; i++)); do
        agent_in_list "claude" "${V_AGENTS[$i]}" || continue
        local name spec
        spec="${V_SPEC[$i]}"
        name="$(claude_plugin_name_from_spec "$spec")"
        desired_names+=("$name")
        desired_specs+=("$spec")
        desired_vids+=("${V_ID[$i]}")
    done

    if [ ${#desired_names[@]} -eq 0 ]; then
        log INFO "no claude vendors declared"
    fi

    # Read installed plugins
    local installed=()
    while IFS= read -r line; do
        [ -n "$line" ] && installed+=("$line")
    done < <(jq -r '(.plugins // {}) | keys[]' "$CLAUDE_PLUGINS_JSON" 2>/dev/null || true)

    # Check desired plugins
    for ((i = 0; i < ${#desired_names[@]}; i++)); do
        local name="${desired_names[$i]}" spec="${desired_specs[$i]}"
        local found=0
        local entry
        for entry in "${installed[@]}"; do
            [ "$entry" = "$name" ] && { found=1; break; }
        done

        if [ "$found" -eq 1 ]; then
            # Verify installPath exists
            local path
            path="$(jq -r --arg k "$name" '.plugins[$k][0].installPath // empty' "$CLAUDE_PLUGINS_JSON" 2>/dev/null || true)"
            if [ -n "$path" ] && [ -e "$path" ]; then
                log OK "$name"
                CLAUDE_INSTALLED=$((CLAUDE_INSTALLED+1))
            else
                log WARN "$name — installed but cache missing at $path"
            fi
        else
            local marketplace
            marketplace="$(claude_marketplace_from_spec "$name")"
            if [ "$marketplace" != "claude-plugins-official" ] && ! claude_marketplace_is_known "$marketplace"; then
                log ACTION "Run inside claude: /plugin marketplace add ${desired_vids[$i]}"
            fi
            log ACTION "Run inside claude: /plugin install $name"
        fi
    done

    # Check orphaned plugins
    for entry in "${installed[@]}"; do
        local found=0
        for name in "${desired_names[@]}"; do
            [ "$entry" = "$name" ] && { found=1; break; }
        done
        [ "$found" -eq 0 ] && log ORPHAN "Run inside claude: /plugin remove $entry"
    done
}

# ── main ────────────────────────────────────────────────────────────

if [ ! -f "$VENDOR_CONF" ]; then
    echo "No vendors.conf found at $VENDOR_CONF — nothing to sync."
    exit 0
fi

parse_vendors_conf

if [ ${#V_ID[@]} -eq 0 ]; then
    echo "vendors.conf is empty — nothing to sync."
    exit 0
fi

echo "vendor-sync.sh — $(date -Is)"
echo "Loaded ${#V_ID[@]} vendor entry(s) from $VENDOR_CONF"

sync_pi
sync_claude

# ── summary ─────────────────────────────────────────────────────────

echo ""
echo "Summary"
printf "  pi:      %d added, %d removed, %d unchanged\n" "$PI_ADDED" "$PI_REMOVED" "$PI_UNCHANGED"
printf "  claude:  %d installed, %d missing (manual), %d orphaned (manual)\n" "$CLAUDE_INSTALLED" "$CLAUDE_MISSING" "$CLAUDE_ORPHAN"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
if [ "$CLAUDE_MISSING" -gt 0 ] || [ "$CLAUDE_ORPHAN" -gt 0 ]; then
    exit 2   # human action required
fi
exit 0
