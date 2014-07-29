zmodload zsh/zle
ZSH=$HOME/.oh-my-zsh
export LANG=ja_JP.UTF-8
ZSH_THEME="wedisagree"
# ZSH_THEME="muse"
plugins=(svn git ruby linux osx docker mosh)
# plugins=(svn git ruby linux osx mosh)
fpath=($HOME/dotfiles/zsh-completions/src $fpath)

# export PATH=/usr/local/bin:/usr/bin:$PATH

source $ZSH/oh-my-zsh.sh
# Customize to your needs...
alias tmux="TERM=xterm-256color tmux -u"
alias i='iqube'
# "v"でデフォルトのviを立ち上げる
alias v="vim -u NONE --noplugin"
alias zshrc='source $HOME/.zshrc'
alias vimzshrc='vim $HOME/.zshrc'
alias vz='vim $HOME/.zshrc'
alias vv='vim $HOME/.vimrc'
alias sshconfig='vim $HOME/.ssh/config'
alias sb='/Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl'
alias vimupdate="vim +NeoBundleUpdate +qa"
alias viminstall="vim +NeoBundleInstall +qa"
alias notify='perl -nle '\''print "display notification \"$_\" with title \"Terminal\""'\'' | osascript'
alias t='tree'
alias gipo='git push origin'
alias gipom='git pull origin master'
alias z='zeus'
alias brake='bin/rake'
alias brails='bin/rails'
alias brspec='bin/rspec'
alias s='bin/rails server'
alias console='brails c'
alias reset='brake db:migrate:reset'
alias migrate='brake db:migrate'
alias seed='brake db:seed'
alias rename='massren'
alias dl='docker ps -l -q'
alias vif='vim `fzf`'
alias vip='vim `ag . -l | peco`'
alias vic='vim -o `git cl`'
alias viz='vim ~/.zshrc'
alias ghql="ghq list -p | perl -nlpe 's[.*src/(.*)][$1\0$_]' | peco --null'"
alias todo="vim /Users/kazuhiro.honma/Dropbox/memo/2014-07-21-todo.markdown"
alias jf='cd `j | fzf  | awk '\''{print $2}'\''`'
alias jp='cd `j | sort -nr | peco | awk '\''{print $2}'\''`'

function extract() {
case $1 in
    *.tar.gz|*.tgz) tar xzvf $1;;
*.tar.xz) tar Jxvf $1;;
    *.zip) unzip $1;;
*.lzh) lha e $1;;
    *.tar.bz2|*.tbz) tar xjvf $1;;
*.tar.Z) tar zxvf $1;;
    *.gz) gzip -dc $1;;
*.bz2) bzip2 -dc $1;;
    *.Z) uncompress $1;;
*.tar) tar xvf $1;;
    *.arj) unarj $1;;
esac
}
alias -s {gz,tgz,zip,lzh,bz2,tbz,Z,tar,arj,xz}=extract

show_buffer_stack() {
    POSTDISPLAY="
    stack: $LBUFFER"
    zle push-line
}
zle -N show_buffer_stack
bindkey "^[q" show_buffer_stack

# for node
if [[ -f ~/.nvm/nvm.sh ]]; then
    source ~/.nvm/nvm.sh
    wait
    test nvm >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
        _nodejs_use_version="v0.10.26"
        if nvm ls | grep -F -e "${_nodejs_use_version}" >/dev/null 2>&1 ;then
            nvm use "${_nodejs_use_version}" >/dev/null
            export NODE_PATH=${NVM_PATH}_modules${NODE_PATH:+:}${NODE_PATH}
        fi
        unset _nodejs_use_version
    fi
fi

# for go
if which go >/dev/null 2>&1; then
    export GOPATH=${HOME}/go
    path=($GOPATH/bin $path)
fi

# for python
export PYTHONPATH=/usr/local/lib/python2.7/site-packages:$PYTHONPATH

# for android
export ANT_OPTS=-Dfile.encoding=UTF8
export ANDROID_HOME=$HOME/Documents/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# z.sh
_Z_CMD=j
source ~/dotfiles/z/z.sh
precmd() {
    _z --add "$(pwd -P)"
}

# auto rehash
function gem(){
$HOME/.rbenv/shims/gem $*
if [ "$1" = "install" ] || [ "$1" = "i" ] || [ "$1" = "uninstall" ] || [ "$1" = "uni" ]
then
    rbenv rehash
    rehash
fi
}

# design
ZSH_THEME_GIT_PROMPT_PREFIX="[⭠ %{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}] %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%}]"

# 一定時間以上かかる処理の場合は終了時に通知してくれる
local COMMAND=""
local COMMAND_TIME=""
precmd() {
    if [ "$COMMAND_TIME" -ne "0" ] ; then
        local d=`date +%s`
        d=`expr $d - $COMMAND_TIME`
        if [ "$d" -ge "10" ] ; then
            COMMAND="$COMMAND "
            which terminal-notifier > /dev/null 2>&1 && terminal-notifier -message "${${(s: :)COMMAND}[1]}" -m "$COMMAND";
            # which growlnotify > /dev/null 2>&1 && growlnotify -t "${${(s: :)COMMAND}[1]}" -m "$COMMAND";
            # which notify > /dev/null 2>&1 && echo "$COMMAND" | notify;
        fi
    fi
    COMMAND="0"
    COMMAND_TIME="0"
}
preexec () {
    COMMAND="${1}"
    if [ "`perl -e 'print($ARGV[0]=~/ssh|^vi/)' $COMMAND`" -ne 1 ] ; then
        COMMAND_TIME=`date +%s`
    fi
}


### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

setopt no_share_history

function gi() { curl http://gitignore.io/api/$@ ;}

### カレントディレクトリ以下を検索して移動
function percol-get-current-dir() {
    find . -type d | grep -vE '(\.git|\.svn|vendor/bundle|public/uploads|/tmp)' | fzf
}
function percol-cdr() {
    local destination="$(percol-get-current-dir)"
    if [ -n "$destination" ]; then
        BUFFER="cd $destination"
        zle accept-line
    else
        zle reset-prompt
    fi
}
zle -N percol-cdr
bindkey '^q' percol-cdr

# ------------------------------------
# Docker alias and function
# ------------------------------------
# if [ `ps aux | grep dvm | grep -v grep | wc -l` == 1 ]; then
#   eval $(dvm env)
# fi
export DOCKER_HOST=tcp://192.168.59.103:2375

# Get DOCKER_HOST IP:PORT
alias dh="echo $DOCKER_HOST"
alias dhip="boot2docker ip 2>& /dev/null"
alias dhport="echo $DOCKER_HOST | cut -c7-19"

# Get latest container ID
alias dl="docker ps -l -q"

# Get container process
alias dps="docker ps"

# Get process included stop container
alias dpa="docker ps -a"

# Get images
alias di="docker images"

# Get container IP
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

# Get latest container IP
# alias dlip="docker inspect --format '{{ .NetworkSettings.IPAddress }}' `dl`"

# Run deamonized container, e.g., $dkd base /bin/echo hello
alias dkd="docker run -d -P"

# Run interactive container, e.g., $dki base /bin/bash
alias dki="docker run -i -t -P"

# Stop all containers
dstop() { docker stop $(docker ps -q);}

# Remove all containers
drm() { docker rm $(docker ps -a -q); }

# Stop and Remove all containers
alias drmf='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'

# Remove all images
dri() { docker rmi $(docker images -q); }

# Dockerfile build, e.g., $dbu tcnksm/test
dbu() {docker build -t=$1 .;}

# Show all alias related docker
dalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort;}
source ~/.fzf.zsh
