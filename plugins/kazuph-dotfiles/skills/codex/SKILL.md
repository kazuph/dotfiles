---
name: codex
description: Codex CLI (GPT-5) を使って調査・実装・レビューを実行する。「codexで調べて」「codexに実装させて」「codexでレビュー」等で自動発動。
argument-hint: "[investigate|implement|review] [prompt or options]"
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
user-invocable: true
context: fork
---

# Codex Skill

Codex CLI を使って3種類のタスクを実行する統合スキル。

## 共通ルール

- **TTY必須**: 全コマンドを `script -q /dev/null` でラップ（ないと `tcgetattr` エラー）
- **モデル固定**: `exec` は `-m gpt-5.3-codex-spark`、`review` は `-c model="gpt-5.3-codex-spark"` を指定（reviewに `-m` フラグはない）
- **サンドボックス**: `--sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox`
- **出力抑制（exec系）**: `>/dev/null 2>&1` + `-o "$outfile"` で最終メッセージのみ取得（トークン節約）

## 共通プレフィックス

以下を `CODEX_BASE` として全コマンドに付ける:

```bash
CODEX_BASE="codex --sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox"
```

---

## 1. 調査 (investigate)

コードベースの調査・分析。読み取り専用（`--full-auto` なし）。

### コマンド

```bash
outfile=$(mktemp -t codex)
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  exec --skip-git-repo-check -m gpt-5.3-codex-spark -o "$outfile" \
  "<プロンプト>" >/dev/null 2>&1
cat "$outfile"
```

### ディレクトリ指定あり

```bash
outfile=$(mktemp -t codex)
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  exec --skip-git-repo-check -m gpt-5.3-codex-spark -C /path/to/dir -o "$outfile" \
  "<プロンプト>" >/dev/null 2>&1
cat "$outfile"
```

### ポイント

- `--full-auto` を付けない → ファイル変更なし
- 調査プロンプトには「ファイルの変更は行わないでください」を明記

---

## 2. 実装 (implement)

コードの実装・修正。書き込み有効（`--full-auto` 付き）。

### コマンド

```bash
outfile=$(mktemp -t codex)
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  exec --skip-git-repo-check --full-auto -m gpt-5.3-codex-spark -o "$outfile" \
  "<プロンプト>" >/dev/null 2>&1
cat "$outfile"
```

### ディレクトリ指定あり

```bash
outfile=$(mktemp -t codex)
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  exec --skip-git-repo-check --full-auto -m gpt-5.3-codex-spark -C /path/to/dir -o "$outfile" \
  "<プロンプト>" >/dev/null 2>&1
cat "$outfile"
```

### ポイント

- `--full-auto` でファイル作成・編集・削除を許可
- 実行前にユーザーに方針確認、実行後に `git diff` で変更確認
- タイムアウト: 長いタスクは `timeout 600` でガード

---

## 3. レビュー (review)

コードレビュー。`codex review` サブコマンドを使用。

### 未コミット変更のレビュー

```bash
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  review --uncommitted -c model="gpt-5.3-codex-spark" 2>&1
```

### ブランチ差分のレビュー

```bash
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  review --base develop -c model="gpt-5.3-codex-spark" 2>&1
```

### 特定コミットのレビュー

```bash
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  review --commit <SHA> -c model="gpt-5.3-codex-spark" 2>&1
```

### カスタム観点でレビュー

```bash
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  review --uncommitted -m gpt-5.3-codex-spark \
  "セキュリティ観点でレビュー。XSS、SQLi、認証バイパスを重点確認" 2>&1
```

### ディレクトリ指定あり

```bash
script -q /dev/null codex \
  --sandbox workspace-write \
  --config sandbox_workspace_write.network_access=true \
  --dangerously-bypass-approvals-and-sandbox \
  -C /path/to/dir \
  review --base develop -c model="gpt-5.3-codex-spark" 2>&1
```

### ポイント

- `exec` ではなく `review` サブコマンドを使う
- review は読み取り専用（コード変更なし）
- 出力はレビューコメントそのものなので `-o` 不要、`2>&1` で直接取得
- **ソース指定（`--uncommitted` / `--base` / `--commit`）はカスタムプロンプトと併用不可**。カスタム観点でレビューする場合はソース指定なしで `[PROMPT]` のみ渡す
- モデル指定は `-c model="gpt-5.3-codex-spark"`（`-m` フラグは `review` サブコマンドにはない）

---

## 引数パターン

| 呼び出し | 動作 |
|---------|------|
| `/codex investigate <prompt>` | 読み取り調査 |
| `/codex implement <prompt>` | 書き込み実装 |
| `/codex review` | 未コミット変更レビュー |
| `/codex review --base develop` | ブランチ差分レビュー |

引数の最初の語が `investigate` / `implement` / `review` でモードを判別する。

## トラブルシューティング

- **TTYエラー**: `script -q /dev/null` を付け忘れていないか
- **Codex unreachable**: `codex --version` で CLI 確認
- **タイムアウト**: スコープを絞って再実行
- **意図しない変更（implement）**: `git checkout -- .` でリセット（確認後）
