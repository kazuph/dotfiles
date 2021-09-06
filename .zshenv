# zmodload zsh/zprof && zprof

if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$hOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

source ~/.fzf.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# skip_global_compinit=1
export PATH=$PATH:$HOME/esp/xtensa-esp32-elf/bin
export IDF_PATH=~/esp/esp-idf

if [ -d /home/linuxbrew/.linuxbrew ] ; then
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

if [ -d ${HOME}/.anyenv ] ; then
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
fi
. "$HOME/.cargo/env"
