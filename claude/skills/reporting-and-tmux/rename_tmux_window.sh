#!/bin/bash
set -euo pipefail

if [[ -z "${TMUX_PANE:-}" ]]; then
  echo "TMUX_PANE is not set" >&2
  exit 1
fi

# ai_guardのシェル関数ラッパーを回避するため絶対パスで呼ぶ
GIT_BIN="${GIT_BIN:-$(unset -f git 2>/dev/null; type -P git 2>/dev/null || echo /usr/bin/git)}"

# リポジトリ名: git-common-dirから本体リポジトリを特定（worktree対応）
if common_dir="$("$GIT_BIN" rev-parse --git-common-dir 2>/dev/null)"; then
  # 絶対パスに変換
  if [[ "$common_dir" != /* ]]; then
    common_dir="$(cd "$common_dir" && pwd)"
  fi
  # .git を取り除いてリポジトリルートのbasenameを取得
  repo_name="$(basename "$(dirname "$common_dir")")"
else
  repo_name="$(basename "${PWD}")"
fi

if [[ -z "$repo_name" || "$repo_name" == "/" ]]; then
  repo_name="window"
fi

# 引数があれば「リポジトリ名-タスク概要」、なければリポジトリ名のみ
if [[ $# -ge 1 && -n "$1" ]]; then
  window_name="${repo_name}-${1}"
else
  window_name="$repo_name"
fi

tmux rename-window -t "$TMUX_PANE" "$window_name"
