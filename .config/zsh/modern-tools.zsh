# ===========================================
# Modern CLI Tools Configuration
# ===========================================

# ----- Starship Prompt -----
eval "$(starship init zsh)"

# ----- Zoxide (smarter cd) -----
eval "$(zoxide init zsh)"
# 使い方: z <directory> でジャンプ、zi でインタラクティブ選択

# ----- eza (modern ls) -----
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias lt='eza -T --icons --level=2'  # ツリー表示
    alias lta='eza -Ta --icons --level=2'
fi

# ----- bat (modern cat) -----
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias catp='bat'  # ページャー付き
    export BAT_THEME="Catppuccin Mocha"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ----- ripgrep (modern grep) -----
if command -v rg &> /dev/null; then
    alias grep='rg'
    alias rgi='rg -i'  # case-insensitive
fi

# ----- fd (modern find) -----
if command -v fd &> /dev/null; then
    alias find='fd'
    # fzfのデフォルトコマンドをfdに変更
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# ----- fzf + zoxide integration -----
# zi: インタラクティブにディレクトリジャンプ
function zf() {
    local dir
    dir=$(zoxide query -l | fzf --height 40% --reverse --preview 'eza -la --icons --git {}')
    if [[ -n "$dir" ]]; then
        cd "$dir"
    fi
}

# ----- Quick edit configs -----
alias zshconfig='${EDITOR:-nvim} ~/.zshrc'
alias starconfig='${EDITOR:-nvim} ~/.config/starship.toml'
alias tmuxconfig='${EDITOR:-nvim} ~/.tmux.conf'
alias nvimconfig='${EDITOR:-nvim} ~/.config/nvim/init.lua'
