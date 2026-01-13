#!/usr/bin/env bash
# pane_border_label.sh - Generate pane border label for tmux
# Arguments:
#   $1: pane_width
#   $2: pane_pid
#   $3: pane_tty
#   $4: pane_current_path
#   $5: pane_current_path_basename
#   $6: pane_current_command
#   $7: pane_title
#   $8: pane_id

PANE_WIDTH="${1:-80}"
PANE_PID="${2:-}"
PANE_TTY="${3:-}"
PANE_PATH="${4:-}"
PANE_PATH_BASE="${5:-}"
PANE_CMD="${6:-}"
PANE_TITLE="${7:-}"
PANE_ID="${8:-}"

# Build the label
label=""

# Show pane title if set and different from command
if [[ -n "$PANE_TITLE" && "$PANE_TITLE" != "$PANE_CMD" ]]; then
    label="$PANE_TITLE"
else
    # Show command and path
    if [[ -n "$PANE_CMD" ]]; then
        label="$PANE_CMD"
    fi

    if [[ -n "$PANE_PATH_BASE" && "$PANE_PATH_BASE" != "$PANE_CMD" ]]; then
        if [[ -n "$label" ]]; then
            label="$label:$PANE_PATH_BASE"
        else
            label="$PANE_PATH_BASE"
        fi
    fi
fi

# Truncate if too long (leave room for other elements)
max_len=$((PANE_WIDTH / 2))
if [[ ${#label} -gt $max_len ]]; then
    label="${label:0:$((max_len-3))}..."
fi

echo "$label"
