#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
export EDITOR=vim
HISTSIZE=1000000
SAVEHIST=1000000

zmodload zsh/zle
# export LANG=ja_JP.UTF-8
# fpath=($HOME/dotfiles/zsh-completions/src $fpath)
fpath=(/usr/local/share/zsh-completions $fpath)

export PATH=~/dotfiles/bin:$PATH
# alias git='/usr/local/bin/git'
alias uml='java -jar $HOME/bin/plantuml.jar ' # + 入力ファイル

# unalias history
# Customize to your needs...
alias tmux="TERM=xterm-256color tmux -u"
alias i='iqube'
# "v"でデフォルトのviを立ち上げる
# alias vim='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
alias v="vim -u $HOME/dotfiles/.vimrc_compact"
alias zshrc='source $HOME/.zshrc'
alias vimzshrc='vim $HOME/.zshrc'
alias vz='vim $HOME/.zshrc'
alias ve='vim $HOME/.zshenv'
alias vv='vim $HOME/.vimrc'
alias vg='vim $HOME/.gitconfig'
alias sshconfig='vim $HOME/.ssh/config'
alias sb='/Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl'
alias vimupdate="vim +NeoBundleUpdate +qa"
alias viminstall="vim +NeoBundleInstall +qa"
alias notify='perl -nle '\''print "display notification \"$_\" with title \"Terminal\""'\'' | osascript'
alias t='tree -I "node_modules|bundle"'
alias brake='bin/rake'
alias brails='bin/rails'
alias brspec='bin/rspec'
alias s='bin/rails server'
alias console='brails c'
alias reset='brake db:migrate:reset'
alias migrate='brake db:migrate'
alias seed='brake db:seed'
alias rename='massren --config editor vim && massren'
alias vf='vim `fzf`'
alias vc='vim -o `git cl`'
alias vm='vim -o `git ml`'
# alias todo="vim /Users/kazuhiro.honma/Dropbox/memo/2014-07-21-todo.markdown"
alias todo="todo.sh"
alias jf='cd `j | fzf  | awk '\''{print $2}'\''`'
alias tidy='tidy -config $HOME/dotfiles/tidy_config'
alias get='ghq get '
alias usb='ls /dev/tty.*'
alias rn='react-native'
alias sub=subl
alias vim=vim
alias vi=nvim
alias vi=nvim

# atcoder
alias acctest="oj t -d tests -c 'ruby main.rb'"

# for go
if which go >/dev/null 2>&1; then
    export GOPATH=${HOME}
    export GOBIN=~/bin
    path=($GOPATH/bin $path)
fi

# for android
export ANT_OPTS=-Dfile.encoding=UTF8
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# for nordic
export PATH=$PATH:$HOME/nRF5_SDK/tools/nrfjprog

# z - jump around
function load-if-exists() { test -e "$1" && source "$1" }
source ~/dotfiles/z/z.sh
_Z_CMD=j
_Z_DATA=~/.z
if is-at-least 4.3.9; then
  load-if-exists ~/dotfiles/z/z.sh
else
  _Z_NO_PROMPT_COMMAND=1
  load-if-exists ~/dotfiles/z/z.sh && {
    function precmd_z() {
      _z --add "$(pwd -P)"
    }
    precmd_functions+=precmd_z
  }
fi
test $? || unset _Z_CMD _Z_DATA _Z_NO_PROMPT_COMMAND

setopt no_share_history

### カレントディレクトリ以下を検索して移動
function fzf-get-current-dir() {
    find . -type d | grep -vE '(\.git|\.svn|vendor/bundle|\.bundle|public/uploads|/tmp|node_mobuldes)' | fzf
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

# Run deamonized container, e.g., $dkd base /bin/echo hello
alias dkd="docker run -d -P"

# Run interactive container, e.g., $dki base /bin/bash
alias dki="docker run -i -t -P"

# Execute interactive container, e.g., $dex base /bin/bash
alias dex="docker exec -i -t"

# Stop all containers
dstop() { docker stop $(docker ps -a -q); }

# Remove all containers
drm() { docker rm $(docker ps -a -q); }

# Stop and Remove all containers
alias drmf='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'

# Remove all images
drmi() { docker rmi $(docker images -q); }

# Dockerfile build, e.g., $dbu tcnksm/test
dbu() { docker build -t=$1 .; }

# Show all alias related docker
dalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }

# Bash into running container
dbash() { docker exec -it $(docker ps -aqf "name=$1") bash; }

alias dc='docker-compose'

# ググれる
ggr() {open "https://www.google.co.jp/search?q=$1";}

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
alias o='git ls-files | f open'
alias e='ghq list -p | f cd'

# incremental
f() { fzf | while read LINE; do $@ $LINE; done }

gh(){
    ghq list -p | f cd;
    zle accept-line
}
zle -N gh
bindkey "^g" gh

setopt ignoreeof

# unset PYTHONPATH

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# インクリメンタルにソースコードの中身を検索する
function pe() {
  vim -o `ag "$@" . | peco --exec 'awk -F : '"'"'{print "+" $2 " " $1}'"'"''`
}

# export PATH="$PATH:$(yarn global bin)"
export PATH="/usr/local/opt/openssl/bin:$PATH"

# neovim
export XDG_CONFIG_HOME=~/.config
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH="/usr/local/opt/ncurses/bin:$PATH"
export PATH="$PATH:$HOME/flutter/flutter/bin"

# ARM gcc
export PATH=$PATH:/opt/gnuarmemb/gcc-arm-none-eabi-7-2018-q2-update/bin

export LC_ALL=en_US.UTF-8
# export LANG=en_US.UTF-8
export LANG=ja_JP.UTF-8
export GIT_EDITOR='/Applications/MacVim.app/Contents/MacOS/Vim -fg '

# export DOCKER_HOST=raspberrypi.local:2375

export PATH=$PATH:/Applications/"Android Studio.app"/Contents/jre/jdk/Contents/Home/bin
export JAVA_HOME=/Applications/"Android Studio.app"/Contents/jre/jdk/Contents/Home

export AWS_PROFILE=600

# for ddbcli
export $(cat ~/.aws/credentials | grep -v 600 | sed -e 's/ //g' | perl -pe "s/(aws\w+)=/\U\1=/g")
export AWS_REGION=ap-northeast-1

export HISTFILE="${ZDOTDIR:-$HOME}/.zhistory" # The path to the history file.

export PATH="$PATH:$HOME/development/flutter/bin"

function simc() {
  xcrun instruments -w $(xcrun simctl list | grep -v unavailable | grep -E "^\s" | grep -v ":" | fzf | grep -oE "\((.+?)\)" | grep -oE ".{20,}" | head -n1 | perl -pe "s/(\(|\))//g" )
}

# function balena {
#   if [ -f .gitignore.balena ] ; then
#     echo cp .gitignore.balena .gitignore
#     \cp .gitignore .gitignore.org
#     \cp .gitignore.balena .gitignore
#     /usr/local/bin/balena "$@"
#     echo cp .gitignore.org .gitignore
#     \cp .gitignore.org .gitignore
#     rm -rf .gitignore.org
#   else
#     /usr/local/bin/balena "$@"
#   fi
# }
#
source ~/.cargo/env

# M5Stack Moddable
export MODDABLE="/Users/kazuph600/src/github.com/Moddable-OpenSource/moddable"
export PATH="${MODDABLE}/build/bin/mac/release:$PATH"
export IDF_PATH=$HOME/esp32/esp-idf
export PATH=$PATH:$HOME/esp32/xtensa-esp32-elf/bin:$IDF_PATH/tools
