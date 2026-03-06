zmodload zsh/datetime
autoload -Uz add-zsh-hook

typeset -g MOONPROMPT_BIN="$HOME/dotfiles/moonprompt/_build/native/release/build/cmd/main/main.exe"
typeset -g MOONPROMPT_BRANCH_DELIM='::MOONPROMPT_BRANCH::'
typeset -g _moonprompt_command_started_ms=""

export MOONPROMPT_HOST="${HOST%%.*}"

function _moonprompt_now_ms() {
  local epoch="${EPOCHREALTIME:-0}"
  local sec="${epoch%%.*}"
  local frac="000"

  if [[ "$epoch" == *.* ]]; then
    frac="${epoch#*.}000"
  fi

  print -r -- $(( 10#$sec * 1000 + 10#${frac[1,3]} ))
}

function _moonprompt_cache_runtime_versions() {
  if command -v bun >/dev/null 2>&1 && [[ -z "${MOONPROMPT_BUN_VERSION:-}" ]]; then
    export MOONPROMPT_BUN_VERSION="$(bun --version 2>/dev/null)"
  fi

  if command -v python3 >/dev/null 2>&1 && [[ -z "${MOONPROMPT_PY_VERSION:-}" ]]; then
    local python_version_output
    python_version_output="$(python3 --version 2>&1)"
    export MOONPROMPT_PY_VERSION="${python_version_output#Python }"
  fi
}

function _moonprompt_fallback() {
  PROMPT='%F{81}%~%f'$'\n''%# '
  RPROMPT=''
  _tmux_update_git_branch_for_pane ""
}

function _moonprompt_render() {
  local exit_code="$1"
  local duration_ms="$2"
  local raw branch prompt_text

  if [[ ! -x "$MOONPROMPT_BIN" ]]; then
    _moonprompt_fallback
    return
  fi

  raw="$("$MOONPROMPT_BIN" --status "$exit_code" --duration "$duration_ms" 2>/dev/null)" || {
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

_moonprompt_cache_runtime_versions
