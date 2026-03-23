# Slack Ask Skill

Claude Codeからの質問・承認をSlackで受け付け、ユーザーからの返答を無限に待機するスキルです。

## セットアップ

### 1. Slack Appの作成

1. [Slack API](https://api.slack.com/apps) → "Create New App" → "From scratch"
2. OAuth & Permissions で以下のスコープを追加:
   - `chat:write` - メッセージ送信
   - `channels:history` - パブリックチャンネル履歴
   - `groups:history` - プライベートチャンネル用
3. "Install to Workspace" → Bot User OAuth Tokenをコピー
4. Botをチャンネルに招待: `/invite @YourBotName`

### 2. クレデンシャルの設定（推奨順）

#### 方法1: macOS Keychain（推奨）

```bash
# トークンを保存
security add-generic-password -a claude-slack -s SLACK_BOT_TOKEN -w "xoxb-your-token"
security add-generic-password -a claude-slack -s SLACK_CHANNEL -w "C1234567890"
```

#### 方法2: Linux pass (password-store)

```bash
pass insert claude/slack-bot-token
pass insert claude/slack-channel
```

#### 方法3: Termux (Android)

```bash
mkdir -p ~/.config/claude-slack
cat > ~/.config/claude-slack/credentials << 'EOF'
SLACK_BOT_TOKEN="xoxb-your-token"
SLACK_CHANNEL="C1234567890"
EOF
chmod 600 ~/.config/claude-slack/credentials
```

#### 方法4: 環境変数（シンプルだが非推奨）

```bash
# ~/.zshrc に追加
export SLACK_BOT_TOKEN="xoxb-your-token"
export SLACK_CHANNEL="C1234567890"
```

### 3. 既存クレデンシャルの再利用

この実装は以下を自動で探索します。

- `~/dotfiles/claude/hooks/.env`
- `~/.claude/hooks/.env`
- macOS Keychain の `SLACK_BOT_TOKEN` / `SLACK_CHANNEL(_ID)`

そのため、Slack 通知 hook で使っている bot token / channel をそのまま再利用できます。

## プラグインとしてのインストール

### ローカルからインストール

```bash
claude --plugin-dir ~/dotfiles/claude
```

### マーケットプレイスから配布

1. GitHubリポジトリにpush
2. マーケットプレイスを追加:
```bash
/plugin marketplace add yourusername/dotfiles
```
3. プラグインをインストール:
```bash
claude plugin install my-claude-tools@yourusername-dotfiles
```

## 使用方法

Claude Codeに「Slackで聞いて」「Slack経由で質問」と指示すると自動発動します。

## ファイル構成

```
slack-ask/
├── SKILL.md              # スキル定義
├── README.md             # このファイル
└── scripts/
    ├── get-credentials.sh  # クレデンシャル取得
    ├── ask.sh              # 質問スクリプト
    ├── approve.sh          # 承認スクリプト
    └── notify.sh           # 通知スクリプト
```

## セキュリティ

- トークンは平文ファイルに保存しない
- Keychain/pass/セキュアストレージを使用
- `.gitignore`でクレデンシャルファイルを除外
