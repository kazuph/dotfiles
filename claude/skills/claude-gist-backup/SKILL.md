---
name: claude-gist-backup
description: CLAUDE.mdをGitHub Gist・dotfiles・Obsidianの3箇所に同期する。詳細・トリガーは本文参照。
allowed-tools: Bash
---

# CLAUDE.md Backup & Sync

## トリガー
- 「Gist」「バックアップ」「CLAUDE.md更新」などに言及されたとき
- `~/.claude/CLAUDE.md` を編集した後

## 同期先（3箇所すべてに同期すること）

| # | 同期先 | パス |
|---|--------|------|
| 1 | **GitHub Gist** | Gist ID: `c99a57f26ad3fdb012988a294d33b21e` |
| 2 | **dotfiles** | `~/dotfiles/claude/CLAUDE.md` |
| 3 | **Obsidian Vault** | `/Users/kazuph/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault/CLAUDE.md` |

## コマンド

### 1. GitHub Gist への同期
```bash
gh gist edit c99a57f26ad3fdb012988a294d33b21e --add ~/.claude/CLAUDE.md
```

### 2. dotfiles へのコピー
```bash
cp ~/.claude/CLAUDE.md ~/dotfiles/claude/CLAUDE.md
```

### 3. Obsidian Vault へのコピー
```bash
cp ~/.claude/CLAUDE.md "/Users/kazuph/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault/CLAUDE.md"
```

## 実行手順

1. `~/.claude/CLAUDE.md` が保存済みであることを確認
2. 上記3つのコマンドをすべて実行
3. `gh gist view c99a57f26ad3fdb012988a294d33b21e --raw | head -20` で Gist の内容確認

## 備考
- Gist は履歴が保持される（Secret Gist）
- dotfiles は Git 管理されているため、後で commit & push が必要な場合あり
- Obsidian は iCloud 経由で他デバイスと同期される
