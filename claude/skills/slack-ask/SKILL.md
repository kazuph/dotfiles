---
name: slack-ask
description: |
  AskUserQuestionの代替。Slack経由でユーザーに質問や承認を求める。
  ユーザーが離席中・外出中でもSlackで応答できる。

  質問: ask.sh "質問文" "選択肢1" "選択肢2" ...
  承認: approve.sh "タイトル" "詳細"（--meta でコンテキスト付与可）
  通知: notify.sh "メッセージ"

  実行方法: Bash(run_in_background: true) → TaskOutput(block: true)で待機
allowed-tools:
  - Bash
  - TaskOutput
---

# Slack質問・承認スキル（AskUserQuestion代替）

ユーザーがターミナルの前にいなくても、Slackで質問・承認・通知ができる。

## いつ使うか

- **AskUserQuestionの代わり**: 要件確認、方針選択、エラー対処等
- **承認フロー**: ai_guardの危険コマンド承認（自動連携済み）
- **完了通知**: 長時間タスクの完了報告

## 質問する（ask）

```bash
# バックグラウンドで実行
~/.claude/skills/slack-ask/scripts/ask.sh "質問内容" "選択肢1" "選択肢2" ...

# TaskOutputで待機
TaskOutput(task_id: "...", block: true, timeout: 600000)
```

**Slack側の応答方法:**
- 数字リアクション（1️⃣2️⃣3️⃣）で選択肢を選ぶ
- スレッド返信で自由記述

**レスポンス例:**
```json
{"success":true,"button":"option_1","response":"選択肢1","optionIndex":0}
```

## 承認を求める（approve）

```bash
# 基本
~/.claude/skills/slack-ask/scripts/approve.sh "タイトル" "詳細"

# コンテキスト付き（ai_guardから自動で呼ばれる）
node slack-approval.mjs --format shell --meta '{"cmd":"rm","dir":"/path","branch":"main"}' approve "タイトル" "詳細"
```

**Slack側の応答方法:**
- ✅ = 承認
- 3️⃣ = 3分承認
- ❌ = 却下
- スレッド返信 = 却下（内容が理由になる）

## 通知のみ（notify）

```bash
~/.claude/skills/slack-ask/scripts/notify.sh "デプロイ完了しました"
```

## 使用例

```bash
# 実装方針の確認（AskUserQuestion代替）
~/.claude/skills/slack-ask/scripts/ask.sh \
  "DBはどれを使用しますか？" \
  "PostgreSQL" "MySQL" "SQLite"

# 続行確認
~/.claude/skills/slack-ask/scripts/ask.sh \
  "テストが3件失敗しました。続行しますか？" \
  "続行" "中止"

# 承認リクエスト
~/.claude/skills/slack-ask/scripts/approve.sh \
  "本番デプロイ" "v1.2.3をproductionにデプロイします"
```
