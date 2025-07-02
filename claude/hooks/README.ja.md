# Claude Code Hooks

## stop-send-notification.js

Claudeがメッセージ生成を停止した時にmacOS通知を送るフック。

### 設定

`~/.claude/settings.json` に以下を追加:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/stop-send-notification.js"
          }
        ]
      }
    ]
  }
}
```

### インストール

1. `stop-send-notification.js` を `~/.claude/hooks/` に配置
2. 実行権限を付与: `chmod +x ~/.claude/hooks/stop-send-notification.js`

### 機能

- Claudeの最後のメッセージをmacOS通知で表示
- tmux使用時はウィンドウとペイン番号も表示（例: `Claude Code - [1-0] Initial Greeting`）
- 改行を自動的にスペースに変換し、最大235文字で切り詰め
- セキュリティ: `~/.claude/projects/` 内のファイルのみ読み取り可能

