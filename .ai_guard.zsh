# ai_guard: 危険コマンドの実行前に確認を挟み、ログを残す
# 非対話シェルでも可能ならダイアログを出し、失敗時のみ安全側に倒す
[[ -n ${AI_GUARD_LOADED:-} ]] && return
AI_GUARD_LOADED=1

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
      needs_prompt=1 ;;
    push|publish|deploy|reset)
      needs_prompt=1 ;;
  esac

  # サブコマンド系（git push/reset, npm|pnpm|yarn publish, firebase|vercel|flyctl deploy など）
  if [[ "$cmd" == "git" || "$cmd" == "npm" || "$cmd" == "pnpm" || "$cmd" == "yarn" || "$cmd" == "firebase" || "$cmd" == "vercel" || "$cmd" == "flyctl" ]]; then
    local subcmd="${args[1]:-}"
    case "$subcmd" in
      push|publish|deploy|reset)
        needs_prompt=1 ;;
    esac
  fi

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
        (( log_ready )) && printf "%s\tREJECT\t%s\t非対話のため自動拒否\n" "$(date -Iseconds)" "$cmd_display" >> "$log_file"
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
    if [[ -n "${AI_GUARD_EXEC:-}" ]]; then
      eval "$AI_GUARD_EXEC"
    else
      command "$cmd" "${args[@]}"
    fi
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

# --- guarded wrappers -------------------------------------------------

# git push/reset を確認
git() {
  if [[ "$1" == push || "$1" == reset ]]; then
    ai_extreme_confirm git "$@"
  else
    command git "$@"
  fi
}

# npm/pnpm/yarn publish を確認
npm() {
  if [[ "$1" == publish ]]; then
    ai_extreme_confirm npm "$@"
  else
    command npm "$@"
  fi
}

pnpm() {
  if [[ "$1" == publish ]]; then
    ai_extreme_confirm pnpm "$@"
  else
    command pnpm "$@"
  fi
}

yarn() {
  if [[ "$1" == publish ]]; then
    ai_extreme_confirm yarn "$@"
  else
    command yarn "$@"
  fi
}

# deploy 系主要CLI
firebase() {
  if [[ "$1" == deploy ]]; then
    ai_extreme_confirm firebase "$@"
  else
    command firebase "$@"
  fi
}

vercel() {
  if [[ "$1" == deploy ]]; then
    ai_extreme_confirm vercel "$@"
  else
    command vercel "$@"
  fi
}

flyctl() {
  if [[ "$1" == deploy ]]; then
    ai_extreme_confirm flyctl "$@"
  else
    command flyctl "$@"
  fi
}

# 既存 reset エイリアスを保護付きで実行
reset() {
  local exec_cmd="brake db:migrate:reset"
  AI_GUARD_EXEC="$exec_cmd" ai_extreme_confirm reset
}
