# dotfiles

macOS用の開発環境セットアップ

## インストール

```bash
# 1. Homebrewをインストール（未インストールの場合）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. dotfilesをcloneしてインストール
cd ~
git clone https://github.com/kazuph/dotfiles.git
cd dotfiles
./install.sh
```

## 含まれるもの

### CLI ツール
- **starship** - モダンなプロンプト
- **zoxide** - スマートなcd（`z`コマンド）
- **eza** - モダンなls（アイコン/Git対応）
- **bat** - モダンなcat（シンタックスハイライト）
- **ripgrep** - 高速grep
- **fd** - 高速find
- **fzf** - ファジーファインダー
- **ghq** - Gitリポジトリ管理
- **gh** - GitHub CLI

### フォント
- **UDEV Gothic NF** - UDフォント + JetBrains Mono + Nerd Font
- **Hack Nerd Font**

### エディタ/ターミナル
- **Neovim** (AstroNvim)
- **tmux** + Catppuccin テーマ
- **Ghostty** 設定

## インストール後

```bash
# シェル再起動
exec zsh

# tmuxプラグインインストール（tmux内で）
# prefix + I (Ctrl+T, I)
```

## 注意事項

### Ghostty設定について

Ghosttyは以下の2箇所に設定ファイルを持つ可能性がある：

1. `~/.config/ghostty/config` - 標準の場所
2. `~/Library/Application Support/com.mitchellh.ghostty/config` - macOS固有

**シンボリックリンクを正しく動作させるには：**

```bash
# macOS固有の設定を削除
rm -rf ~/Library/Application\ Support/com.mitchellh.ghostty/

# シンボリックリンクを作成
ln -snfv ~/dotfiles/.config/ghostty ~/.config/ghostty
```

これでGhosttyは `~/.config/ghostty/config` を使用するようになる。
