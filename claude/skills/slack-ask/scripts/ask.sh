#!/bin/bash
# Slack質問スクリプト
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
    # Multiple arguments: join with comma
    OPTIONS_CSV="$(printf '%s\n' "$@" | paste -sd ',' -)"
elif [ "$#" -eq 1 ]; then
    # Single argument: already CSV or single option
    OPTIONS_CSV="$1"
fi

exec node "$HELPER" ask "$QUESTION" "$OPTIONS_CSV"
