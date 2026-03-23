#!/bin/bash
# Slack承認リクエストスクリプト
# Usage: approve.sh "タイトル" "詳細説明"

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$SKILL_DIR/scripts/slack-approval.mjs"

if [ -z "${1:-}" ]; then
    echo '{"success": false, "error": "Title is required"}'
    exit 1
fi

TITLE="$1"
DESCRIPTION="${2:-}"

exec node "$HELPER" approve "$TITLE" "$DESCRIPTION"
