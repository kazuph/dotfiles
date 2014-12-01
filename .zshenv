source ~/.fzf.zsh
alias th='tail -10000 ~/.zsh_history|perl -pe '\''s/^.+;//'\''|fzf'
eval "$(hub alias -s)"

# rbenv
if [ -d ${HOME}/.rbenv  ] ; then
  export PATH="${HOME}/.rbenv/bin:${HOME}/.rbenv/shims:${PATH}"
  eval "$(rbenv init -)"
fi

# plenv
if [ -d ${HOME}/.plenv  ] ; then
  export PATH=${HOME}/.plenv/bin/:${HOME}/.plenv/shims:${PATH}
  eval "$(plenv init -)"
fi

skip_global_compinit=1
# sudo rm -rf /private/var/log/asl/*.asl

