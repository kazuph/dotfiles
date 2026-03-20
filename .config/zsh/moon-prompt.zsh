zmodload zsh/datetime
autoload -Uz add-zsh-hook

typeset -g MOONPROMPT_SCRIPT="$HOME/dotfiles/bin/moonprompt.mbt"
typeset -g MOONPROMPT_BRANCH_DELIM='::MOONPROMPT_BRANCH::'
typeset -g _moonprompt_command_started_ms=""

function _moonprompt_now_ms() {
  local epoch="${EPOCHREALTIME:-0}"
  local sec="${epoch%%.*}"
  local frac="000"

  if [[ "$epoch" == *.* ]]; then
    frac="${epoch#*.}000"
  fi

  print -r -- $(( 10#$sec * 1000 + 10#${frac[1,3]} ))
}

function _moonprompt_fallback() {
  PROMPT='%F{81}%~%f'$'\n''%# '
  RPROMPT=''
  _tmux_update_git_branch_for_pane ""
}

function _moonprompt_git_info() {
  local branch staged modified untracked stashed ahead behind

  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || return 1

  local porcelain
  porcelain="$(git status --porcelain 2>/dev/null)"
  staged=0; modified=0; untracked=0
  if [[ -n "$porcelain" ]]; then
    while IFS= read -r line; do
      local xy="${line[1,2]}"
      local x="${xy[1]}"
      local y="${xy[2]}"
      [[ "$x" == "?" ]] && { (( untracked++ )); continue }
      [[ "$x" != " " && "$x" != "?" ]] && (( staged++ ))
      [[ "$y" != " " && "$y" != "?" ]] && (( modified++ ))
    done <<< "$porcelain"
  fi

  stashed="$(git stash list 2>/dev/null | wc -l | tr -d ' ')"

  local upstream
  upstream="$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"
  ahead=0; behind=0
  if [[ -n "$upstream" ]]; then
    local ab
    ab="$(git rev-list --left-right --count HEAD...'@{upstream}' 2>/dev/null)"
    if [[ -n "$ab" ]]; then
      ahead="${ab%%	*}"
      behind="${ab##*	}"
    fi
  fi

  print -r -- "$branch $staged $modified $untracked $stashed $ahead $behind"
}

function _moonprompt_render() {
  local exit_code="$1"
  local duration_ms="$2"
  local raw branch prompt_text

  if ! command -v moon >/dev/null 2>&1; then
    _moonprompt_fallback
    return
  fi

  if [[ ! -f "$MOONPROMPT_SCRIPT" ]]; then
    _moonprompt_fallback
    return
  fi

  local -a moon_args=(
    --status "$exit_code"
    --duration "$duration_ms"
    --user "${USER:-user}"
    --host "${HOST%%.*}"
    --cwd "${PWD:-$(pwd)}"
    --home "${HOME:-}"
  )

  local git_info
  git_info="$(_moonprompt_git_info)"
  if [[ -n "$git_info" ]]; then
    local -a parts=( ${(s: :)git_info} )
    moon_args+=(
      --branch "${parts[1]}"
      --staged "${parts[2]}"
      --modified "${parts[3]}"
      --untracked "${parts[4]}"
      --stashed "${parts[5]}"
      --ahead "${parts[6]}"
      --behind "${parts[7]}"
    )
  fi

  raw="$(moon run "$MOONPROMPT_SCRIPT" --target native -- "${moon_args[@]}" 2>/dev/null)" || {
    _moonprompt_fallback
    return
  }

  if [[ "$raw" == *"$MOONPROMPT_BRANCH_DELIM"* ]]; then
    prompt_text="${raw%%$MOONPROMPT_BRANCH_DELIM*}"
    branch="${raw##*$MOONPROMPT_BRANCH_DELIM}"
  else
    branch=""
    prompt_text="$raw"
  fi

  PROMPT="$prompt_text"
  RPROMPT=''
  _tmux_update_git_branch_for_pane "$branch"
}

function _moonprompt_precmd() {
  local last_status=$?
  local now_ms duration_ms

  now_ms="$(_moonprompt_now_ms)"
  duration_ms=0
  if [[ -n "${_moonprompt_command_started_ms:-}" ]]; then
    duration_ms=$(( now_ms - _moonprompt_command_started_ms ))
  fi

  _moonprompt_render "$last_status" "$duration_ms"
}

function _moonprompt_preexec() {
  _moonprompt_command_started_ms="$(_moonprompt_now_ms)"
}

add-zsh-hook -d preexec _moonprompt_preexec 2>/dev/null
add-zsh-hook -d precmd _moonprompt_precmd 2>/dev/null
add-zsh-hook preexec _moonprompt_preexec
add-zsh-hook precmd _moonprompt_precmd
