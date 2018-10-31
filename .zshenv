# zmodload zsh/zprof && zprof

if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$hOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

source ~/.fzf.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# rbenv
if [ -d ${HOME}/.rbenv  ] ; then
  export PATH="${HOME}/.rbenv/bin:${HOME}/.rbenv/shims:${PATH}"
  eval "$(rbenv init -)"
fi

# skip_global_compinit=1
export PATH=$PATH:$HOME/esp/xtensa-esp32-elf/bin
export IDF_PATH=~/esp/esp-idf
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"
