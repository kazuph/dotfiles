---
name: pi
description: Agent OS V8アイソレート内でPi CLIを実行する。「/pi ファイルを読んで」「/pi hello.jsを作って」等で発動。隔離されたサンドボックス内でコーディングエージェントが安全に動作する。
argument-hint: "[prompt message]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
user-invocable: true
context: fork
---

# /pi — V8アイソレート内コーディングエージェント

V8サンドボックス内で https モジュールを使い Fireworks API を直接叩くコーディングエージェント。
ファイル操作・コマンド実行もすべてVM内で安全に実行。

## アーキテクチャ

- **V8 Isolate**: Rivet Agent OS によるサンドボックス環境
- **API**: https モジュールで Fireworks API を直接叩く（SSEストリーミング対応）
- **ツール**: read_file, write_file, list_directory, execute_command, search_text
- **通信**: stdin で設定を送信、stderr でストリーム表示、stdout でレスポンスJSON

## 使い方

### Claude Code スキルとして
```
/pi hello worldスクリプトを作って
/pi このディレクトリのファイル一覧を見せて
/pi hello.jsのバグを直して
```

### CLIツールとして
```bash
# 対話モード（REPL）
agent-os-pi [workspace-dir]

# ワンショット実行
agent-os-pi [workspace-dir] --message "hello.jsを作って"

# モデル指定
agent-os-pi . --model accounts/fireworks/models/llama-v3p3-70b-instruct -m "テスト書いて"
```

## 実行手順（Claude Codeが内部で実行）

### 1. 依存パッケージ確認
```bash
cd <SKILL_DIR> && npm install
```

### 2. APIキー取得
```bash
FIREWORKS_KEY=$(eval "$(direnv export bash 2>/dev/null)" && echo $FIREWORKS_API_KEY)
```
取得できない場合は `/tmp/.agent-os-fireworks-key` に保存して使う。

### 3. Agent 実行
```bash
cd <SKILL_DIR> && node agent-os-pi.mjs --cwd <TARGET_DIR> --message "<USER_PROMPT>"
```

### 4. レスポンスをユーザーに返す

## 設定

### モデル設定
デフォルト: `accounts/fireworks/models/llama-v3p3-70b-instruct`

`--model` フラグで変更可能。

## ファイル構成
- `agent-os-pi.mjs` — ホスト（VM管理、REPL、stdin/stdout制御）
- `vm-coding-agent.js` — VMエージェント（API呼び出し、ツール実行）
- `cli.mjs` — グローバルCLIラッパー

## 注意事項
- VM内ではネイティブバイナリ（Bun, Go等）は実行不可（Node.js/WASM のみ）
- `/workspace` にマウントされたファイルのみ読み書き可能
- ネットワークは https モジュール経由でアクセス可能
