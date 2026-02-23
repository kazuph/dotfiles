# Keychain Mapping Files

各SkillのCLIをTouch ID付きで実行したい場合は、このディレクトリに`<skill>.env`のようなマッピングファイルを作り、`scripts/keychain-env.sh`経由で起動してください。

## フォーマット

```
# コメント
ENV_VAR_NAME=KeychainServiceName
```

- `ENV_VAR_NAME`: CLIが参照する環境変数（例: `GMAIL_MCP_TOKEN`）
- `KeychainServiceName`: macOS Keychainに保存したパスワード／トークンのサービス名
- 空行と`#`始まりの行は無視されます

例（`keychain-env/gmail.env`）:
```
GMAIL_MCP_TOKEN=gmail-mcp-token
GMAIL_MCP_REFRESH_TOKEN=gmail-mcp-refresh
```

## Keychainへの登録例
```bash
security add-generic-password -a "$USER" -s gmail-mcp-token -w '<token-value>'
security add-generic-password -a "$USER" -s gmail-mcp-refresh -w '<refresh-token>'
```
登録時にKeychainのアクセス制御で「このアイテムを使うときTouch IDを要求」を設定してください。

## 実行例
```bash
~/.claude/skills/keychain-env/keychain-env.sh keychain-env/gmail.env ./bin/gmail-tools serve
```

CLIをデーモンとして起動するときだけTouch ID認証が走り、デーモン起動後の`list-tools`や`run`は既存ソケットに接続するだけなので再認証は不要です。
