# .bashrc
export LANG=ja_JP.UTF-8
# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions
alias tmux='TERM=xterm-256color tmux -u'
alias vi='vim'
# source ~/perl5/perlbrew/etc/bashrc
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
PS1="\u:\W\$(parse_git_branch) $ "
stty -ixon -ixoff
