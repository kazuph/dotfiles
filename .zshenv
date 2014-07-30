source ~/.fzf.zsh
alias th='tail -10000 ~/.zsh_history|perl -pe '\''s/^.+;//'\''|fzf'

# rbenv
if [ -d ${HOME}/.rbenv  ] ; then
  export PATH="${HOME}/.rbenv/bin:${HOME}/.rbenv/shims:${PATH}"
  eval "$(rbenv init -)"
fi

# plenv
# if [ -d ${HOME}/.plenv  ] ; then
#   export PATH=${HOME}/.plenv/bin/:${HOME}/.plenv/shims:${PATH}
#   eval "$(plenv init -)"
# fi

# perlbrew
# if [ -f ${HOME}/perl5/perlbrew/etc/bashrc ] ; then
#     source ~/perl5/perlbrew/etc/bashrc
# fi

# macvim
# if [ -f /Applications/MacVim.app/Contents/MacOS/Vim ]; then
#     alias vi='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
#     alias vim='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
#     alias vless='/Applications/MacVim.app/Contents/Resources/vim/runtime/macros/less.sh'
# else
#     alias vi="vim"
# fi
# export EDITOR=vim
# if ! type vim > /dev/null 2>&1; then
#     alias vim=vi
# fi

skip_global_compinit=1
# sudo rm -rf /private/var/log/asl/*.asl
