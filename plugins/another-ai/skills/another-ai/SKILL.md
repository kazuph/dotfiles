---
name: another-ai
description: 追加のAIをTTY付きの素のCLIで実行するためのミニ手順。詳細は本文参照。
allowed-tools: Shell
---

# another-ai Skill

## ポイント
- **TTY必須**: `script -q /dev/null ...` でラップし、疑似TTYを確保する。
- **ラッパー不要**: any-script経由にせず、CLIを直接呼ぶ。
- **安全フラグ**: codexは信頼ディレクトリチェック回避のため `--skip-git-repo-check` を付ける。
- **出力抑制 + サンドボックス回避**: `--sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox` を毎回付け、`-o` で最終メッセージだけファイルに吐き `cat` で取り出す（エイリアス非依存・ログ抑制）。

## 実行例
- claude Code CLI（単純プロンプト出力）  
  ```bash
  script -q /dev/null claude --dangerously-skip-permissions --print "yes"
  ```
- codex（研究プレビューCLI・読み取り専用・最終メッセージのみ取得）
  ```bash
  outfile=$(mktemp -t codex)
  script -q /dev/null codex \
    --sandbox workspace-write \
    --config sandbox_workspace_write.network_access=true \
    --dangerously-bypass-approvals-and-sandbox \
    exec --skip-git-repo-check -o "$outfile" "hi" >/dev/null 2>&1
  cat "$outfile"
  ```
- codex（書き込み有効・ファイル変更を許可・最終メッセージのみ取得）
  ```bash
  outfile=$(mktemp -t codex)
  script -q /dev/null codex \
    --sandbox workspace-write \
    --config sandbox_workspace_write.network_access=true \
    --dangerously-bypass-approvals-and-sandbox \
    exec --skip-git-repo-check --full-auto -o "$outfile" "hi" >/dev/null 2>&1
  cat "$outfile"
  ```

## トラブルシュート
- `tcgetattr/ioctl: Operation not supported on socket` が出る場合、実行環境にTTYがない。`script -q /dev/null` で包んで再実行する。
- any-script経由で同エラーが出る場合は、直接上記コマンドで試す。
