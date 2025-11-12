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

if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

  autoload -Uz compinit
  compinit
fi
# source /usr/local/aws/bin/aws_zsh_completer.sh

# Customize to your needs...
export EDITOR=vim
HISTSIZE=1000000
SAVEHIST=1000000

zmodload zsh/zle
# export LANG=ja_JP.UTF-8
# fpath=($HOME/dotfiles/zsh-completions/src $fpath)
fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(~/.zsh-soracom-cli-completion $fpath)

export PATH=~/dotfiles/bin:$PATH
# alias git='/usr/local/bin/git'
alias uml='java -jar $HOME/bin/plantuml.jar ' # + 入力ファイル

# unalias history
# Customize to your needs...
alias tmux="TERM=xterm-256color tmux -u"
alias tmuxnew="TERM=xterm-256color tmux new-session -t 0"
alias i='iqube'
# "v"でデフォルトのviを立ち上げる
# alias vim='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
alias v="vi -u $HOME/dotfiles/.vimrc_compact"
alias zshrc='source $HOME/.zshrc'
alias vimzshrc='vim $HOME/.zshrc'
alias vz='vi $HOME/.zshrc'
alias ve='vi $HOME/.zshenv'
alias vv='vi $HOME/.vimrc'
alias vg='vi $HOME/.gitconfig'
alias sshconfig='vi $HOME/.ssh/config'
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
alias vf='vi `fzf`'
alias vc='vi -o `git cl`'
alias vm='vi -o `git ml`'
# alias todo="vim /Users/kazuhiro.honma/Dropbox/memo/2014-07-21-todo.markdown"
alias todo="todo.sh"
alias tidy='tidy -config $HOME/dotfiles/tidy_config'
alias get='ghq get '
alias usb='ls /dev/tty.*'
alias rn='react-native'
alias sub=subl
alias vi=nvim
alias vim=vi
alias tn='twnyan'
alias tw='twnyan tw'
alias to='twnyan user own'
alias ts='twnyan search'
alias tt='twnyan timeline 100'
alias tm='twnyan mention'

# atcoder
alias acctest="oj t -d tests -c 'ruby main.rb'"

# for go
if which go >/dev/null 2>&1; then
    export GOPATH=${HOME}
    export GOBIN=~/bin
    path=($GOPATH/bin $path)
    export GOENV_DISABLE_GOPATH=1 # for goenv
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

### fzf集
# 全文検索
__fzf_ripgrep() {
  emulate -L zsh
  rg_cmd="rg --smart-case --line-number --color=always --trim"
  selected=$(FZF_DEFAULT_COMMAND=":" \
      fzf --bind="change:top+reload($rg_cmd {q} || true)" \
          --bind="ctrl-l:execute(tmux splitw -h -- nvim +/{q} {1} +{2})" \
          --ansi --phony \
          --delimiter=":" \
          --preview="bat -H {2} --color=always --style=header,grid {1}" \
          --preview-window='down:60%:+{2}-10')

  local ret=$?
  [[ -n "$selected" ]] && echo ${${(@s/:/)selected}[1]}
  return $ret
}
fzf-ripgrep-widget() {
  LBUFFER="${LBUFFER}$(__fzf_ripgrep)"
  local ret=$?
  zle reset-prompt
  return $ret
}
zle -N fzf-ripgrep-widget
bindkey '^q' fzf-ripgrep-widget



# ディレクトリを検索して移動
function fzf-get-current-dir() {
    fd . --type d | fzf
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
# zle -N fzf-cdr
# bindkey '^t' fzf-cdr
export FZF_CTRL_T_COMMAND="fzf-cdr"
# export FZF_CTRL_T_COMMAND="fd --type f "
# export FZF_CTRL_T_OPTS="
#     --height 90%
#     --select-1 --exit-0
#     --bind 'ctrl-o:execute(vim {1} < /dev/tty)'
#     --bind '>:reload($FZF_CTRL_T_COMMAND -H -E .git )'
#     --bind '<:reload($FZF_CTRL_T_COMMAND)'
#     --preview 'bat -r :300 --color=always --style=header,grid {}'"

# ブランチを検索して移動
# fbr - checkout git branch
function fzf-checkout-branch() {
  local branches branch
  branches=$(git branch | sed -e 's/\(^\* \|^  \)//g' | cut -d " " -f 1) &&
  branch=$(echo "$branches" | fzf --preview "git show --color=always {}") &&
  git checkout $(echo "$branch")
}
# zle     -N   fzf-checkout-branch
# bindkey "^b" fzf-checkout-branch

# ghqで管理しているリポジトリをプレビュー付きで検索して移動
f() { fzf | while read LINE; do $@ $LINE; done }
fp() { fzf --preview "bat --color=always --style=header,grid --line-range :80 {}/README.*" | while read LINE; do $@ $LINE; done }
gcd() {
  ghq list -p | fp cd
  zle accept-line
}
zle -N gcd
bindkey "^g" gcd

# 最近cdしたディレクトリを検索して移動
# jf() {
#   j | sort -rn | awk '{print $2}' | f cd;
#   zle accept-line
# }
# zle -N jf
# bindkey "^j" jf

# gh(){
#     ghq list -p | f cd;
#     zle accept-line
# }
# zle -N gh
# bindkey "^g" gh

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

# ~/.zshrc への追加コード
# Git 関連の設定

# Git alias（.gitconfig に追加）
# [alias]
#     wt = worktree
#     wta = worktree add
#     wtl = worktree list
#     wtr = worktree remove
#     wtp = worktree prune

# Git Worktree zsh functions の読み込み
if [[ -d "$HOME/dotfiles/zsh/git-worktree" ]]; then
    # 基本操作
    source "$HOME/dotfiles/zsh/git-worktree/basic.zsh"

    # ナビゲーション
    source "$HOME/dotfiles/zsh/git-worktree/navigation.zsh"

    # メンテナンス
    source "$HOME/dotfiles/zsh/git-worktree/maintenance.zsh"
fi


setopt ignoreeof

# unset PYTHONPATH

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# インクリメンタルにソースコードの中身を検索する
function pe() {
  vim -o `ag "$@" . | peco --exec 'awk -F : '"'"'{print "+" $2 " " $1}'"'"''`
}

# export PATH="$PATH:$(yarn global bin)"
# export PATH="/usr/local/opt/openssl/bin:$PATH"

# neovim
export XDG_CONFIG_HOME=~/.config
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH="/usr/local/opt/ncurses/bin:$PATH"
export PATH="$PATH:$HOME/development/flutter/bin"

# ARM gcc
export PATH=$PATH:/opt/gnuarmemb/gcc-arm-none-eabi-7-2018-q2-update/bin

export LC_ALL=en_US.UTF-8
# export LANG=en_US.UTF-8
export LANG=ja_JP.UTF-8
export GIT_EDITOR=vi

# export DOCKER_HOST=raspberrypi.local:2375

export PATH=$PATH:/Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin
export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home/

export AWS_PROFILE=default

# for ddbcli
# export $(cat ~/.aws/credentials | grep -v 600 | sed -e 's/ //g' | perl -pe "s/(aws\w+)=/\U\1=/g")
# export AWS_REGION=ap-northeast-1

# export HISTFILE="${ZDOTDIR:-$HOME}/.zhistory" # The path to the history file.
# function select-history() {
#   BUFFER=$(history -n -r 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="History > ")
#   CURSOR=$#BUFFER
# }
# zle -N select-history
# bindkey '^r' select-history

test -e $HOME/development/flutter/bin && export PATH="$PATH:$HOME/development/flutter/bin"

function simc() {
  xcrun instruments -w $(xcrun simctl list | grep -v unavailable | grep -E "^\s" | grep -v ":" | fzf | grep -oE "\((.+?)\)" | grep -oE ".{20,}" | head -n1 | perl -pe "s/(\(|\))//g" )
}

if [ -d ${HOME}/.cargo/env ] ; then
  source ~/.cargo/env
fi

# M5Stack Moddable
export MODDABLE="/Users/kazuph/src/github.com/Moddable-OpenSource/moddable"
export PATH="${MODDABLE}/build/bin/mac/release:$PATH"
# export IDF_PATH=~/esp/esp-idf
# export PATH="$PATH:$IDF_PATH/tools"
# export PATH=$PATH:$HOME/esp32/xtensa-esp32-elf/bin:$IDF_PATH/tools

export TMUX_TMPDIR=/tmp

# source $HOME/.deepl.env

if [[ -f ~/.anyenv/bin/anyenv || -f /opt/homebrew/bin/anyenv ]] ; then
  eval "$(anyenv init -)"
fi

fpath=(${ASDF_DIR}/completions $fpath)
autoload -Uz compinit && compinit

export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"

# bun completions
[ -s "/Users/kazuph/.bun/_bun" ] && source "/Users/kazuph/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/kazuph/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/kazuph/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/kazuph/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/kazuph/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"
    fi
fi
unset __conda_setup
function condaf() {
  ENV_NAME=$(conda info --env | grep -vE "(^\s.+|^#)" | fzf --preview "conda run -n {1} pip list" | awk '{print $NF}')
  conda activate $ENV_NAME
}

alias cs='cursor --remote ssh-remote+pc "$(ssh pc ". ~/.zshrc && ghq list -p" | fzf)"'
alias ws='windsurf --remote ssh-remote+pc "$(ssh pc ". ~/.zshrc && ghq list -p" | fzf)"'

if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/kazuph/.lmstudio/bin"
export PATH="/Users/kazuph/.local/bin:$PATH"

# Added by Windsurf
export PATH="/Users/kazuph/.codeium/windsurf/bin:$PATH"

export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

alias cc="ENABLE_BACKGROUND_TASKS=1 claude --dangerously-skip-permissions"
export PATH="$HOME/.local/bin:$PATH"
export PATH=$PATH:$HOME/.maestro/bin

# Claude Code protection with user confirmation (no sudo)
# Function to check if running under Claude Code and request confirmation
claude_safe_command() {
    local cmd="$1"
    shift

    # Check if running under Claude Code
    if [[ "$CLAUDECODE" == "1" ]] || [[ -n "$CLAUDE_CODE_ENTRYPOINT" ]]; then
        # Show confirmation dialog without granting root privileges
        local dialog_result
        dialog_result=$(osascript -e "display dialog \"Claude Code wants to execute: $cmd $*\" buttons {\"Cancel\", \"Allow\"} default button \"Cancel\" with icon caution" 2>&1)

        # Check if user clicked "Allow" (dialog returns "button returned:Allow")
        if [[ "$dialog_result" == *"button returned:Allow"* ]]; then
            command $cmd "$@"
        else
            echo "❌ Command execution cancelled by user"
            return 1
        fi
    else
        command $cmd "$@"
    fi
}

# Git-specific protection function
# Claude Code実行時のGit操作を危険度別に分類して保護
# 🚨 最高危険度: reset --hard, rebase, cherry-pick (履歴改変・データ消失)
# ⚠️  高危険度: push --force, clean -f (リモート破壊・ファイル削除)
# 📝 中危険度: merge, pull, fetch (マージ競合・予期しない変更)
# ℹ️  基本確認: その他全てのgitコマンド (意図しない操作防止)
claude_safe_git() {
    local cmd="$1"
    shift
    local subcmd="$1"

    # Check if running under Claude Code
    if [[ "$CLAUDECODE" == "1" ]] || [[ -n "$CLAUDE_CODE_ENTRYPOINT" ]]; then
        # Define dangerous git operations
        case "$subcmd" in
            push|force-push|push\ --force|push\ -f)
                local dialog_result
                dialog_result=$(osascript -e "display dialog \"⚠️ Claude Code wants to PUSH code to remote repository: git $*\" buttons {\"Cancel\", \"Allow Push\"} default button \"Cancel\" with icon caution" 2>&1)
                if [[ "$dialog_result" == *"button returned:Allow Push"* ]]; then
                    command $cmd "$@"
                else
                    echo "❌ Git push cancelled by user"
                    return 1
                fi
                ;;
            reset|reset\ --hard|rebase|rebase\ -i|cherry-pick|restore|restore\ --staged|restore\ --worktree)
                local dialog_result
                dialog_result=$(osascript -e "display dialog \"⚠️ Claude Code wants to MODIFY git history or restore files: git $*\" buttons {\"Cancel\", \"Allow History Change\"} default button \"Cancel\" with icon stop" 2>&1)
                if [[ "$dialog_result" == *"button returned:Allow History Change"* ]]; then
                    command $cmd "$@"
                else
                    echo "❌ Git history modification/restore cancelled by user"
                    return 1
                fi
                ;;
            branch\ -D|branch\ --delete|tag\ -d|tag\ --delete)
                local dialog_result
                dialog_result=$(osascript -e "display dialog \"⚠️ Claude Code wants to DELETE git branch/tag: git $*\" buttons {\"Cancel\", \"Allow Delete\"} default button \"Cancel\" with icon stop" 2>&1)
                if [[ "$dialog_result" == *"button returned:Allow Delete"* ]]; then
                    command $cmd "$@"
                else
                    echo "❌ Git deletion cancelled by user"
                    return 1
                fi
                ;;
            clean\ -f|clean\ -fd|clean\ -fx)
                local dialog_result
                dialog_result=$(osascript -e "display dialog \"⚠️ Claude Code wants to CLEAN untracked files: git $*\" buttons {\"Cancel\", \"Allow Clean\"} default button \"Cancel\" with icon caution" 2>&1)
                if [[ "$dialog_result" == *"button returned:Allow Clean"* ]]; then
                    command $cmd "$@"
                else
                    echo "❌ Git clean cancelled by user"
                    return 1
                fi
                ;;
            merge|merge\ --no-ff|pull|fetch)
                local dialog_result
                dialog_result=$(osascript -e "display dialog \"Claude Code wants to execute: git $*\" buttons {\"Cancel\", \"Allow\"} default button \"Cancel\" with icon note" 2>&1)
                if [[ "$dialog_result" == *"button returned:Allow"* ]]; then
                    command $cmd "$@"
                else
                    echo "❌ Git operation cancelled by user"
                    return 1
                fi
                ;;
            *)
                # For other git commands, just show basic confirmation
                local dialog_result
                dialog_result=$(osascript -e "display dialog \"Claude Code wants to execute: git $*\" buttons {\"Cancel\", \"Allow\"} default button \"Cancel\" with icon note" 2>&1)
                if [[ "$dialog_result" == *"button returned:Allow"* ]]; then
                    command $cmd "$@"
                else
                    echo "❌ Git command cancelled by user"
                    return 1
                fi
                ;;
        esac
    else
        command $cmd "$@"
    fi
}

# Always protected commands (extremely high risk - require sudo)
alias nvram='sudo nvram'                   # ファームウェア設定変更・起動不能リスクの無認証実行を禁止
alias csrutil='sudo csrutil'              # SIP無効化・セキュリティ低下の無認証実行を禁止
alias spctl='sudo spctl'                   # Gatekeeper無効化・マルウェアリスクの無認証実行を禁止

# User confirmation protected commands (for Claude Code only)
alias rm='claude_safe_command rm'                              # Claude Code実行時のファイル削除の無認証実行を禁止
alias rmdir='claude_safe_command rmdir'                        # Claude Code実行時のディレクトリ削除の無認証実行を禁止
alias dd='claude_safe_command dd'                              # Claude Code実行時の低レベルディスク操作・データ破壊を禁止
alias mkfs='claude_safe_command mkfs'                          # Claude Code実行時のファイルシステム作成・データ全消去を禁止
alias fdisk='claude_safe_command fdisk'                        # Claude Code実行時のパーティション操作・ディスク破壊を禁止
alias diskutil='claude_safe_command diskutil'                 # Claude Code実行時のmacOSディスク管理・フォーマットを禁止
alias format='claude_safe_command format'                     # Claude Code実行時のディスクフォーマット・データ全消去を禁止
alias parted='claude_safe_command parted'                      # Claude Code実行時のパーティション編集・データ損失を禁止
alias gparted='claude_safe_command gparted'                    # Claude Code実行時のGUI パーティション編集を禁止
alias xattr='claude_safe_command xattr'                        # Claude Code実行時の隔離属性削除・セキュリティ回避を禁止
# alias chmod='claude_safe_command chmod'                        # Claude Code実行時のファイル権限変更・セキュリティ設定破壊を禁止
# alias chown='claude_safe_command chown'                        # Claude Code実行時のファイル所有者変更・アクセス制御破壊を禁止
alias launchctl='claude_safe_command launchctl'                # Claude Code実行時のmacOSサービス制御・システム動作変更を禁止
alias killall='claude_safe_command killall'                   # Claude Code実行時のプロセス名一括終了・システム不安定化を禁止
alias pkill='claude_safe_command pkill'                       # Claude Code実行時のプロセスパターン終了・重要プロセス停止を禁止
alias kill='claude_safe_command kill'                         # Claude Code実行時のプロセス強制終了・システム不安定化を禁止
alias shutdown='claude_safe_command shutdown'                 # Claude Code実行時のシステム終了・作業中断を禁止
alias reboot='claude_safe_command reboot'                     # Claude Code実行時のシステム再起動・作業中断を禁止
alias halt='claude_safe_command halt'                         # Claude Code実行時のシステム停止・作業中断を禁止
alias systemctl='claude_safe_command systemctl'               # Claude Code実行時のLinuxサービス制御・システム動作変更を禁止
alias service='claude_safe_command service'                   # Claude Code実行時のサービス制御・システム動作変更を禁止
alias crontab='claude_safe_command crontab'                   # Claude Code実行時のcron設定変更・定期実行タスク変更を禁止
alias passwd='claude_safe_command passwd'                     # Claude Code実行時のパスワード変更・アカウント乗っ取りを禁止
alias su='claude_safe_command su'                             # Claude Code実行時のユーザー切り替え・権限昇格を禁止
alias visudo='claude_safe_command visudo'                     # Claude Code実行時のsudo設定編集・権限設定破壊を禁止
alias mount='claude_safe_command mount'                       # Claude Code実行時のファイルシステムマウント・システム構成変更を禁止
alias umount='claude_safe_command umount'                     # Claude Code実行時のファイルシステムアンマウント・データ損失を禁止
alias fsck='claude_safe_command fsck'                         # Claude Code実行時のファイルシステム修復・データ変更を禁止
alias defaults='claude_safe_command defaults'                 # Claude Code実行時のmacOS設定変更・システム動作変更を禁止
alias scutil='claude_safe_command scutil'                     # Claude Code実行時のシステム設定変更・ネットワーク設定破壊を禁止
alias dscl='claude_safe_command dscl'                         # Claude Code実行時のDirectory Services操作・ユーザー管理変更を禁止
alias installer='claude_safe_command installer'               # Claude Code実行時のパッケージインストール・システム変更を禁止
alias pkgutil='claude_safe_command pkgutil'                   # Claude Code実行時のパッケージ管理・システムファイル変更を禁止
alias softwareupdate='claude_safe_command softwareupdate'     # Claude Code実行時のシステムアップデート・予期しない変更を禁止
alias profiles='claude_safe_command profiles'                 # Claude Code実行時の構成プロファイル変更・企業ポリシー破壊を禁止
alias security='claude_safe_command security'                 # Claude Code実行時のセキュリティ設定変更・暗号化設定破壊を禁止
alias keychain='claude_safe_command keychain'                 # Claude Code実行時のキーチェーン操作・パスワード情報漏洩を禁止
alias codesign='claude_safe_command codesign'                 # Claude Code実行時のコード署名操作・セキュリティ証明書変更を禁止
alias notarytool='claude_safe_command notarytool'             # Claude Code実行時のApple公証操作・開発者証明書変更を禁止
alias xcrun='claude_safe_command xcrun'                       # Claude Code実行時のXcode開発ツール実行・開発環境変更を禁止
alias networksetup='claude_safe_command networksetup'         # Claude Code実行時のネットワーク設定変更・接続設定破壊を禁止
alias systemsetup='claude_safe_command systemsetup'           # Claude Code実行時のシステム設定変更・ハードウェア設定破壊を禁止
alias pmset='claude_safe_command pmset'                       # Claude Code実行時の電源管理設定変更・バッテリー動作変更を禁止
alias caffeinate='claude_safe_command caffeinate'             # Claude Code実行時のスリープ制御・電源管理変更を禁止

# Git commands that can destroy code/history
# alias git='claude_safe_git git'                               # Claude Code実行時のGit操作全般の無認証実行を禁止


export PATH="/opt/homebrew/opt/trash/bin:$PATH"
alias rm='/opt/homebrew/opt/trash/bin/trash'
eval "$(mise activate zsh)"

# Update tmux pane metadata with the current git branch for status display
function _tmux_update_git_branch_for_pane() {
  [[ -n "${TMUX_PANE:-}" ]] || return
  command -v tmux >/dev/null 2>&1 || return

  local pane="${TMUX_PANE}"
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=""

  if [[ -n "$branch" ]]; then
    tmux set-option -q -p -t "$pane" @git_branch "$branch" >/dev/null 2>&1
  else
    tmux set-option -q -p -t "$pane" -uq @git_branch >/dev/null 2>&1
  fi
}

function _tmux_set_pane_title() {
  [[ -n "${TMUX_PANE:-}" ]] || return
  command -v tmux >/dev/null 2>&1 || return

  local title="${1:-}"
  [[ -n "$title" ]] || return
  title="${title//$'\r'/ }"
  title="${title//$'\n'/ }"
  tmux select-pane -t "$TMUX_PANE" -T "$title" >/dev/null 2>&1
}

# Git information in prompt
autoload -Uz vcs_info
precmd() {
  vcs_info
  _tmux_update_git_branch_for_pane
}
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
# PROMPT='%~ ${vcs_info_msg_0_} $ '  # Commented out to use Prezto's sorin theme

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

export PATH="$HOME/.local/bin:$PATH"
# ~/.cargo/bin/
export PATH="$HOME/.cargo/bin:$PATH"


# alias codex='/Users/kazuph/.local/share/mise/installs/node/22.18.0/bin/codex --search'
# alias codex='/Users/kazuph/.local/share/mise/installs/node/22.18.0/bin/codex --search --ask-for-approval never --sandbox workspace-write --config sandbox_workspace_write.network_access=true --full-auto'
# alias codex='/Users/kazuph/.local/share/mise/installs/node/22.20.0/bin/codex --sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox'
codex() {
  # local summary="$*"
  # [[ -n "$summary" ]] || summary="(interactive)"
  # if (( ${#summary} > 80 )); then
  #   summary="${summary:0:77}..."
  # fi
  # _tmux_set_pane_title "Codex: ${summary}"
  command codex --sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox "$@"
}

gemini() {
  # local summary="$*"
  # [[ -n "$summary" ]] || summary="(interactive)"
  # if (( ${#summary} > 80 )); then
  #   summary="${summary:0:77}..."
  # fi
  # _tmux_set_pane_title "Gemini: ${summary}"
  command mise exec -- gemini --approval-mode=yolo "$@"
}

