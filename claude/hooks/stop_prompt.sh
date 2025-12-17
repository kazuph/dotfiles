#!/bin/bash

# Stop hook: return instructions as JSON to satisfy hook runner expectations
MSG=$(cat <<'EOF'
タスク完了報告手順:
1. tmux display-message -p -t "$TMUX_PANE" '#I' でウィンドウID取得
2. 今回のタスク内容を30文字以内で要約
3. say -r 230 "Window <ID> <要約>" をバックグラウンドで実行
4. ~/.claude/skills/reporting-and-tmux/rename_tmux_window.sh "<漢字+絵文字>" を実行
EOF
)

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "stopMessage": "${MSG//$'\n'/\\n}"
  }
}
EOF
