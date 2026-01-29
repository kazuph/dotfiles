#!/bin/bash
set -euo pipefail

if [[ -z "${TMUX_PANE:-}" ]]; then
  echo "TMUX_PANE is not set" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"漢字と絵文字のラベル\"" >&2
  exit 2
fi

label="$1"
# 1階層のディレクトリ名を取得 (例: project)
current_dir=$(basename "$PWD")

tmux rename-window -t "$TMUX_PANE" "[${current_dir}] ${label}"
