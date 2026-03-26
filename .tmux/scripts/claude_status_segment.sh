#!/bin/bash
set -euo pipefail

get_resurrect_dir() {
    local configured host_name
    configured="$(tmux show-option -gqv @resurrect-dir 2>/dev/null || true)"
    host_name="$(hostname 2>/dev/null || true)"

    if [[ -n "$configured" ]]; then
        configured="${configured//\$HOME/$HOME}"
        configured="${configured//\$HOSTNAME/$host_name}"
        configured="${configured/#\~/$HOME}"
        printf '%s\n' "$configured"
        return
    fi

    if [[ -d "$HOME/.tmux/resurrect" ]]; then
        printf '%s\n' "$HOME/.tmux/resurrect"
    else
        printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
    fi
}

list_ai_windows() {
    tmux list-panes -a -F '#{window_index}|#{pane_current_command}|#{pane_title}' 2>/dev/null |
        while IFS='|' read -r window_index pane_command pane_title; do
            if [[ "$pane_command" == codex* ]]; then
                printf '%s\n' "$window_index"
                continue
            fi

            if [[ "$pane_title" =~ ^[⠁-⣿✳] ]] || [[ "$pane_title" == *"Claude Code"* ]] || [[ "$pane_title" == *"Execute "* ]]; then
                printf '%s\n' "$window_index"
            fi
        done |
        sort -n -u |
        paste -sd, -
}

last_save_segment() {
    local resurrect_dir last_link save_file save_time
    resurrect_dir="$(get_resurrect_dir)"
    last_link="$resurrect_dir/last"

    if [[ ! -L "$last_link" ]]; then
        return
    fi

    save_file="$(readlink "$last_link")"
    [[ "$save_file" == /* ]] || save_file="$resurrect_dir/$save_file"
    [[ -f "$save_file" ]] || return

    save_time="$(stat -f '%Sm' -t '%H:%M' "$save_file" 2>/dev/null || true)"
    [[ -n "$save_time" ]] || return

    printf '#[fg=#60785a]Save[%s]#[default]' "$save_time"
}

main() {
    local ai_windows save_segment
    ai_windows="$(list_ai_windows)"
    save_segment="$(last_save_segment)"

    if [[ -n "$ai_windows" ]]; then
        printf '#[fg=#b8f171,bold]AI[%s]#[default]' "$ai_windows"
        if [[ -n "$save_segment" ]]; then
            printf ' '
        fi
    fi

    if [[ -n "$save_segment" ]]; then
        printf '%s' "$save_segment"
    fi
}

main
