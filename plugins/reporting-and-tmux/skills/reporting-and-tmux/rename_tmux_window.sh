#!/bin/bash
set -euo pipefail

if [[ -z "${TMUX_PANE:-}" ]]; then
  echo "TMUX_PANE is not set" >&2
  exit 1
fi

# 1階層のディレクトリ名を取得 (例: project)
current_dir="$(basename "${PWD}")"
if [[ -z "$current_dir" || "$current_dir" == "/" ]]; then
  current_dir="window"
fi

tmux rename-window -t "$TMUX_PANE" "$current_dir"
