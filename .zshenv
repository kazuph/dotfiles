# zmodload zsh/zprof && zprof

if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$hOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if [ -d /home/linuxbrew/.linuxbrew ] ; then
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

# $HOME/bin以下をpathに追加する
if [ -d $HOME/bin ]; then
  export PATH=$HOME/bin:$PATH
fi

. "$HOME/.cargo/env"

# uv
export PATH="/Users/kazuph/.local/bin:$PATH"
