#!/bin/bash
# Slack通知スクリプト（返答を待たない）
# Usage: notify.sh "メッセージ"

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="${CLAUDE_SLACK_BRIDGE_DIR:-$HOME/claude-slack-bridge}"

# クレデンシャル取得
source "$SKILL_DIR/scripts/get-credentials.sh"

if [ -z "$SLACK_BOT_TOKEN" ] || [ -z "$SLACK_CHANNEL" ]; then
    echo '{"success": false, "error": "SLACK_BOT_TOKEN and SLACK_CHANNEL are required"}' >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo '{"success": false, "error": "Message is required"}' >&2
    exit 1
fi

MESSAGE="$1"

npx --prefix "$SCRIPT_DIR" tsx "$SCRIPT_DIR/src/index.ts" notify "$MESSAGE"
