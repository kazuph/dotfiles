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
alias python='python3'
alias pip='pip3'

# Keep Ghostty's TERM_PROGRAM inside tmux so Kitty-compatible apps (yazi, snacks, etc.) can detect the real terminal.
if [[ -n "$TMUX" && -n "$GHOSTTY_SHELL_FEATURES" && "$TERM_PROGRAM" != "Ghostty" ]]; then
  export TERM_PROGRAM="Ghostty"
  if [[ -z "${GHOSTTY_TERM_PROGRAM_VERSION:-}" && -r /Applications/Ghostty.app/Contents/Info.plist ]]; then
    GHOSTTY_TERM_PROGRAM_VERSION="$(
      /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' /Applications/Ghostty.app/Contents/Info.plist 2>/dev/null
    )"
  fi
  if [[ -n "$GHOSTTY_TERM_PROGRAM_VERSION" ]]; then
    export TERM_PROGRAM_VERSION="$GHOSTTY_TERM_PROGRAM_VERSION"
  fi
fi

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
_Z_DATA=~/.z

# j: z の履歴を fzf で選択して cd
unalias j 2>/dev/null
j() {
  local dir=$(z -l 2>&1 | sed 's/^[0-9. ]*//' | fzf --tac --no-sort --preview 'ls -la {}')
  [[ -n "$dir" ]] && cd "$dir"
}
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
# 全文検索（~/.local/bin/rg_with_glob を使用）
__fzf_ripgrep() {
  emulate -L zsh
  selected=$( \
      fzf --disabled --ansi \
          --bind 'start:reload:rg_with_glob {q} || :' \
          --bind 'change:reload:rg_with_glob {q} || :' \
          --bind="ctrl-l:execute(tmux splitw -h -- nvim +/{q} {1} +{2})" \
          --delimiter=":" \
          --header '@.md or @.md pattern' \
          --preview="bat --color=always --style=header,grid --highlight-line {2} {1} 2>/dev/null || bat --color=always --style=header,grid {1}" \
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
f() { fzf | while read LINE; do eval "$@ \"$LINE\"" </dev/tty; done }
fp() { fzf --preview '[[ -d {} ]] && ls -la {} || bat --color=always --style=header,grid {}' | while read LINE; do eval "$@ \"$LINE\"" </dev/tty; done }
gcd() {
  local ghq_root=$(ghq root)
  local current_dir=$(pwd)
  local selected

  # transform で3モード循環: local -> ghq -> git -> local ...
  local toggle='ctrl-g:transform:
    if [[ $FZF_PROMPT =~ local ]]; then
      echo "change-prompt(ghq> )+reload(ghq list -p)+change-preview(bat --color=always --style=header,grid --line-range :80 {}/README.*)"
    elif [[ $FZF_PROMPT =~ ghq ]]; then
      echo "change-prompt(git> )+reload(git branch --all 2>/dev/null | sed \"s/^[* ]*//\" | grep -v HEAD)+change-preview(git log --oneline --color=always -20 {} 2>/dev/null)"
    else
      echo "change-prompt(local> )+reload(fd . --type f --type d 2>/dev/null)+change-preview([[ -d {} ]] && ls -la {} || bat --color=always --style=header,grid {})"
    fi'

  if [[ "$current_dir" == "$HOME" ]] || [[ "$current_dir" != "$ghq_root"* ]]; then
    # ホームディレクトリ or ghq管理外 → ghqリポジトリ検索から開始
    selected=$(ghq list -p | fzf \
      --prompt 'ghq> ' \
      --header 'C-g: toggle mode (ghq/git/local)' \
      --preview "bat --color=always --style=header,grid --line-range :80 {}/README.*" \
      --bind "$toggle")
  else
    # ghq管理下 → ファイル/ディレクトリ検索から開始
    selected=$(fd . --type f --type d 2>/dev/null | fzf \
      --prompt 'local> ' \
      --header 'C-g: toggle mode (local/ghq/git)' \
      --preview '[[ -d {} ]] && ls -la {} || bat --color=always --style=header,grid {}' \
      --bind "$toggle")
  fi

  # 選択結果を処理
  if [[ -n "$selected" ]]; then
    if [[ -d "$selected" ]]; then
      cd "$selected"
    elif [[ -f "$selected" ]]; then
      eval "vi \"$selected\"" </dev/tty
    else
      # ファイルでもディレクトリでもない → git branch とみなす
      local branch="${selected#remotes/origin/}"
      # worktree で使用中ならそのディレクトリに移動
      local wt_path=$(git worktree list 2>/dev/null | grep "\[$branch\]" | awk '{print $1}')
      if [[ -n "$wt_path" ]]; then
        cd "$wt_path"
      else
        git checkout "$branch" 2>/dev/null || git checkout -b "$branch" "origin/$branch" 2>/dev/null
      fi
    fi
  fi
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
alias ghm='gh markdown-preview'

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

# 最低限の危険コマンドだけダイアログを残す（rm -rfやディスク破壊系のみ）。承認/却下理由をフォーム入力で残す。
ai_extreme_confirm() {
  local cmd="$1"; shift
  local args=("$@")
  local needs_prompt=0
  local has_recursive=0
  local has_force=0
  local log_file="$HOME/.ai_extreme_confirm.log"
  local log_ready=1

  if ! touch "$log_file" 2>/dev/null; then
    log_ready=0
    printf "⚠️ ログファイル %s を作成できませんでした。権限を確認してください。\n" "$log_file" >&2
  fi

  if [[ "$cmd" == "rm" || "$cmd" == "trash" || "$cmd" == "rimraf" ]]; then
    for arg in "${args[@]}"; do
      if [[ "$arg" == -* ]]; then
        [[ "$arg" == *r* || "$arg" == *R* ]] && has_recursive=1
        [[ "$arg" == *f* ]] && has_force=1
      fi
      [[ "$arg" == "--recursive" || "$arg" == "--dir" ]] && has_recursive=1
      [[ "$arg" == "--force" ]] && has_force=1
      [[ "$arg" == "--no-preserve-root" ]] && needs_prompt=1
    done

    for arg in "${args[@]}"; do
      if [[ "$arg" == "/" || "$arg" == "/*" || "$arg" == "." || "$arg" == ".." || "$arg" == */ ]]; then
        needs_prompt=1
      fi
    done
  fi

  case "$cmd" in
    rm|trash)
      (( has_recursive )) && needs_prompt=1 ;;
    rmdir|rimraf)
      needs_prompt=1 ;;
    dd|mkfs|fdisk|diskutil|format|parted|gparted)
      needs_prompt=1;;
  esac

  local cmd_display
  cmd_display="$(printf "%s " "$cmd" "${args[@]}")"
  cmd_display="${cmd_display% }"

  if (( needs_prompt )); then
    local dialog_output button_choice reason_text
    if command -v osascript >/dev/null 2>&1; then
      dialog_output=$(osascript - "$cmd_display" <<'APPLESCRIPT'
on run argv
  set cmdText to item 1 of argv
  set promptText to "⚠️ 本当に実行しますか？" & return & cmdText & return & return & "承認/却下の理由を入力してください。"
  try
    set resp to display dialog promptText default answer "" buttons {"却下", "承認"} default button "却下" with icon stop
    return (button returned of resp) & linefeed & (text returned of resp)
  on error number -128
    return "ESC" & linefeed & ""
  end try
end run
APPLESCRIPT
      ) || dialog_output=""
    fi

    if [[ -n "$dialog_output" ]]; then
      button_choice="${dialog_output%%$'\n'*}"
      reason_text="${dialog_output#*$'\n'}"
    fi

    if [[ -z "$button_choice" ]]; then
      if [[ -t 0 && -t 1 ]]; then
        printf "⚠️ 本当に実行しますか？\n%s\n承認する場合は y/yes を入力してください。\n理由: " "$cmd_display" >&2
        read -r reason_text
        printf "承認しますか？ [y/N]: " >&2
        read -r button_choice
      else
        printf "❌ Command cancelled: %s\n   理由: 対話プロンプトを表示できません\n" "$cmd_display" >&2
        (( log_ready )) && printf "%s\tREJECT\t%s\t%s\n" "$(date -Iseconds)" "$cmd_display" "非対話のため自動拒否" >> "$log_file"
        return 1
      fi
    fi

    if [[ "$button_choice" != "承認" && "$button_choice" != "y" && "$button_choice" != "yes" && "$button_choice" != "Y" ]]; then
      printf "❌ Command cancelled: %s\n" "$cmd_display"
      printf "   理由: %s\n" "${reason_text:-未入力}"
      (( log_ready )) && printf "%s\tREJECT\t%s\t%s\n" "$(date -Iseconds)" "$cmd_display" "${reason_text:-未入力}" >> "$log_file"
      return 1
    fi

    (( log_ready )) && printf "%s\tALLOW\t%s\t%s\n" "$(date -Iseconds)" "$cmd_display" "${reason_text:-未入力}" >> "$log_file"
    printf "✅ 承認: %s (理由: %s)\n" "$cmd_display" "${reason_text:-未入力}"
  fi

  if [[ "$cmd" == "rm" ]]; then
    if command -v trash >/dev/null 2>&1; then
      command trash "${args[@]}"
    else
      command rm "${args[@]}"
    fi
  else
    command "$cmd" "${args[@]}"
  fi
}

alias sudo='sudo '
alias rm='ai_extreme_confirm rm'
alias rmdir='ai_extreme_confirm rmdir'
alias dd='ai_extreme_confirm dd'
alias mkfs='ai_extreme_confirm mkfs'
alias fdisk='ai_extreme_confirm fdisk'
alias diskutil='ai_extreme_confirm diskutil'
alias format='ai_extreme_confirm format'
alias parted='ai_extreme_confirm parted'
alias gparted='ai_extreme_confirm gparted'
alias rimraf='ai_extreme_confirm rimraf'
alias trash='ai_extreme_confirm trash'

# ファームウェア/セキュリティ周りは常にsudoを要求
alias nvram='sudo nvram'
alias csrutil='sudo csrutil'
alias spctl='sudo spctl'

export PATH="/opt/homebrew/opt/trash/bin:$PATH"
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
alias codex='command codex --sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox'

alias gemini='command mise exec -- gemini --approval-mode=yolo'

# pnpm
export PNPM_HOME="/Users/kazuph/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by Antigravity
export PATH="/Users/kazuph/.antigravity/antigravity/bin:$PATH"

# Added by Antigravity
export PATH="/Users/kazuph/.antigravity/antigravity/bin:$PATH"
