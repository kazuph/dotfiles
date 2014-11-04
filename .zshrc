zmodload zsh/zle
ZSH=$HOME/.oh-my-zsh
export LANG=ja_JP.UTF-8
ZSH_THEME="wedisagree"
# ZSH_THEME="muse"
plugins=(svn git ruby linux osx docker mosh)
# plugins=(svn git ruby linux osx mosh)
fpath=($HOME/dotfiles/zsh-completions/src $fpath)

# export PATH=/usr/local/bin:/usr/bin:$PATH
alias git='/usr/local/bin/git'
alias uml='java -jar $HOME/bin/plantuml.jar ' # + 入力ファイル

source $ZSH/oh-my-zsh.sh
unalias history
# Customize to your needs...
alias tmux="TERM=xterm-256color tmux -u"
alias i='iqube'
# "v"でデフォルトのviを立ち上げる
alias vim='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
alias v="vim -u $HOME/dotfiles/.vimrc_compact"
alias zshrc='source $HOME/.zshrc'
alias vimzshrc='vim $HOME/.zshrc'
alias vz='vim $HOME/.zshrc'
alias ve='vim $HOME/.zshenv'
alias vv='vim $HOME/.vimrc'
alias sshconfig='vim $HOME/.ssh/config'
alias sb='/Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl'
alias vimupdate="vim +NeoBundleUpdate +qa"
alias viminstall="vim +NeoBundleInstall +qa"
alias notify='perl -nle '\''print "display notification \"$_\" with title \"Terminal\""'\'' | osascript'
alias t='tree'
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
alias vf='vim `fzf`'
alias vp='vim `ag . -l | peco`'
alias vc='vim -o `git cl`'
alias vm='vim -o `git ml`'
alias vz='vim ~/.zshrc'
alias todo="vim /Users/kazuhiro.honma/Dropbox/memo/2014-07-21-todo.markdown"
alias jf='cd `j | fzf  | awk '\''{print $2}'\''`'
alias jp='cd `j | sort -nr | peco | awk '\''{print $2}'\''`'
alias th='tail -10000 ~/.zsh_history|perl -pe '\''s/^.+;//'\''|fzf'
alias tidy='tidy -config $HOME/dotfiles/tidy_config'
alias get='ghq get '

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
    export GOPATH=${HOME}
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

### カレントディレクトリ以下を検索して移動
function fzf-get-current-dir() {
    find . -type d | grep -vE '(\.git|\.svn|vendor/bundle|public/uploads|/tmp)' | fzf
}
function fzf-cdr() {
    local destination="$(fzf-get-current-dir)"
    if [ -n "$destination" ]; then
        BUFFER="cd $destination"
        zle accept-line
    else
        zle reset-prompt
    fi
}
zle -N fzf-cdr
bindkey '^q' fzf-cdr

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

ggr() {open "https://www.google.co.jp/search?q=$1";}
ca() {git ca -m "$@";}

# The next line updates PATH for the Google Cloud SDK.
source '/Users/kazuhiro.honma/google-cloud-sdk/path.zsh.inc'

# The next line enables bash completion for gcloud.
source '/Users/kazuhiro.honma/google-cloud-sdk/completion.zsh.inc'


# https://github.com/Jxck/dotfiles/blob/master/zsh/.http_status
# https://tools.ietf.org/html/rfc7231#section-6.1
alias "100"="echo 'Continue'"
alias "101"="echo 'Switching Protocols'"
alias "200"="echo 'OK'"
alias "201"="echo 'Created'"
alias "202"="echo 'Accepted'"
alias "203"="echo 'Non-Authoritative Information'"
alias "204"="echo 'No Content'"
alias "205"="echo 'Reset Content'"
alias "206"="echo 'Partial Content'"
alias "300"="echo 'Multiple Choices'"
alias "301"="echo 'Moved Permanently'"
alias "302"="echo 'Found'"
alias "303"="echo 'See Other'"
alias "304"="echo 'Not Modified'"
alias "305"="echo 'Use Proxy'"
alias "307"="echo 'Temporary Redirect'"
alias "400"="echo 'Bad Request'"
alias "401"="echo 'Unauthorized'"
alias "402"="echo 'Payment Required'"
alias "403"="echo 'Forbidden'"
alias "404"="echo 'Not Found'"
alias "405"="echo 'Method Not Allowed'"
alias "406"="echo 'Not Acceptable'"
alias "407"="echo 'Proxy Authentication Required'"
alias "408"="echo 'Request Timeout'"
alias "409"="echo 'Conflict'"
alias "410"="echo 'Gone'"
alias "411"="echo 'Length Required'"
alias "412"="echo 'Precondition Failed'"
alias "413"="echo 'Payload Too Large'"
alias "414"="echo 'URI Too Long'"
alias "415"="echo 'Unsupported Media Type'"
alias "416"="echo 'Range Not Satisfiable'"
alias "417"="echo 'Expectation Failed'"
alias "426"="echo 'Upgrade Required'"
alias "500"="echo 'Internal Server Error'"
alias "501"="echo 'Not Implemented'"
alias "502"="echo 'Bad Gateway'"
alias "503"="echo 'Service Unavailable'"
alias "504"="echo 'Gateway Timeout'"
alias "505"="echo 'HTTP Version Not Supported'"

# incremental
p() { peco | while read LINE; do $@ $LINE; done }
f() { fzf | while read LINE; do $@ $LINE; done }

gh(){
    ghq list -p | f cd;
    zle accept-line
}
zle -N gh
bindkey "^g" gh

