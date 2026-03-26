#!/bin/bash
set -euo pipefail

PANE_WIDTH="${1:-80}"
PANE_PID="${2:-}"
PANE_TTY="${3:-}"
PANE_PATH="${4:-}"
PANE_PATH_BASE="${5:-}"
PANE_CMD="${6:-}"
PANE_TITLE="${7:-}"
PANE_ID="${8:-}"

if [[ -x /usr/bin/git ]]; then
    GIT_BIN="${GIT_BIN:-/usr/bin/git}"
else
    GIT_BIN="${GIT_BIN:-$(command -v git 2>/dev/null || echo git)}"
fi

hostname_full="$(hostname 2>/dev/null || true)"
hostname_short="${hostname_full%%.*}"

title_is_noise() {
    local title="${1:-}"
    [[ -z "$title" ]] && return 0
    [[ "$title" == "$PANE_CMD" ]] && return 0
    [[ "$title" == "$hostname_full" ]] && return 0
    [[ "$title" == "$hostname_short" ]] && return 0
    [[ -n "${HOSTNAME:-}" && "$title" == "$HOSTNAME" ]] && return 0
    [[ -n "${HOSTNAME:-}" && "$title" == "${HOSTNAME%%.*}" ]] && return 0
    return 1
}

repo_name_from_path() {
    local path="${1:-}"
    local common_dir

    [[ -n "$path" && -d "$path" ]] || return 1

    if common_dir="$("$GIT_BIN" -C "$path" rev-parse --git-common-dir 2>/dev/null)"; then
        if [[ "$common_dir" != /* ]]; then
            common_dir="$(cd "$path" && cd "$common_dir" && pwd)"
        fi
        basename "$(dirname "$common_dir")"
        return 0
    fi

    basename "$path"
}

normalize_command() {
    case "${1:-}" in
        codex*) printf 'codex\n' ;;
        zsh|-zsh|bash|-bash|fish|-fish) printf 'shell\n' ;;
        *) printf '%s\n' "${1:-}" ;;
    esac
}

build_fallback_label() {
    local cmd_label repo_label
    cmd_label="$(normalize_command "$PANE_CMD")"
    repo_label="$(repo_name_from_path "$PANE_PATH" 2>/dev/null || printf '%s' "$PANE_PATH_BASE")"

    if [[ -z "$repo_label" ]]; then
        printf '%s\n' "$cmd_label"
        return
    fi

    if [[ "$cmd_label" == "shell" ]]; then
        printf '%s\n' "$repo_label"
    else
        printf '%s:%s\n' "$cmd_label" "$repo_label"
    fi
}

if title_is_noise "$PANE_TITLE"; then
    label="$(build_fallback_label)"
else
    label="$PANE_TITLE"
fi

max_len=$((PANE_WIDTH / 2))
if [[ ${#label} -gt $max_len ]]; then
    label="${label:0:$((max_len - 3))}..."
fi

printf '%s\n' "$label"
