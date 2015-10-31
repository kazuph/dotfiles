if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

source ~/.fzf.zsh
alias th='tail -10000 $HOME/.zsh_history|perl -pe '\''s/^.+;//'\''|fzf'

eval "$(hub alias -s)"

# rbenv
if [ -d ${HOME}/.rbenv  ] ; then
  export PATH="${HOME}/.rbenv/bin:${HOME}/.rbenv/shims:${PATH}"
  eval "$(rbenv init -)"
fi

# export PATH=/Users/kazuph_org/local/node-v0.10/bin:$PATH

skip_global_compinit=1

