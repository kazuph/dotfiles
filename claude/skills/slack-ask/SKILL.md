---
name: slack-ask
description: Slackを通じてユーザーに質問や承認を求めるスキル。作業完了後の確認、今後の方針、追加作業の提案などをSlackチャンネルに投稿し、ユーザーからの返答を無限に待機する。「Slackで聞いて」「Slackで承認を取って」「Slack経由で質問」と言われた時に使用。
allowed-tools:
  - Bash
  - TaskOutput
---

# Slack質問・承認スキル

Slackを通じてユーザーに質問や承認を求め、返答を無限に待機するスキルです。

## 前提条件

環境変数が設定されていること：
- `SLACK_BOT_TOKEN`: Slack Bot User OAuth Token
- `SLACK_CHANNEL`: 投稿先のSlackチャンネルID

**セキュリティ**: トークンはKeychainまたはセキュアストレージから取得することを推奨。
詳細は[README.md](./README.md)を参照。

## 実行手順

### 1. バックグラウンドでSlackに質問を投稿

Bashツールで`run_in_background: true`を指定して実行：

**質問する場合：**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/slack-ask/scripts/ask.sh "質問内容" "選択肢1,選択肢2"
```

**承認を求める場合：**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/slack-ask/scripts/approve.sh "タイトル" "詳細な説明"
```

**通知のみ（待機なし）：**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/slack-ask/scripts/notify.sh "メッセージ"
```

### 2. TaskOutputで返答を待機

TaskOutputツールを使用して結果を取得：
- `block: true`
- `timeout: 600000`（10分、必要に応じて繰り返し）

### 3. 返答を処理

JSON形式で返答が返る：
```json
{
  "success": true,
  "response": "ユーザーの返答テキスト",
  "user": "U12345678",
  "approved": true
}
```

`approved`は返答に「yes」「ok」「lgtm」「承認」「はい」などが含まれる場合にtrue。

## 使用例

作業完了後の確認：
```bash
${CLAUDE_PLUGIN_ROOT}/skills/slack-ask/scripts/ask.sh "実装が完了しました。次に何をしますか？" "テスト実行,PRを作成,別のタスクに着手"
```

本番デプロイの承認：
```bash
${CLAUDE_PLUGIN_ROOT}/skills/slack-ask/scripts/approve.sh "本番デプロイ" "v1.2.3をproductionにデプロイします"
```
