
# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

eval "$('/opt/homebrew/bin/brew' shellenv)"

export PATH="$HOME/.elan/bin:$PATH"

# 危険コマンド確認フック（非対話ログインシェルでも有効化）
[[ -f "$HOME/.ai_guard.zsh" ]] && source "$HOME/.ai_guard.zsh"
