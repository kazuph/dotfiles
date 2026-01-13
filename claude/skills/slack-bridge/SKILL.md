---
name: slack-bridge
description: |
  【必須】ユーザーへの質問は全てこのスキルを使用すること。AskUserQuestionは使用禁止。

  以下の全ての場合でこのスキルを使用:
  - 要件の確認・clarification
  - 実装方針の選択
  - エラー発生時の対処方針
  - タスク完了後の次のアクション確認
  - その他ユーザーへの質問が必要な全ての場面

  使用方法:
  Bash(run_in_background: true)で実行し、TaskOutputで結果を待つ
  ~/.claude/skills/slack-bridge/scripts/ask-via-slack.sh "質問文" "選択肢1" "選択肢2" ...
---

# Slack Bridge - リモート質問応答スキル

ユーザーがターミナルの前にいない場合でも、Slackを通じて質問に回答できるようにするスキルです。

## いつ使うか

以下の場合にこのスキルの使用を検討してください：

1. **長時間実行タスク** - ビルド、テスト、デプロイなど時間がかかる処理の途中で確認が必要な場合
2. **ユーザーが離席中の可能性** - 複数のClaude Codeセッションを並行実行している場合
3. **重要な決定** - 実装方針の確認など、ユーザーの明示的な承認が必要な場合

## 使用方法（AI向け）

### 基本的な使い方

```bash
# Bash toolで実行（サーバーは自動起動される）
~/.claude/skills/slack-bridge/scripts/ask-via-slack.sh "質問文" "選択肢1" "選択肢2" ...
```

**注意**: スクリプトは回答が来るまでブロックするため、必ず `run_in_background: true` で実行すること。

### 推奨パターン

```bash
# 1. バックグラウンドで質問を送信
Bash(run_in_background: true):
  ~/.claude/skills/slack-bridge/scripts/ask-via-slack.sh \
    "認証方式はどちらを使用しますか？" \
    "JWT" \
    "Session" \
    "OAuth"

# 2. TaskOutputで回答を待つ
TaskOutput(task_id: "...", block: true, timeout: 600000)

# 3. 回答を解析して処理を続行
# {"answer":"JWT","optionIndex":0,"timestamp":...}
```

### 使用例

```bash
# 実装方針の確認
~/.claude/skills/slack-bridge/scripts/ask-via-slack.sh \
  "DBはどれを使用しますか？" \
  "PostgreSQL" \
  "MySQL" \
  "SQLite"

# 続行確認
~/.claude/skills/slack-bridge/scripts/ask-via-slack.sh \
  "テストが3件失敗しました。続行しますか？" \
  "続行" \
  "中止"

# エラー対処方針
~/.claude/skills/slack-bridge/scripts/ask-via-slack.sh \
  "型エラーが見つかりました。どう対処しますか？" \
  "修正して続行" \
  "無視して続行" \
  "中止"
```

### 戻り値

JSON形式で回答が返されます：

```json
{"answer":"選択肢1","optionIndex":0,"timestamp":1234567890}
```

## Decision Tree

```
ユーザーへの質問が必要
    │
    ├─ ユーザーがターミナルの前にいる（確実）
    │   └─ AskUserQuestion を使用
    │
    └─ ユーザーが離席中 or 不明 or 長時間タスク
        └─ このスキル（slack-bridge）を使用
            │
            └─ Bash(run_in_background: true) でスクリプト実行
                └─ TaskOutput で結果を取得
```

## 技術詳細

- **サーバー自動起動**: スクリプト実行時にサーバーが停止していれば自動で起動
- **Long-polling**: ファイル不要。HTTPリクエストで回答を待機
- **タイムアウト**: 10分（600秒）で自動タイムアウト
- **自動フォーカス**: 回答後、Ghosttyがアクティブになり該当tmux paneに切り替わる
- **セッション識別**: Slackメッセージにtmux session:window名が表示される

## ファイル構成

```
~/.claude/skills/slack-bridge/
├── SKILL.md                    # このファイル
├── server.js                   # HTTPサーバー（自動起動）
├── .env                        # Slack認証情報
├── package.json
└── scripts/
    └── ask-via-slack.sh        # 質問送信スクリプト
```

## Tailscale Funnel

Slackからのwebhookを受け取るため、Tailscale Funnelが必要です：

```bash
# 有効化（初回のみ）
tailscale funnel 3847
```

SlackアプリのInteractivity Request URL: `https://kazuhironomacbook-air.tail5f04b.ts.net/slack/interactions`
