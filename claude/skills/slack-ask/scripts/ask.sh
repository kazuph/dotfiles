#!/bin/bash
# Slack質問スクリプト（自動コンテキスト収集付き）
# Usage: ask.sh "質問内容" "選択肢1" "選択肢2" ...
#    or: ask.sh "質問内容" "選択肢1,選択肢2"

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$SKILL_DIR/scripts/slack-approval.mjs"

QUESTION="${1:-}"
if [ -z "$QUESTION" ]; then
    echo '{"success": false, "error": "Question is required"}'
    exit 1
fi
shift || true

OPTIONS_CSV=""
if [ "$#" -gt 1 ]; then
    OPTIONS_CSV="$(printf '%s\n' "$@" | paste -sd ',' -)"
elif [ "$#" -eq 1 ]; then
    OPTIONS_CSV="$1"
fi

# Auto-collect context meta
_dir="$(pwd -P 2>/dev/null || pwd)"
_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || _branch=""
_repo=$(git rev-parse --show-toplevel 2>/dev/null) || _repo=""
[ -n "$_repo" ] && _repo="${_repo##*/}"
_process=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d '\n') || _process=""
_tmux=""
if [ -n "${TMUX_PANE:-}" ]; then
    _tw=$(tmux display-message -p -t "${TMUX_PANE}" '#{window_name}' 2>/dev/null | tr -d '\n') || _tw=""
    _tp=$(tmux display-message -p -t "${TMUX_PANE}" '#{pane_title}' 2>/dev/null | tr -d '\n') || _tp=""
    [ -n "$_tw" ] || [ -n "$_tp" ] && _tmux="${_tw:-?}:${_tp:-?}"
fi

_meta=$(printf '{"dir":"%s","branch":"%s","repo":"%s","process":"%s","tmux":"%s"}' \
    "$_dir" "$_branch" "$_repo" "$_process" "$_tmux")

# Output meta+args as JSON for caller to use, then exec node directly
# Note: ai_guard may intercept 'node' in bash; if so, caller should use
# node directly from non-bash context (e.g. Claude Code's Bash tool)
exec node "$HELPER" --meta "$_meta" ask "$QUESTION" "$OPTIONS_CSV"
