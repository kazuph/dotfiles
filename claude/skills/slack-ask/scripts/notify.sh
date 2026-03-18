#!/bin/bash
# Slack通知スクリプト（返答を待たない）
# Usage: notify.sh "メッセージ"

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$SKILL_DIR/scripts/slack-approval.mjs"

source "$SKILL_DIR/scripts/get-credentials.sh"

if [ -z "${SLACK_BOT_TOKEN:-}" ] || [ -z "${SLACK_CHANNEL:-}" ]; then
    echo '{"success": false, "error": "SLACK_BOT_TOKEN and SLACK_CHANNEL are required"}'
    exit 1
fi

if [ -z "${1:-}" ]; then
    echo '{"success": false, "error": "Message is required"}'
    exit 1
fi

MESSAGE="$1"

exec node "$HELPER" notify "$MESSAGE"
