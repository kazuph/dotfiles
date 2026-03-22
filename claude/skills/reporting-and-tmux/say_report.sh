#!/bin/bash
set -euo pipefail

if [[ -z "${TMUX_PANE:-}" ]]; then
  echo "TMUX_PANE is not set" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"短いメッセージ\"" >&2
  exit 2
fi

message="$1"
win_id=$(tmux display-message -p -t "$TMUX_PANE" '#I')
rate=${SAY_RATE:-240}

say -r "$rate" "$win_id $message"
