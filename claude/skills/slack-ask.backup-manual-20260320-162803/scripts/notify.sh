#!/bin/bash
# Slack通知スクリプト（返答を待たない）
# Usage: notify.sh "メッセージ"

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$SKILL_DIR/scripts/slack-approval.mjs"

if [ -z "${1:-}" ]; then
    echo '{"success": false, "error": "Message is required"}'
    exit 1
fi

MESSAGE="$1"

exec node "$HELPER" notify "$MESSAGE"
