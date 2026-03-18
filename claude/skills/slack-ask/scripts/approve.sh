#!/bin/bash
# Slack承認リクエストスクリプト
# Usage: approve.sh "タイトル" "詳細説明"

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$SKILL_DIR/scripts/slack-approval.mjs"

source "$SKILL_DIR/scripts/get-credentials.sh"

if [ -z "${SLACK_BOT_TOKEN:-}" ] || [ -z "${SLACK_CHANNEL:-}" ]; then
    echo '{"success": false, "error": "SLACK_BOT_TOKEN and SLACK_CHANNEL are required"}'
    exit 1
fi

if [ -z "${1:-}" ]; then
    echo '{"success": false, "error": "Title is required"}'
    exit 1
fi

TITLE="$1"
DESCRIPTION="${2:-}"

exec node "$HELPER" approve "$TITLE" "$DESCRIPTION"
