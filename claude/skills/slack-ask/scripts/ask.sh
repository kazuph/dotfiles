#!/bin/bash
# Slack質問スクリプト
# Usage: ask.sh "質問内容" ["選択肢1,選択肢2"]

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="${CLAUDE_SLACK_BRIDGE_DIR:-$HOME/claude-slack-bridge}"

# クレデンシャル取得
source "$SKILL_DIR/scripts/get-credentials.sh"

if [ -z "$SLACK_BOT_TOKEN" ] || [ -z "$SLACK_CHANNEL" ]; then
    echo '{"success": false, "error": "SLACK_BOT_TOKEN and SLACK_CHANNEL are required"}' >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo '{"success": false, "error": "Question is required"}' >&2
    exit 1
fi

QUESTION="$1"
OPTIONS="$2"

if [ -n "$OPTIONS" ]; then
    npx --prefix "$SCRIPT_DIR" tsx "$SCRIPT_DIR/src/index.ts" ask "$QUESTION" --options "$OPTIONS"
else
    npx --prefix "$SCRIPT_DIR" tsx "$SCRIPT_DIR/src/index.ts" ask "$QUESTION"
fi
