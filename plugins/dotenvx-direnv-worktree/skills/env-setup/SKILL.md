---
name: env-setup
description: Set up secure environment variable management using dotenvx + direnv + git worktree. Use when user asks to set up env management, wants to encrypt .env files, or needs to configure environment variables for worktree-based development. Also use when setting up a new project that needs secure env handling.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
user-invocable: true
---

# Environment Setup Skill (dotenvx + direnv + worktree)

Git worktreeを使った並列開発で、環境変数を安全かつ効率的に管理する環境をセットアップします。

## Core Principle

**暗号化は常時維持**: ディスク上は暗号化、メモリ上のみ復号。復号されたファイルが作られることはない。

```
ディスク上          メモリ上（実行時のみ）
┌─────────────┐     ┌─────────────┐
│ .env        │     │ DATABASE_URL=xxx │
│ (暗号化)    │ ──→ │ API_KEY=yyy      │
│ xxxxxxxxxx  │     │ (復号済み)       │
└─────────────┘     └─────────────────┘
     ↑                    ↑
  常にこの状態        プロセス実行中のみ
```

## Tool Stack

| ツール | 役割 | インストール |
|--------|------|-------------|
| **gwq** | Git worktree管理、fuzzy finder | `go install github.com/d-kuro/gwq@latest` |
| **direnv** | ディレクトリ単位で環境変数を自動読み込み | `brew install direnv` |
| **dotenvx** | .envファイルの暗号化管理 | `npm install -g @dotenvx/dotenvx` |

## Setup Instructions

以下の手順で環境をセットアップしてください。

### Step 1: Check Prerequisites

まず必要なツールがインストールされているか確認:

```bash
# Check direnv
which direnv || echo "direnv not installed"

# Check dotenvx
which dotenvx || npm list -g @dotenvx/dotenvx || echo "dotenvx not installed"

# Check gwq (optional but recommended)
which gwq || echo "gwq not installed (optional)"
```

インストールされていない場合は、ユーザーに案内してインストールを促す。

### Step 2: Create/Encrypt .env File

既存の.envがあれば暗号化、なければサンプルを作成:

```bash
# If .env exists
dotenvx encrypt

# The .env.keys file will be generated with DOTENV_PRIVATE_KEY
# Extract the key for .envrc
```

### Step 3: Create .envrc

以下の内容で.envrcを作成:

```bash
# .envrc
export DOTENV_PRIVATE_KEY="<key from .env.keys>"
eval "$(dotenvx decrypt --stdout --format shell)"
```

**重要**: .env.keysからDOTENV_PRIVATE_KEYの値を転記後、.env.keysは削除可能。

### Step 4: Update .gitignore

以下を.gitignoreに追加（未追加の場合）:

```
.worktree
.artifacts
.envrc
.env.keys
```

### Step 5: Activate direnv

```bash
direnv allow
```

### Step 6: (Optional) Configure gwq

~/.config/gwq/config.toml を確認/作成:

```toml
[worktree]
basedir = ".worktree"  # プロジェクト内に配置（direnv継承のため）

[[repository_settings]]
repository = "*"
copy_files = []  # direnv + dotenvxならコピー不要
setup_commands = ["npm install || pnpm install || true", "direnv allow"]
```

## Multi-Environment Setup

複数環境を管理する場合:

### Encrypt Each Environment

```bash
dotenvx encrypt -f .env.development
dotenvx encrypt -f .env.staging
dotenvx encrypt -f .env.production
```

### Enhanced .envrc for Multiple Environments

```bash
# .envrc
export DOTENV_PRIVATE_KEY_DEVELOPMENT="xxx"
export DOTENV_PRIVATE_KEY_STAGING="yyy"
# DOTENV_PRIVATE_KEY_PRODUCTION は開発者には渡さない

# APP_ENVに応じて読み込む環境を決定
ENV_FILE=".env.${APP_ENV:-development}"

if [[ -f "$ENV_FILE" ]]; then
  eval "$(dotenvx decrypt -f "$ENV_FILE" --stdout --format shell)"
fi
```

## CI/CD Integration

GitHub Actions example:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        env:
          DOTENV_PRIVATE_KEY: ${{ secrets.DOTENV_PRIVATE_KEY }}
        run: npx dotenvx run -- npm test
```

## Command Reference

### dotenvx

| コマンド | 説明 |
|---------|------|
| `dotenvx encrypt` | .envを暗号化 |
| `dotenvx encrypt -f .env.production` | 特定ファイルを暗号化 |
| `dotenvx decrypt --stdout` | 復号して標準出力 |
| `dotenvx decrypt --stdout --format shell` | シェル形式で出力 |
| `dotenvx set KEY="value"` | 変数を追加/更新（自動再暗号化） |
| `dotenvx get KEY` | 変数の値を取得 |
| `dotenvx run -- <command>` | 環境変数を注入してコマンド実行 |

### gwq

| コマンド | 説明 |
|---------|------|
| `gwq add -b <branch>` | worktree作成 |
| `gwq list` | worktree一覧（fuzzy finder） |

### direnv

| コマンド | 説明 |
|---------|------|
| `direnv allow` | .envrcを許可 |
| `direnv reload` | 再読み込み |

## Worktree Behavior

worktreeでも自動で動作する理由:

1. `.worktree/` はプロジェクト内のサブディレクトリ
2. direnvは親ディレクトリの `.envrc` を自動継承
3. `.env` はgit管理なのでworktreeにも存在
4. 結果、worktreeでも自動で復号される

### Modifying .env in Worktree

```bash
cd .worktree/feature-x/

# 環境変数を追加/変更（自動で再暗号化される）
dotenvx set NEW_API_KEY="xxx"

# コミット
git add .env
git commit -m "feat: add NEW_API_KEY"
```

**重要**: `dotenvx set` は自動で再暗号化。.envを直接編集しない。

## Benefits Summary

| 項目 | 効果 |
|------|------|
| セキュリティ | .envは常に暗号化、ディスク上に平文なし |
| git管理 | 暗号化済み.envをコミット可能 |
| チーム共有 | 鍵だけ共有すれば即動作 |
| worktree | 親の.envrcを自動継承、設定不要 |
| CI/CD | シークレット1つで全環境変数を管理 |
| 権限分離 | 環境ごとに鍵を分けて権限制御可能 |

## Execution Flow

このスキルを実行する際:

1. **現状確認**: 既存の.env, .envrc, .gitignoreを確認
2. **ツール確認**: direnv, dotenvxのインストール状態を確認
3. **セットアップ実行**: Step 1-6を順番に実行
4. **検証**: `direnv allow`後、環境変数が読み込まれるか確認

ユーザーに確認が必要な場合（既存ファイルの上書きなど）は必ず確認を取る。
