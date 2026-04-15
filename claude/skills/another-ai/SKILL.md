---
name: another-ai
description: 追加のAIをTTY付きの素のCLIで実行するためのミニ手順。詳細は本文参照。
allowed-tools: Shell
---

# another-ai Skill

## ポイント
- **TTY不要**: `exec`/ワンショットモードでは `script -q /dev/null` ラッパー不要。直接叩く。
- **ラッパー不要**: any-script経由にせず、CLIを直接呼ぶ。
- **安全フラグ**: codexは信頼ディレクトリチェック回避のため `--skip-git-repo-check` を付ける。
- **出力抑制 + サンドボックス回避**: codexは `--sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox` を毎回付け、`-o` で最終メッセージだけファイルに吐き `cat` で取り出す。geminiは `-o json | jq -r '.response'` で最終応答のみ抽出。
- **エイリアス回避**: `command codex` でzshエイリアスをバイパスする（フラグ重複回避）。

## 実行例
- Claude Code CLI（単純プロンプト出力）
  ```bash
  CLAUDECODE= command claude --dangerously-skip-permissions --print "yes"
  ```
  ※ `CLAUDECODE=` はClaude Codeセッション内から呼ぶ場合に必須（ネスト検出バイパス）。
- Codex（読み取り専用・最終メッセージのみ取得）
  ```bash
  outfile=$(mktemp -t codex)
  command codex \
    --sandbox workspace-write \
    --config sandbox_workspace_write.network_access=true \
    --dangerously-bypass-approvals-and-sandbox \
    exec --skip-git-repo-check -o "$outfile" "hi" >/dev/null 2>&1
  cat "$outfile"
  ```
- Codex（書き込み有効・ファイル変更を許可・最終メッセージのみ取得）
  ```bash
  outfile=$(mktemp -t codex)
  command codex \
    --sandbox workspace-write \
    --config sandbox_workspace_write.network_access=true \
    --dangerously-bypass-approvals-and-sandbox \
    exec --skip-git-repo-check --full-auto -o "$outfile" "hi" >/dev/null 2>&1
  cat "$outfile"
  ```
- Gemini（最終応答のみ取得）
  ```bash
  /opt/homebrew/bin/mise exec -- gemini --approval-mode=yolo -o json "hi" 2>/dev/null \
    | jq -r '.response'
  ```

## トラブルシュート
- `tcgetattr/ioctl: Operation not supported on socket` が出る場合、インタラクティブモードを使っている可能性がある。`exec` モード（codex）やワンショットモード（gemini）に切り替える。それでも出る場合のみ `script -q /dev/null` でラップ。
- any-script経由で同エラーが出る場合は、直接上記コマンドで試す。
