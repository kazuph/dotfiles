---
name: slack-ask
description: |
  Slack経由でユーザーに質問や承認を求めるスキル。
  作業完了後の確認、今後の方針、追加作業の提案などをSlackチャンネルに投稿し、ユーザーからの返答を待機する。

  使用方法:
  Bash(run_in_background: true)で実行し、TaskOutputで結果を待つ
  ~/.claude/skills/slack-ask/scripts/ask.sh "質問文" "選択肢1" "選択肢2" ...
allowed-tools:
  - Bash
  - TaskOutput
---

# Slack質問・承認スキル

Slackを通じてユーザーに質問や承認を求め、返答を待機するスキルです。

## 前提条件

環境変数が設定されていること:
- `SLACK_BOT_TOKEN`: Slack Bot User OAuth Token
- `SLACK_CHANNEL` or `SLACK_CHANNEL_ID`: 投稿先のSlackチャンネルID

クレデンシャルは以下の優先順位で自動取得:
1. 環境変数
2. `~/dotfiles/claude/hooks/.env` / `~/.claude/hooks/.env`
3. macOS Keychain

## 実行手順

### 1. バックグラウンドでSlackに質問を投稿

Bashツールで `run_in_background: true` を指定して実行:

**質問する場合:**
```bash
~/.claude/skills/slack-ask/scripts/ask.sh "質問内容" "選択肢1" "選択肢2" ...
# or
~/.claude/skills/slack-ask/scripts/ask.sh "質問内容" "選択肢1,選択肢2"
```

**承認を求める場合:**
```bash
~/.claude/skills/slack-ask/scripts/approve.sh "タイトル" "詳細な説明"
```

**通知のみ（待機なし）:**
```bash
~/.claude/skills/slack-ask/scripts/notify.sh "メッセージ"
```

### 2. TaskOutputで返答を待機

TaskOutputツールを使用して結果を取得:
- `block: true`
- `timeout: 600000`（10分、必要に応じて繰り返し）

### 3. 返答を処理

JSON形式で返答が返る:
```json
{
  "success": true,
  "response": "ユーザーの返答テキスト",
  "user": "U12345678",
  "approved": true,
  "ts": "1234567890.123456",
  "channel": "C07UG7JRBHR"
}
```

## 使用例

```bash
# 実装方針の確認
~/.claude/skills/slack-ask/scripts/ask.sh \
  "DBはどれを使用しますか？" \
  "PostgreSQL" \
  "MySQL" \
  "SQLite"

# 続行確認
~/.claude/skills/slack-ask/scripts/ask.sh \
  "テストが3件失敗しました。続行しますか？" \
  "続行" \
  "中止"

# 本番デプロイの承認
~/.claude/skills/slack-ask/scripts/approve.sh \
  "本番デプロイ" \
  "v1.2.3をproductionにデプロイします"

# 通知のみ
~/.claude/skills/slack-ask/scripts/notify.sh "デプロイ完了しました"
```

## ファイル構成

```
~/.claude/skills/slack-ask/
├── SKILL.md
├── README.md
├── .env.example
└── scripts/
    ├── slack-approval.mjs    # 本体（ask/approve/notify）
    ├── ask.sh                # 質問スクリプト
    ├── approve.sh            # 承認リクエストスクリプト
    ├── notify.sh             # 通知スクリプト
    └── get-credentials.sh    # クレデンシャル取得
```
