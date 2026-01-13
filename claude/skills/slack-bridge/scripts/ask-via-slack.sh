#!/bin/bash
# Slack経由で質問し、回答を待つスクリプト（Long-polling版）
# Usage: ask-via-slack.sh "質問文" "選択肢1" "選択肢2" ...

set -e

SERVER_DIR="$HOME/.claude/skills/slack-bridge"
SERVER_PORT=3847

# サーバーが起動していなければ起動
if ! curl -s "http://localhost:$SERVER_PORT/health" > /dev/null 2>&1; then
  echo "Starting Slack bridge server..." >&2
  cd "$SERVER_DIR" && node server.js > /tmp/claude-slack-bridge.log 2>&1 &
  # 起動を待つ
  for i in {1..10}; do
    sleep 0.5
    if curl -s "http://localhost:$SERVER_PORT/health" > /dev/null 2>&1; then
      break
    fi
  done
fi

# 引数から質問と選択肢を取得
QUESTION="$1"
shift
OPTIONS=()
while [[ $# -gt 0 ]]; do
  OPTIONS+=("$1")
  shift
done

# ユニークなIDを生成
QUESTION_ID="q_$(date +%s)_$$"

# セッション情報を取得（tmux pane名 or PWD）
if [ -n "$TMUX_PANE" ]; then
  SESSION_INFO=$(tmux display-message -p '#S:#W' 2>/dev/null || basename "$PWD")
  # pane IDだけでなく、session:window.pane の完全なターゲットを取得
  PANE_ID=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null || echo "$TMUX_PANE")
else
  SESSION_INFO=$(basename "$PWD")
  PANE_ID=""
fi

# オプションをJSON配列に変換
OPTIONS_JSON="[]"
for opt in "${OPTIONS[@]}"; do
  OPTIONS_JSON=$(echo "$OPTIONS_JSON" | jq --arg label "$opt" '. + [{"label": $label}]')
done

# ペイロード作成
PAYLOAD=$(jq -n \
  --arg questionId "$QUESTION_ID" \
  --arg question "$QUESTION" \
  --arg sessionInfo "$SESSION_INFO" \
  --arg paneId "$PANE_ID" \
  --argjson options "$OPTIONS_JSON" \
  '{
    questionId: $questionId,
    questions: [{
      question: $question,
      header: "Claude Code",
      options: $options
    }],
    sessionInfo: $sessionInfo,
    paneId: $paneId
  }')

# Long-polling: サーバーに質問を送信し、回答が来るまで待つ（最大10分）
RESPONSE=$(curl -s -X POST "http://localhost:$SERVER_PORT/ask-and-wait" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  --max-time 610)

# エラーチェック
if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error // .message // "Unknown error"')
  echo "Error: $ERROR" >&2
  exit 1
fi

# 回答を出力
echo "$RESPONSE"
