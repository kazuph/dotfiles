# ai_guard: 危険コマンドの実行前に確認を挟み、ログを残す
# 非対話シェルでも可能ならダイアログを出し、失敗時のみ安全側に倒す
[[ -n ${AI_GUARD_LOADED:-} ]] && return
AI_GUARD_LOADED=1

if [[ -f "$HOME/dotfiles/.config/shell/ai-guard-common.sh" ]]; then
  . "$HOME/dotfiles/.config/shell/ai-guard-common.sh"
fi

# ============================================================================
# CRITICAL SECURITY: .allow-main 保護機構
# AIプロセスは .allow-main を含む全てのコマンドを即時ブロック
# このセクションは最優先で実行され、バイパス不可能
# ============================================================================
_ai_guard_block_protected() {
  local cmd_line="$1"
  printf "\n" >&2
  printf "🚫🚫🚫 SECURITY BLOCK 🚫🚫🚫\n" >&2
  printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" >&2
  printf "❌ AIプロセスによる .allow-main 関連操作は完全に禁止されています\n" >&2
  printf "\n" >&2
  printf "ブロックされたコマンド:\n" >&2
  printf "  %s\n" "$cmd_line" >&2
  printf "\n" >&2
  printf "理由: .allow-main はセキュリティ上重要なファイルです。\n" >&2
  printf "      AIがこのファイルを操作することは許可されていません。\n" >&2
  printf "\n" >&2
  printf "必要な場合は、人間が手動で操作してください。\n" >&2
  printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" >&2
  printf "\n" >&2

  # ログに記録
  local log_file="$HOME/.ai_guard_security.log"
  printf "%s\tBLOCKED_PROTECTED\t%s\t[AI attempted to access protected pattern]\n" \
    "$(date -Iseconds)" "$cmd_line" >> "$log_file" 2>/dev/null
}

# ============================================================================
# git checkout -b ブロック: worktree (git wt) を使わせる
# ============================================================================
_ai_guard_block_checkout_b() {
  local cmd_line="$1"
  printf "\n" >&2
  printf "🚫 ブロック: git checkout -b\n" >&2
  printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" >&2
  printf "git wt でworktreeを使う必要があります。\n" >&2
  printf "\n" >&2

  # git-wt がインストールされているかチェック
  if git wt --version >/dev/null 2>&1; then
    printf "📖 git wt の使い方:\n" >&2
    printf "  git wt <branch>       # worktree作成（なければ新規ブランチ）\n" >&2
    printf "  git wt                # worktree一覧\n" >&2
    printf "  git wt -d <branch>    # worktree削除\n" >&2
    printf "\n" >&2

    # ブランチ名を抽出して代替コマンドを提案
    local branch_name=""
    if [[ "$cmd_line" =~ checkout[[:space:]]+-b[[:space:]]+([^[:space:]]+) ]]; then
      branch_name="${match[1]}"
    elif [[ "$cmd_line" =~ checkout[[:space:]]+--branch[[:space:]]+([^[:space:]]+) ]]; then
      branch_name="${match[1]}"
    fi

    if [[ -n "$branch_name" ]]; then
      printf "📋 代わりにこちらを実行:\n" >&2
      printf "  git wt %s\n" "$branch_name" >&2
      printf "\n" >&2
    fi
  else
    printf "⚠️  git-wt がインストールされていません。\n" >&2
    printf "\n" >&2
    printf "📦 セットアップ手順:\n" >&2
    printf "  brew install k1LoW/tap/git-wt\n" >&2
    printf "\n" >&2
  fi

  printf "💡 プロジェクトローカルに.worktreeディレクトリが作成されます。\n" >&2
  printf "   設定確認: git config --get wt.basedir\n" >&2
  printf "\n" >&2
  printf "📁 ディレクトリ構造:\n" >&2
  printf "   .worktree/<branch>\n" >&2
  printf "   例: .worktree/feature-auth\n" >&2
  printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" >&2
  printf "\n" >&2

  # ログに記録
  local log_file="$HOME/.ai_guard_security.log"
  printf "%s\tBLOCKED_CHECKOUT_B\t%s\t[Redirecting to git wt worktree]\n" \
    "$(date -Iseconds)" "$cmd_line" >> "$log_file" 2>/dev/null
}

# git checkout -b または checkout --branch を検出
_ai_guard_is_checkout_b() {
  local cmd_line="$1"
  # 行頭から git checkout -b / --branch を検出（コミットメッセージ等での誤検知を防ぐ）
  [[ "$cmd_line" =~ ^git[[:space:]]+checkout[[:space:]]+-b[[:space:]] ]] && return 0
  [[ "$cmd_line" =~ ^git[[:space:]]+checkout[[:space:]]+--branch[[:space:]] ]] && return 0
  return 1
}

AI_GUARD_TEMP_APPROVAL_FILE="${AI_GUARD_TEMP_APPROVAL_FILE:-$HOME/.ai_guard_temp_approval}"
AI_GUARD_TEMP_APPROVAL_SECONDS="${AI_GUARD_TEMP_APPROVAL_SECONDS:-180}"
AI_GUARD_TEMP_REJECT_FILE="${AI_GUARD_TEMP_REJECT_FILE:-$HOME/.ai_guard_temp_reject}"
AI_GUARD_TEMP_REJECT_SECONDS="${AI_GUARD_TEMP_REJECT_SECONDS:-$AI_GUARD_TEMP_APPROVAL_SECONDS}"
AI_GUARD_APPROVAL_MODE="${AI_GUARD_APPROVAL_MODE:-auto}"

_ai_guard_temp_approval_key() {
  local cmd="$1"; shift
  local subcmd="${1:--}"
  local scope git_group deploy_env cmd_line
  cmd_line="$cmd $*"

  # ディスク破壊系は常に毎回確認（3分キャッシュを使わない）
  if _ai_guard_is_always_prompt_cmd "$cmd"; then
    printf ""
    return 0
  fi

  scope=$(_ai_guard_temp_approval_scope)

  # 削除系は「対象パス」ではなく「コマンド種別 + スコープ」で3分許可
  case "$cmd" in
    trash|rmdir|rimraf|mv)
      printf "delete:%s:%s" "$cmd" "$scope"
      return 0
      ;;
  esac

  # git危険操作は destructive group 単位で3分許可
  if [[ "$cmd" == "git" ]]; then
    git_group=$(_ai_guard_git_risky_group "$@")
    if [[ -n "$git_group" ]]; then
      printf "git:%s:%s" "$git_group" "$scope"
      return 0
    fi
  fi

  # deploy/publish/put 系は tool + env + scope 単位で3分許可
  if _ai_guard_contains_danger_word "$cmd_line"; then
    deploy_env=$(_ai_guard_detect_deploy_env "$cmd" "$@")
    printf "danger:%s:%s:%s" "$cmd" "$deploy_env" "$scope"
    return 0
  fi

  printf "%s:%s:%s" "$cmd" "$subcmd" "$scope"
}

_ai_guard_temp_approval_scope() {
  local cwd repo_root
  cwd="$(pwd -P 2>/dev/null || pwd)"
  repo_root=$(builtin command git rev-parse --show-toplevel 2>/dev/null) || repo_root=""
  if [[ -n "$repo_root" ]]; then
    printf "%s" "$repo_root"
  else
    printf "%s" "$cwd"
  fi
}

_ai_guard_git_risky_group() {
  local subcmd="$1"; shift
  case "$subcmd" in
    reset|restore)
      printf "reset-restore"
      return 0
      ;;
    clean)
      printf "clean"
      return 0
      ;;
    stash)
      if [[ "$1" == "drop" || "$1" == "clear" ]]; then
        printf "stash-drop-clear"
        return 0
      fi
      ;;
    branch)
      if [[ "$1" == "-D" || "$1" == "-d" || "$1" == "--delete" ]]; then
        printf "branch-delete"
        return 0
      fi
      ;;
    rebase)
      printf "rebase"
      return 0
      ;;
    cherry-pick)
      if [[ "$1" == "--abort" ]]; then
        printf "cherry-pick-abort"
        return 0
      fi
      ;;
    merge)
      if [[ "$1" == "--abort" ]]; then
        printf "merge-abort"
        return 0
      fi
      ;;
    push)
      if [[ " $* " == *" --force "* || " $* " == *" -f "* || " $* " == *" --force-with-lease "* ]]; then
        printf "push-force"
      else
        printf "push-review"
      fi
      return 0
      ;;
  esac
  return 1
}

_ai_guard_detect_deploy_env() {
  local cmd="$1"; shift
  local token prev=""
  local env="unknown"
  local cmd_line_l="${cmd:l} ${(j: :)${(@)${(@)@}:l}}"

  for token in "$@"; do
    case "$prev" in
      --env|-e|--stage|--target|--profile)
        token="${token:l}"
        if [[ "$token" == *prod* || "$token" == production ]]; then
          printf "prod"
          return 0
        elif [[ "$token" == stg || "$token" == stage || "$token" == staging ]]; then
          printf "stg"
          return 0
        elif [[ "$token" == preview || "$token" == pre || "$token" == canary ]]; then
          printf "preview"
          return 0
        elif [[ "$token" == dev || "$token" == development || "$token" == local ]]; then
          printf "dev"
          return 0
        fi
        ;;
    esac
    prev="$token"
  done

  if [[ "$cmd_line_l" == *prod* || "$cmd_line_l" == *production* ]]; then
    env="prod"
  elif [[ "$cmd_line_l" == *stg* || "$cmd_line_l" == *stage* || "$cmd_line_l" == *staging* ]]; then
    env="stg"
  elif [[ "$cmd_line_l" == *preview* || "$cmd_line_l" == *canary* ]]; then
    env="preview"
  elif [[ "$cmd_line_l" == *dev* || "$cmd_line_l" == *development* || "$cmd_line_l" == *local* ]]; then
    env="dev"
  fi

  printf "%s" "$env"
}

_ai_guard_is_always_prompt_cmd() {
  local cmd="$1"
  case "$cmd" in
    dd|mkfs|fdisk|diskutil|format|parted|gparted)
      return 0
      ;;
  esac
  return 1
}

_ai_guard_temp_approval_is_valid() {
  local target_key="$1"
  local file="$AI_GUARD_TEMP_APPROVAL_FILE"
  [[ -n "$target_key" ]] || return 1
  [[ -f "$file" ]] || return 1

  local now
  now=$(date +%s 2>/dev/null) || return 1

  local entry_key entry_expiry
  local -a kept_lines=()
  local matched=1

  while IFS=$'\t' read -r entry_key entry_expiry; do
    [[ -n "$entry_key" && -n "$entry_expiry" ]] || continue
    [[ "$entry_expiry" =~ ^[0-9]+$ ]] || continue
    if (( entry_expiry > now )); then
      kept_lines+=("${entry_key}"$'\t'"${entry_expiry}")
      [[ "$entry_key" == "$target_key" ]] && matched=0
    fi
  done < "$file"

  if (( ${#kept_lines[@]} > 0 )); then
    printf "%s\n" "${kept_lines[@]}" >| "$file"
  else
    builtin command rm -f "$file" 2>/dev/null
  fi

  return $matched
}

_ai_guard_temp_approval_set() {
  local target_key="$1"
  local duration="${2:-$AI_GUARD_TEMP_APPROVAL_SECONDS}"
  local file="$AI_GUARD_TEMP_APPROVAL_FILE"
  [[ -n "$target_key" ]] || return 1
  [[ "$duration" =~ ^[0-9]+$ ]] || duration=180
  (( duration > 0 )) || duration=180

  local now expiry
  now=$(date +%s 2>/dev/null) || return 1
  expiry=$(( now + duration ))

  local entry_key entry_expiry
  local -a kept_lines=()

  if [[ -f "$file" ]]; then
    while IFS=$'\t' read -r entry_key entry_expiry; do
      [[ -n "$entry_key" && -n "$entry_expiry" ]] || continue
      [[ "$entry_expiry" =~ ^[0-9]+$ ]] || continue
      if (( entry_expiry > now )) && [[ "$entry_key" != "$target_key" ]]; then
        kept_lines+=("${entry_key}"$'\t'"${entry_expiry}")
      fi
    done < "$file"
  fi

  kept_lines+=("${target_key}"$'\t'"${expiry}")
  printf "%s\n" "${kept_lines[@]}" >| "$file"
  chmod 600 "$file" 2>/dev/null || true
  return 0
}

_ai_guard_temp_reject_is_valid() {
  local target_key="$1"
  local file="$AI_GUARD_TEMP_REJECT_FILE"
  [[ -n "$target_key" ]] || return 1
  [[ -f "$file" ]] || return 1

  local now
  now=$(date +%s 2>/dev/null) || return 1

  local entry_key entry_expiry
  local -a kept_lines=()
  local matched=1

  while IFS=$'\t' read -r entry_key entry_expiry; do
    [[ -n "$entry_key" && -n "$entry_expiry" ]] || continue
    [[ "$entry_expiry" =~ ^[0-9]+$ ]] || continue
    if (( entry_expiry > now )); then
      kept_lines+=("${entry_key}"$'\t'"${entry_expiry}")
      [[ "$entry_key" == "$target_key" ]] && matched=0
    fi
  done < "$file"

  if (( ${#kept_lines[@]} > 0 )); then
    printf "%s\n" "${kept_lines[@]}" >| "$file"
  else
    builtin command rm -f "$file" 2>/dev/null
  fi

  return $matched
}

_ai_guard_temp_reject_set() {
  local target_key="$1"
  local duration="${2:-$AI_GUARD_TEMP_REJECT_SECONDS}"
  local file="$AI_GUARD_TEMP_REJECT_FILE"
  [[ -n "$target_key" ]] || return 1
  [[ "$duration" =~ ^[0-9]+$ ]] || duration=180
  (( duration > 0 )) || duration=180

  local now expiry
  now=$(date +%s 2>/dev/null) || return 1
  expiry=$(( now + duration ))

  local entry_key entry_expiry
  local -a kept_lines=()

  if [[ -f "$file" ]]; then
    while IFS=$'\t' read -r entry_key entry_expiry; do
      [[ -n "$entry_key" && -n "$entry_expiry" ]] || continue
      [[ "$entry_expiry" =~ ^[0-9]+$ ]] || continue
      if (( entry_expiry > now )) && [[ "$entry_key" != "$target_key" ]]; then
        kept_lines+=("${entry_key}"$'\t'"${entry_expiry}")
      fi
    done < "$file"
  fi

  kept_lines+=("${target_key}"$'\t'"${expiry}")
  printf "%s\n" "${kept_lines[@]}" >| "$file"
  chmod 600 "$file" 2>/dev/null || true
  return 0
}

# ============================================================================

# Detect whether this shell is driven by an AI tool (Codex/Claude等)。
_ai_guard_is_ai_session() {
  [[ "${AI_GUARD_FORCE_AI:-0}" == "1" ]] && return 0

  local pcmd gp pid gp_pid
  pid=${PPID:-0}
  pcmd=$(ps -o command= -p "$pid" 2>/dev/null || true)
  gp_pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
  gp=$(ps -o command= -p "$gp_pid" 2>/dev/null || true)

  if _ai_guard_process_matches_ai "$pcmd"; then
    return 0
  fi
  if _ai_guard_process_matches_ai "$gp"; then
    return 0
  fi

  return 1
}

ai_extreme_confirm() {
  # xtraceが有効なシェルでも、この関数内のトレース出力を抑止してノイズを防ぐ
  setopt localoptions noxtrace
  if [[ "${AI_GUARD_ACTIVE:-0}" == "1" ]]; then
    builtin command "$@"
    return $?
  fi
  local _ai_guard_prev_active="${AI_GUARD_ACTIVE:-0}"
  AI_GUARD_ACTIVE=1
  local cmd="$1"; shift
  local args=("$@")
  # dispatch 側で条件判定済み。ここでは必ず確認を出す前提。
  local needs_prompt=1
  local log_file="$HOME/.ai_extreme_confirm.log"
  local log_ready=1

  if ! touch "$log_file" 2>/dev/null; then
    log_ready=0
    printf "⚠️ ログファイル %s を作成できませんでした。権限を確認してください。\n" "$log_file" >&2
  fi

  local cwd_short="" context_block="" context_for_log="" dialog_title_prefix=""
  {
    local cwd parent_proc
    cwd="$(pwd -P 2>/dev/null || pwd)"
    parent_proc="$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d '\n')"
    [[ -z "$parent_proc" ]] && parent_proc="(unknown)"

    # 末尾2階層を強調表示（例: /Users/kazuph/projects/myapp → projects/myapp）
    local parent_dir=$(dirname "$cwd")
    local last_two="${parent_dir##*/}/${cwd##*/}"
    [[ "$parent_dir" == "/" ]] && last_two="${cwd##*/}"
    [[ "$cwd" == "/" ]] && last_two="/"
    cwd_short="$last_two"
    [[ "$cwd" == "$HOME" ]] && cwd_short="~"

    # シンプルなコンテキストブロック（親プロセスはタイトルに移動）
    context_block=$'📁 '"$cwd_short"
    context_for_log="[cwd:${cwd}] [ppid:${parent_proc}]"

    # タイトルプレフィックス: 🤖 プロセス名 [tmux window: pane]
    dialog_title_prefix="🤖 ${parent_proc}"

    # tmux 情報を追加
    if [[ -n "${TMUX_PANE:-}" ]] && builtin command -v tmux >/dev/null 2>&1; then
      local tmux_window_name tmux_pane_title
      tmux_window_name=$(tmux display-message -p -t "${TMUX_PANE}" '#{window_name}' 2>/dev/null | tr -d '\n')
      tmux_pane_title=$(tmux display-message -p -t "${TMUX_PANE}" '#{pane_title}' 2>/dev/null | tr -d '\n')

      if [[ -n "$tmux_window_name" || -n "$tmux_pane_title" ]]; then
        dialog_title_prefix="${dialog_title_prefix} [${tmux_window_name:-?}: ${tmux_pane_title:-?}]"
        context_for_log="[tmux:${tmux_window_name}|${tmux_pane_title}] ${context_for_log}"
      fi
    fi

    dialog_title_prefix="${dialog_title_prefix} "
  } >/dev/null

  local cmd_display cmd_display_for_prompt
  cmd_display="$(printf "%s " "$cmd" "${args[@]}")"
  cmd_display="${cmd_display% }"
  if [[ -n "${AI_GUARD_CMD_DISPLAY:-}" ]]; then
    cmd_display="${AI_GUARD_CMD_DISPLAY}"
  fi
  cmd_display="${cmd_display//$'\n'/ }"
  cmd_display_for_prompt=$'💻 コマンド: '"$cmd_display"

  if (( needs_prompt )); then
    local dialog_output button_choice reason_text

    if [[ "${AI_GUARD_APPROVAL_MODE:-auto}" == "slack" || "${AI_GUARD_APPROVAL_MODE:-auto}" == "auto" ]]; then
      local slack_approve_script slack_title slack_detail
      slack_approve_script="$HOME/dotfiles/claude/skills/slack-ask/scripts/slack-approval.mjs"
      if [[ -f "$slack_approve_script" ]] && command -v node >/dev/null 2>&1; then
        slack_title="実行承認: ${cmd} @ ${cwd_short}"
        slack_detail=$'%s\n%s\n\n次のどれかで返信してください。\n・承認 理由\n・3分承認 理由\n・却下 理由\n・3分却下 理由'
        slack_detail=$(printf "$slack_detail" "$cmd_display_for_prompt" "$context_block")

        # Build structured meta JSON for rich Slack display
        local slack_meta_json _meta_branch _meta_cwd _meta_repo _meta_tmux
        _meta_cwd="$(pwd -P 2>/dev/null || pwd)"
        _meta_branch=$(builtin command git rev-parse --abbrev-ref HEAD 2>/dev/null) || _meta_branch=""
        _meta_repo=$(builtin command git rev-parse --show-toplevel 2>/dev/null) || _meta_repo=""
        [[ -n "$_meta_repo" ]] && _meta_repo="${_meta_repo##*/}"
        _meta_tmux=""
        if [[ -n "${TMUX_PANE:-}" ]]; then
          local _tw _tp
          _tw=$(tmux display-message -p -t "${TMUX_PANE}" '#{window_name}' 2>/dev/null | tr -d '\n')
          _tp=$(tmux display-message -p -t "${TMUX_PANE}" '#{pane_title}' 2>/dev/null | tr -d '\n')
          [[ -n "$_tw" || -n "$_tp" ]] && _meta_tmux="${_tw:-?}:${_tp:-?}"
        fi

        # Escape for JSON (minimal: backslash, double-quote, newline)
        local _esc_cmd _esc_full
        _esc_cmd="${cmd//\\/\\\\}"; _esc_cmd="${_esc_cmd//\"/\\\"}"
        _esc_full="${cmd_display//\\/\\\\}"; _esc_full="${_esc_full//\"/\\\"}"
        _esc_full="${_esc_full//$'\n'/\\n}"

        slack_meta_json=$(printf '{"cmd":"%s","full_cmd":"%s","dir":"%s","branch":"%s","repo":"%s","process":"%s","tmux":"%s"}' \
          "$_esc_cmd" "$_esc_full" "$_meta_cwd" "$_meta_branch" "$_meta_repo" "$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d '\n')" "$_meta_tmux")

        dialog_output=$(node "$slack_approve_script" --format shell --timeout-seconds 1800 --meta "$slack_meta_json" approve "$slack_title" "$slack_detail" 2>/dev/null) || dialog_output=""
      fi

      if [[ -z "$dialog_output" && "${AI_GUARD_APPROVAL_MODE:-auto}" == "slack" ]]; then
        reason_text="Slack 承認に失敗しました。"
        local reason_clean reason_for_log
        reason_clean="${reason_text//$'\n'/ }"
        reason_clean="${reason_clean//$'\t'/ }"
        reason_for_log="${reason_clean:-未入力} ${context_for_log}"
        printf "❌ Command cancelled: %s\n   理由: %s\n   %s\n" "$cmd_display" "$reason_text" "$context_block" >&2
        (( log_ready )) && printf "%s\tREJECT\t%s\t%s\n" "$(date -Iseconds)" "$cmd_display" "$reason_for_log" >> "$log_file"
        AI_GUARD_ACTIVE=${_ai_guard_prev_active}
        return 1
      fi
    fi

    # GUIダイアログは1回だけ試行し、失敗・却下なら即キャンセル扱い
    # （スクリプト等でGUIを出したくない場合: AI_GUARD_NO_GUI=1）
    if [[ -z "$dialog_output" && "${AI_GUARD_NO_GUI:-0}" != "1" ]] && command -v osascript >/dev/null 2>&1; then
      local tmp_as
      tmp_as=$(mktemp -t ai_guard_dialog) || tmp_as=""
      if [[ -n "$tmp_as" ]]; then
        cat <<'APPLESCRIPT' >| "$tmp_as"
on run argv
  set cmdText to item 1 of argv
  set ctxText to item 2 of argv
  set titleText to item 3 of argv
  set promptText to "⚠️ 本当に実行しますか？" & return & cmdText & return & ctxText & return & return & "承認/却下の理由を入力してください。"
  try
    set resp to display dialog promptText default answer "" buttons {"却下", "3分間承認", "承認"} default button "却下" with title titleText with icon stop
    return (button returned of resp) & linefeed & (text returned of resp)
  on error number -128
    return "ESC" & linefeed & ""
  end try
end run
APPLESCRIPT
        # タイトルに「[tmux window: pane title] コマンド @ ディレクトリ末尾2階層」を表示
        local dialog_title="${dialog_title_prefix}${cmd} @ ${cwd_short}"
        dialog_output=$(osascript "$tmp_as" "$cmd_display_for_prompt" "$context_block" "$dialog_title" 2>/dev/null) || dialog_output=""
        builtin command rm -f "$tmp_as"
      fi
    fi

    if [[ -n "$dialog_output" ]]; then
      button_choice="${dialog_output%%$'\n'*}"
      reason_text="${dialog_output#*$'\n'}"
    fi

    if [[ -z "$button_choice" ]]; then
      if [[ -t 0 && -t 1 ]]; then
        printf "⚠️ 本当に実行しますか？\n%s\n%s\n承認(y/yes) / 3分承認(t) / 3分却下(r) / 却下(その他)\n理由: " "$cmd_display_for_prompt" "$context_block" >&2
        read -r reason_text
        printf "選択 [y/t/r/N]: " >&2
        read -r button_choice
      else
        reason_text="ダイアログ表示に失敗 (osascript 応答なし/TTYなし)。"
        local reason_clean reason_for_log
        reason_clean="${reason_text//$'\n'/ }"
        reason_clean="${reason_clean//$'\t'/ }"
        reason_for_log="${reason_clean:-未入力} ${context_for_log}"
        printf "❌ Command cancelled: %s\n   理由: %s\n   %s\n" "$cmd_display" "$reason_text" "$context_block" >&2
        (( log_ready )) && printf "%s\tREJECT\t%s\t%s\n" "$(date -Iseconds)" "$cmd_display" "$reason_for_log" >> "$log_file"
        AI_GUARD_ACTIVE=${_ai_guard_prev_active}
        return 1
      fi
    fi

    local reason_clean log_reason
    reason_clean="${reason_text//$'\n'/ }"
    reason_clean="${reason_clean//$'\t'/ }"
    log_reason="${reason_clean:-未入力} ${context_for_log}"

    local allow_mode="ALLOW"
    local set_temp_approval=0
    local set_temp_reject=0
    if [[ "$button_choice" == "3分間承認" || "$button_choice" == "t" || "$button_choice" == "T" ]]; then
      allow_mode="TEMP_ALLOW"
      set_temp_approval=1
    elif [[ "$button_choice" == "3分間却下" || "$button_choice" == "r" || "$button_choice" == "R" ]]; then
      allow_mode="TEMP_REJECT"
      set_temp_reject=1
    elif [[ "$button_choice" != "承認" && "$button_choice" != "y" && "$button_choice" != "yes" && "$button_choice" != "Y" ]]; then
      printf "❌ Command cancelled: %s\n" "$cmd_display"
      printf "   理由: %s\n" "${reason_text:-未入力}"
      printf "   %s\n" "$context_block"
      (( log_ready )) && printf "%s\tREJECT\t%s\t%s\n" "$(date -Iseconds)" "$cmd_display" "$log_reason" >> "$log_file"
      AI_GUARD_ACTIVE=${_ai_guard_prev_active}
      return 1
    fi

    if (( set_temp_approval )); then
      if [[ "${AI_GUARD_TEMP_APPROVAL_DISABLED:-0}" == "1" ]]; then
        allow_mode="ALLOW"
        printf "ℹ️ このコマンドは常に確認対象のため、3分間承認は適用しません。\n" >&2
      else
        local temp_key="${AI_GUARD_TEMP_APPROVAL_KEY:-}"
        if ! _ai_guard_temp_approval_set "$temp_key" "$AI_GUARD_TEMP_APPROVAL_SECONDS"; then
          allow_mode="ALLOW"
          printf "⚠️ 3分間承認の保存に失敗したため、今回のみ承認として実行します。\n" >&2
        fi
      fi
    fi

    if (( set_temp_reject )); then
      if [[ "${AI_GUARD_TEMP_APPROVAL_DISABLED:-0}" == "1" ]]; then
        allow_mode="REJECT"
        printf "ℹ️ このコマンドは常に確認対象のため、3分間却下は適用しません。\n" >&2
      else
        local temp_key="${AI_GUARD_TEMP_APPROVAL_KEY:-}"
        if ! _ai_guard_temp_reject_set "$temp_key" "$AI_GUARD_TEMP_REJECT_SECONDS"; then
          printf "⚠️ 3分間却下の保存に失敗しましたが、今回は却下します。\n" >&2
        fi
      fi
      printf "❌ 3分間却下: %s (理由: %s)\n%s\n" "$cmd_display" "${reason_text:-未入力}" "$context_block"
      (( log_ready )) && printf "%s\tTEMP_REJECT\t%s\t%s\n" "$(date -Iseconds)" "$cmd_display" "$log_reason" >> "$log_file"
      AI_GUARD_ACTIVE=${_ai_guard_prev_active}
      return 1
    fi

    (( log_ready )) && printf "%s\t%s\t%s\t%s\n" "$(date -Iseconds)" "$allow_mode" "$cmd_display" "$log_reason" >> "$log_file"
    if [[ "$allow_mode" == "TEMP_ALLOW" ]]; then
      printf "✅ 3分間承認: %s (理由: %s)\n%s\n" "$cmd_display" "${reason_text:-未入力}" "$context_block"
    else
      printf "✅ 承認: %s (理由: %s)\n%s\n" "$cmd_display" "${reason_text:-未入力}" "$context_block"
    fi
  fi

  if [[ -n "${AI_GUARD_EXEC:-}" ]]; then
    eval "$AI_GUARD_EXEC"
  else
    builtin command "$cmd" "${args[@]}"
  fi
  AI_GUARD_ACTIVE=${_ai_guard_prev_active}
}

alias sudo='sudo '

# ファームウェア/セキュリティ周りは常にsudoを要求
alias nvram='sudo nvram'
alias csrutil='sudo csrutil'
alias spctl='sudo spctl'

export PATH="/opt/homebrew/opt/trash/bin:$PATH"

# --- guard policy ------------------------------------------------------
# 確認ダイアログを出す対象：
# - 単体コマンド: rm / rmdir / rimraf / trash / mv / dd / mkfs / fdisk / diskutil / format / parted / gparted
# - サブコマンド: git reset|restore|clean|stash|branch|rebase|cherry-pick|merge
# - publish / deploy: 引数のどこかに含まれていれば常に確認（npx cdk deploy 等も検知）
# ※ git push は確認不要
# ※ 新しいCLIツールを使う場合は _AI_GUARD_TARGETS に追加してください

# ファイル作成系コマンド（touch, tee, cp）も追加して .allow-main 作成を防止
_AI_GUARD_TARGETS=(rm rmdir rimraf trash mv dd mkfs fdisk diskutil format parted gparted git gh sh bash zsh dash ksh fish nu aws npm npx pnpm pnpx yarn bun bunx deno cargo firebase vercel flyctl fly wrangler netlify railway render amplify cdk serverless sls pulumi terraform touch tee cp ln)

_AI_GUARD_DANGER_WORDS=(publish deploy put)
_AI_GUARD_DANGER_REGEX="(^|[^[:alnum:]])($(printf "%s|" "${_AI_GUARD_DANGER_WORDS[@]}" | sed 's/|$//'))([^[:alnum:]]|$)"

# AIセッションの起動ディレクトリを取得（PPIDのcwd）
# キャッシュして複数回呼び出しを最適化
_AI_GUARD_LAUNCH_DIR_CACHE=""
_AI_GUARD_LAUNCH_GIT_ROOT_CACHE=""
_AI_GUARD_LAUNCH_GIT_COMMON_DIR_CACHE=""
_AI_GUARD_LAUNCH_CACHE_DONE=0

_ai_guard_get_ai_launch_dir() {
  # キャッシュ済みなら返す
  [[ "$_AI_GUARD_LAUNCH_CACHE_DONE" == "1" ]] && { printf "%s" "$_AI_GUARD_LAUNCH_DIR_CACHE"; return 0; }

  local ppid_cwd=""
  local pid="${PPID:-0}"

  # lsofでPPIDのcwdを取得（macOS対応）
  if command -v lsof >/dev/null 2>&1; then
    ppid_cwd=$(lsof -p "$pid" -Fn 2>/dev/null | awk '/^n\// && prev == "fcwd" {print substr($0,2); exit} {prev=$0}')
  fi

  # 取得できない場合は空を返す
  _AI_GUARD_LAUNCH_DIR_CACHE="$ppid_cwd"

  # gitルートとgit-common-dirも同時にキャッシュ
  if [[ -n "$ppid_cwd" ]]; then
    _AI_GUARD_LAUNCH_GIT_ROOT_CACHE=$(builtin command git -C "$ppid_cwd" rev-parse --show-toplevel 2>/dev/null) || _AI_GUARD_LAUNCH_GIT_ROOT_CACHE=""
    _AI_GUARD_LAUNCH_GIT_COMMON_DIR_CACHE=$(builtin command git -C "$ppid_cwd" rev-parse --git-common-dir 2>/dev/null) || _AI_GUARD_LAUNCH_GIT_COMMON_DIR_CACHE=""
    # 相対パスの場合は絶対パスに変換
    if [[ -n "$_AI_GUARD_LAUNCH_GIT_COMMON_DIR_CACHE" && "$_AI_GUARD_LAUNCH_GIT_COMMON_DIR_CACHE" != /* ]]; then
      _AI_GUARD_LAUNCH_GIT_COMMON_DIR_CACHE=$(cd "$ppid_cwd" && cd "$_AI_GUARD_LAUNCH_GIT_COMMON_DIR_CACHE" && pwd -P 2>/dev/null) || _AI_GUARD_LAUNCH_GIT_COMMON_DIR_CACHE=""
    fi
  fi

  _AI_GUARD_LAUNCH_CACHE_DONE=1
  printf "%s" "$_AI_GUARD_LAUNCH_DIR_CACHE"
}

_ai_guard_get_ai_launch_git_root() {
  # 先にキャッシュを確保
  [[ "$_AI_GUARD_LAUNCH_CACHE_DONE" != "1" ]] && _ai_guard_get_ai_launch_dir >/dev/null
  printf "%s" "$_AI_GUARD_LAUNCH_GIT_ROOT_CACHE"
}

_ai_guard_get_ai_launch_git_common_dir() {
  # 先にキャッシュを確保
  [[ "$_AI_GUARD_LAUNCH_CACHE_DONE" != "1" ]] && _ai_guard_get_ai_launch_dir >/dev/null
  printf "%s" "$_AI_GUARD_LAUNCH_GIT_COMMON_DIR_CACHE"
}

# 自動承認対象のパスかチェック
# - /tmp, /private/tmp, .artifacts/ 以下は常に自動承認
# - git管理下で起動された場合、そのリポジトリ内は自動承認
# - 同じgit-common-dirを持つworktreeも自動承認（main/master以外）
# - ホームディレクトリで起動された場合は常にダイアログ
# パストラバーサル攻撃を防ぐため .. を含むパスは拒否
_ai_guard_is_safe_rm_path() {
  local target="$1"

  # パストラバーサル（..）を含む場合は安全でないとみなす
  [[ "$target" == *..* ]] && return 1

  # 絶対パスに変換
  local abs_path
  if [[ "$target" == /* ]]; then
    abs_path="$target"
  else
    abs_path="$(pwd -P)/$target"
  fi

  # /tmp または /private/tmp 以下は常に自動承認
  [[ "$abs_path" == /tmp/* || "$abs_path" == /private/tmp/* || "$abs_path" == /tmp || "$abs_path" == /private/tmp ]] && return 0

  # .artifacts/ ディレクトリ内は常に自動承認
  [[ "$abs_path" == */.artifacts/* || "$abs_path" == */.artifacts ]] && return 0

  # AIセッションの場合、起動ディレクトリに基づく判定
  if _ai_guard_is_ai_session; then
    local launch_dir launch_git_root launch_git_common_dir
    launch_dir=$(_ai_guard_get_ai_launch_dir)

    # 起動ディレクトリがホームディレクトリの場合は常にダイアログ
    if [[ -z "$launch_dir" || "$launch_dir" == "$HOME" ]]; then
      return 1  # 安全でない = ダイアログ表示
    fi

    # git管理下で起動された場合
    launch_git_root=$(_ai_guard_get_ai_launch_git_root)
    launch_git_common_dir=$(_ai_guard_get_ai_launch_git_common_dir)
    if [[ -n "$launch_git_root" ]]; then
      # 対象パスが存在するディレクトリを特定
      local target_dir="$abs_path"
      [[ -f "$abs_path" ]] && target_dir=$(dirname "$abs_path")
      [[ ! -d "$target_dir" ]] && target_dir=$(dirname "$target_dir")

      # 対象パスのgit情報を取得
      local target_git_common_dir target_git_root target_branch
      target_git_root=$(builtin command git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null) || target_git_root=""
      target_git_common_dir=$(builtin command git -C "$target_dir" rev-parse --git-common-dir 2>/dev/null) || target_git_common_dir=""
      # 相対パスの場合は絶対パスに変換
      if [[ -n "$target_git_common_dir" && "$target_git_common_dir" != /* ]]; then
        target_git_common_dir=$(cd "$target_dir" && cd "$target_git_common_dir" && pwd -P 2>/dev/null) || target_git_common_dir=""
      fi

      # 同じgit-common-dirを持つ場合（同一リポジトリまたはworktree）
      if [[ -n "$target_git_common_dir" && -n "$launch_git_common_dir" && "$launch_git_common_dir" == "$target_git_common_dir" ]]; then
        # 対象がmain/masterブランチの場合
        target_branch=$(builtin command git -C "$target_dir" rev-parse --abbrev-ref HEAD 2>/dev/null) || target_branch=""
        if [[ "$target_branch" == "main" || "$target_branch" == "master" ]]; then
          # .allow-main があれば許可
          if [[ -n "$target_git_root" && -f "${target_git_root}/.allow-main" ]]; then
            return 0  # .allow-main により許可
          fi
          return 1  # main/masterはダイアログ表示
        fi
        # main/master以外は自動承認
        return 0
      fi

      # リポジトリ外はダイアログ
      return 1
    fi

    # git管理下でない場所で起動された場合もダイアログ
    return 1
  fi

  return 1
}

# rm系コマンドの全引数が安全なパスかチェック
_ai_guard_all_rm_paths_safe() {
  local arg
  for arg in "$@"; do
    # オプション（-で始まる）はスキップ
    [[ "$arg" == -* ]] && continue
    # 1つでも安全でないパスがあれば確認が必要
    _ai_guard_is_safe_rm_path "$arg" || return 1
  done
  return 0
}

_ai_guard_contains_danger_word() {
  local cmd_line="$*"
  [[ -n "$cmd_line" ]] || return 1
  local cmd_line_l="${cmd_line:l}"
  [[ "$cmd_line_l" =~ $_AI_GUARD_DANGER_REGEX ]] && return 0
  return 1
}

AI_GUARD_BLOCK_REASON=""
AI_GUARD_GIT_PUSH_DECISION=""
AI_GUARD_GH_PR_CREATE_DECISION=""
AI_GUARD_DANGER_WORD_ACK="0"
AI_GUARD_TRAP_ACTIVE="0"

_ai_guard_accept_line() {
  local cmd_line="$BUFFER"
  local cmd_trim="${cmd_line##[[:space:]]#}"
  local cmd_name="${cmd_trim%% *}"
  if [[ "$cmd_name" == "git" ]]; then
    zle .accept-line
    return 0
  fi
  if _ai_guard_contains_danger_word "$cmd_line"; then
    local prev_exec="${AI_GUARD_EXEC:-}"
    local prev_display="${AI_GUARD_CMD_DISPLAY:-}"
    AI_GUARD_EXEC=":"
    AI_GUARD_CMD_DISPLAY="$cmd_line"
    ai_extreme_confirm :
    local rc=$?
    AI_GUARD_EXEC="$prev_exec"
    AI_GUARD_CMD_DISPLAY="$prev_display"
    if [[ $rc -ne 0 ]]; then
      zle redisplay
      return 0
    fi
  fi
  zle .accept-line
}

if [[ -n "${ZSH_VERSION:-}" && -o interactive ]]; then
  zle -N accept-line _ai_guard_accept_line
fi

ai_guard_block() {
  local cmd_display="$1"
  local reason="$2"
  [[ -n "$reason" ]] || reason="理由不明"
  printf "❌ ブロック: %s\n" "$cmd_display" >&2
  printf "理由: %s\n" "$reason" >&2
  printf "本当に必要ならユーザーに依頼してください。\n" >&2
}

_ai_guard_extract_github_repo_full() {
  local url="$1"
  local repo_full=""
  [[ -n "$url" ]] || return 1
  if [[ "$url" == *github.com* ]]; then
    repo_full=$(printf "%s" "$url" | sed -E 's#.*github\.com[:/]+([^/]+/[^/]+)(\\.git)?#\\1#')
    if [[ -n "$repo_full" && "$repo_full" != "$url" ]]; then
      printf "%s" "$repo_full"
      return 0
    fi
  fi
  return 1
}

_ai_guard_resolve_repo_full() {
  local remote_url="$1"
  local repo_full=""
  [[ -n "$remote_url" ]] || return 1

  repo_full=$(builtin command gh repo view "$remote_url" --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null) || repo_full=""
  if [[ -n "$repo_full" ]]; then
    printf "%s" "$repo_full"
    return 0
  fi

  repo_full=$(_ai_guard_extract_github_repo_full "$remote_url") || repo_full=""
  if [[ -n "$repo_full" ]]; then
    printf "%s" "$repo_full"
    return 0
  fi

  return 1
}

_ai_guard_eval_git_push() {
  local subcmd="$1"; shift
  [[ "$subcmd" == "push" ]] || return 1

  AI_GUARD_BLOCK_REASON=""
  AI_GUARD_GIT_PUSH_DECISION="allow"

  # .allow-main ファイルが存在する場合は main/master への push を許可
  local git_root allow_main_flag=0
  git_root=$(builtin command git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$git_root" && -f "${git_root}/.allow-main" ]]; then
    allow_main_flag=1
  fi

  local arg remote_name="" remote_name_set=0
  for arg in "$@"; do
    case "$arg" in
      --force|-f)
        # --force は .allow-main があっても確認が必要
        AI_GUARD_BLOCK_REASON="--force/-f は確認が必要です。"
        AI_GUARD_GIT_PUSH_DECISION="prompt"
        return 0
        ;;
      main|*/main|*:main|master|*/master|*:master)
        # .allow-main がある場合は許可、なければブロック
        if [[ "$allow_main_flag" -eq 0 ]]; then
          AI_GUARD_BLOCK_REASON="main/master は禁止です。"
          AI_GUARD_GIT_PUSH_DECISION="block"
          return 0
        fi
        ;;
      --force-with-lease)
        AI_GUARD_BLOCK_REASON="--force-with-lease は確認が必要です。"
        AI_GUARD_GIT_PUSH_DECISION="prompt"
        return 0
        ;;
    esac
    if [[ "$arg" != -* && "$remote_name_set" -eq 0 ]]; then
      remote_name="$arg"
      remote_name_set=1
    fi
  done

  [[ -n "$remote_name" ]] || remote_name="origin"

  local remote_url repo_full owner my_login owner_type push_ok permission
  remote_url=$(builtin command git remote get-url "$remote_name" 2>/dev/null) || {
    AI_GUARD_GIT_PUSH_DECISION="prompt"
    return 0
  }
  repo_full=$(_ai_guard_resolve_repo_full "$remote_url") || repo_full=""
  if [[ -z "$repo_full" ]]; then
    AI_GUARD_GIT_PUSH_DECISION="prompt"
    return 0
  fi
  owner="${repo_full%%/*}"
  my_login=$(builtin command gh api /user --jq '.login' 2>/dev/null) || my_login=""
  if [[ -z "$my_login" ]]; then
    AI_GUARD_GIT_PUSH_DECISION="prompt"
    return 0
  fi

  if [[ "$owner" != "$my_login" ]]; then
    owner_type=$(builtin command gh api "repos/${repo_full}" --jq '.owner.type' 2>/dev/null) || owner_type=""
    push_ok=$(builtin command gh api "repos/${repo_full}" --jq '.permissions.push' 2>/dev/null) || push_ok=""
    if [[ -z "$owner_type" ]]; then
      AI_GUARD_GIT_PUSH_DECISION="prompt"
      return 0
    fi
    if [[ "$owner_type" == "Organization" ]]; then
      if [[ "$push_ok" == "true" ]]; then
        AI_GUARD_GIT_PUSH_DECISION="allow"
        return 0
      fi
      if [[ "$push_ok" == "false" ]]; then
        AI_GUARD_BLOCK_REASON="組織 (${owner}) への push 権限がないため禁止です。"
        AI_GUARD_GIT_PUSH_DECISION="block"
        return 0
      fi
      permission=$(builtin command gh api "repos/${repo_full}/collaborators/${my_login}/permission" --jq '.permission' 2>/dev/null) || permission=""
      case "$permission" in
        admin|maintain|write)
          AI_GUARD_GIT_PUSH_DECISION="allow"
          return 0
          ;;
        read|triage)
          AI_GUARD_BLOCK_REASON="組織 (${owner}) への push 権限がないため禁止です。"
          AI_GUARD_GIT_PUSH_DECISION="block"
          return 0
          ;;
      esac
      AI_GUARD_GIT_PUSH_DECISION="allow"
      return 0
    fi
    AI_GUARD_BLOCK_REASON="非所有リポジトリ (${owner}) への push は禁止です。"
    AI_GUARD_GIT_PUSH_DECISION="block"
    return 0
  fi

  AI_GUARD_GIT_PUSH_DECISION="allow"
  return 0
}

_ai_guard_eval_gh_pr_create() {
  local subcmd="$1"; shift
  [[ "$subcmd" == "pr" && "$1" == "create" ]] || return 1
  shift

  AI_GUARD_BLOCK_REASON=""
  AI_GUARD_GH_PR_CREATE_DECISION="allow"

  local target_repo="" head_ref="" arg prev=""
  for arg in "$@"; do
    if [[ "$prev" == "--repo" || "$prev" == "-R" ]]; then
      target_repo="$arg"
    elif [[ "$prev" == "--head" ]]; then
      head_ref="$arg"
    fi
    prev="$arg"
  done

  local is_fork parent_full parent_owner
  is_fork=$(builtin command gh repo view --json isFork --jq '.isFork' 2>/dev/null) || {
    AI_GUARD_GH_PR_CREATE_DECISION="prompt"
    return 0
  }

  if [[ "$is_fork" != "true" ]]; then
    AI_GUARD_GH_PR_CREATE_DECISION="allow"
    return 0
  fi

  parent_full=$(builtin command gh repo view --json parent --jq 'if .parent then (.parent.owner.login + "/" + .parent.name) else "" end' 2>/dev/null)
  parent_owner=$(builtin command gh repo view --json parent --jq 'if .parent then .parent.owner.login else "" end' 2>/dev/null)

  if [[ -z "$parent_full" || -z "$parent_owner" ]]; then
    AI_GUARD_GH_PR_CREATE_DECISION="prompt"
    return 0
  fi

  if [[ -z "$target_repo" || "$target_repo" == "$parent_full" ]]; then
    AI_GUARD_BLOCK_REASON="fork 事故防止のため、upstream への PR 作成は禁止です。"
    AI_GUARD_GH_PR_CREATE_DECISION="block"
    return 0
  fi

  if [[ -n "$head_ref" && "$head_ref" == "$parent_owner:"* ]]; then
    AI_GUARD_BLOCK_REASON="fork 事故防止のため、upstream への PR 作成は禁止です。"
    AI_GUARD_GH_PR_CREATE_DECISION="block"
    return 0
  fi

  AI_GUARD_GH_PR_CREATE_DECISION="allow"
  return 0
}

_ai_guard_is_target() {
  local cmd="$1"
  (( ${_AI_GUARD_TARGETS[(i)$cmd]} )) && return 0
  return 1
}

_ai_guard_need_prompt() {
  local cmd="$1"; shift
  local cmd_line="$cmd"
  if [[ "$#" -gt 0 ]]; then
    cmd_line="$cmd_line $*"
  fi

  if [[ "${AI_GUARD_DANGER_WORD_ACK:-0}" == "1" ]]; then
    return 1
  fi
  if _ai_guard_contains_danger_word "$cmd_line"; then
    return 0
  fi

  case "$cmd" in
    rmdir|rimraf|trash)
      # /tmp や .artifacts/ 以下は自動承認
      _ai_guard_all_rm_paths_safe "$@" && return 1
      return 0
      ;;
    mv)
      # backup/bak 系の単語が含まれる場合のみ確認（上書きバックアップ事故防止）
      local mv_args="$*"
      if [[ "$mv_args" =~ (backup|bak|\.bak|\.backup|_backup|_bak) ]]; then
        return 0
      fi
      return 1
      ;;
    dd|mkfs|fdisk|diskutil|format|parted|gparted) return 0 ;;
    git)
      # ※ git push は原則確認不要（所有判定不能時は別処理で確認）
      # 以下は未コミットの変更やコードを失う可能性があるため確認が必要
      case "$1" in
        reset|restore) return 0 ;;  # 変更を巻き戻す
        clean) return 0 ;;  # 追跡されていないファイルを削除
        stash)
          # stash drop / stash clear は確認が必要
          [[ "$2" == drop || "$2" == clear ]] && return 0
          ;;
        branch)
          # git branch -D (強制削除) は確認が必要
          [[ "$2" == -D || "$2" == -d || "$2" == --delete ]] && return 0
          ;;
        rebase) return 0 ;;  # 履歴を書き換える
        cherry-pick)
          # cherry-pick --abort は確認が必要
          [[ "$2" == --abort ]] && return 0
          ;;
        merge)
          # merge --abort は確認が必要
          [[ "$2" == --abort ]] && return 0
          ;;
        worktree)
          # worktree remove は安全なので確認不要
          return 1
          ;;
      esac
      ;;
    gh)
      case "$1" in
        pr)
          [[ "$2" == "merge" ]] && return 0
          ;;
        repo)
          if [[ "$2" == "edit" ]]; then
            [[ " $* " == *" --visibility "* || " $* " == *" --public "* || " $* " == *" --private "* ]] && return 0
          fi
          ;;
      esac
      ;;
    wrangler)
      # 動的設定ファイルを読み込んで許可リストをチェック（編集だけで即反映）
      [[ -f "$HOME/dotfiles/.ai_guard_config.zsh" ]] && source "$HOME/dotfiles/.ai_guard_config.zsh"
      local subcmd_pair="$1 $2"
      for allowed in "${_AI_GUARD_WRANGLER_ALLOW[@]}"; do
        [[ "$subcmd_pair" == "$allowed" ]] && return 1
      done
      ;;
  esac
  return 1
}

_ai_guard_confirm_with_temp_approval() {
  local cmd="$1"; shift
  local temp_key prev_temp_key prev_temp_disabled rc
  local use_temp_cache=1

  temp_key=$(_ai_guard_temp_approval_key "$cmd" "$@")
  [[ -z "$temp_key" ]] && use_temp_cache=0

  if (( use_temp_cache )) && _ai_guard_temp_reject_is_valid "$temp_key"; then
    local cmd_display log_file="$HOME/.ai_extreme_confirm.log"
    cmd_display="$(printf "%s " "$cmd" "$@")"
    cmd_display="${cmd_display% }"
    printf "❌ 3分間却下中のためキャンセル: %s\n" "$cmd_display" >&2
    printf "%s\tTEMP_REJECT_HIT\t%s\t[cached 3min reject]\n" "$(date -Iseconds)" "$cmd_display" >> "$log_file" 2>/dev/null
    return 1
  fi

  if (( use_temp_cache )) && _ai_guard_temp_approval_is_valid "$temp_key"; then
    builtin command "$cmd" "$@"
    return $?
  fi

  prev_temp_disabled="${AI_GUARD_TEMP_APPROVAL_DISABLED:-0}"
  prev_temp_key="${AI_GUARD_TEMP_APPROVAL_KEY:-}"
  if (( use_temp_cache )); then
    AI_GUARD_TEMP_APPROVAL_DISABLED=0
    AI_GUARD_TEMP_APPROVAL_KEY="$temp_key"
  else
    AI_GUARD_TEMP_APPROVAL_DISABLED=1
    AI_GUARD_TEMP_APPROVAL_KEY=""
  fi
  ai_extreme_confirm "$cmd" "$@"
  rc=$?
  AI_GUARD_TEMP_APPROVAL_KEY="$prev_temp_key"
  AI_GUARD_TEMP_APPROVAL_DISABLED="$prev_temp_disabled"
  return $rc
}

_ai_guard_dispatch() {
  local cmd="$1"; shift
  local full_cmd="$cmd $*"

  # CRITICAL: AIセッションで保護パターンを含む場合は即時ブロック（最優先）
  if _ai_guard_is_ai_session && _ai_guard_check_protected_pattern "$full_cmd"; then
    _ai_guard_block_protected "$full_cmd"
    return 1
  fi

  # rm は通常の確認フローに従う（ブロックしない）

  # Humanセッションではガードを通さず即実行
  if _ai_guard_is_ai_session; then :; else
    builtin command "$cmd" "$@"
    return $?
  fi
  if [[ "${AI_GUARD_ACTIVE:-0}" == "1" ]]; then
    builtin command "$cmd" "$@"
    return $?
  fi

  local cmd_display
  cmd_display="$(printf "%s " "$cmd" "$@")"
  cmd_display="${cmd_display% }"

  # git checkout -b のブロック（Humanのみ。AIは許可）
  if [[ "$cmd" == "git" ]] && ! _ai_guard_is_ai_session && _ai_guard_is_checkout_b "$cmd_display"; then
    _ai_guard_block_checkout_b "$cmd_display"
    return 1
  fi

  if [[ "$cmd" == "git" ]] && _ai_guard_eval_git_push "$@"; then
    case "$AI_GUARD_GIT_PUSH_DECISION" in
      block)
        ai_guard_block "$cmd_display" "$AI_GUARD_BLOCK_REASON"
        return 1
        ;;
      prompt)
        _ai_guard_confirm_with_temp_approval "$cmd" "$@"
        return $?
        ;;
    esac
  fi

  if [[ "$cmd" == "gh" ]] && _ai_guard_eval_gh_pr_create "$@"; then
    case "$AI_GUARD_GH_PR_CREATE_DECISION" in
      block)
        ai_guard_block "$cmd_display" "$AI_GUARD_BLOCK_REASON"
        return 1
        ;;
      prompt)
        _ai_guard_confirm_with_temp_approval "$cmd" "$@"
        return $?
        ;;
    esac
  fi

  if _ai_guard_need_prompt "$cmd" "$@"; then
    _ai_guard_confirm_with_temp_approval "$cmd" "$@"
    return $?
  else
    builtin command "$cmd" "$@"
  fi
}

# 対象コマンドは一括でラップ
for _ai_cmd in "${_AI_GUARD_TARGETS[@]}"; do
  eval "${_ai_cmd}() { _ai_guard_dispatch ${_ai_cmd} \"\$@\"; }"
done
unset _ai_cmd

# 既存 reset エイリアスを保護付きで実行
unalias reset 2>/dev/null
reset() {
  local exec_cmd="brake db:migrate:reset"
  AI_GUARD_EXEC="$exec_cmd" ai_extreme_confirm reset
}

# command 経由のバイパスも捕捉
command() {
  local cmd="$1"; shift
  local full_cmd="$cmd $*"

  # CRITICAL: AIセッションで保護パターンを含む場合は即時ブロック
  if _ai_guard_is_ai_session && _ai_guard_check_protected_pattern "$full_cmd"; then
    _ai_guard_block_protected "$full_cmd"
    return 1
  fi

  if _ai_guard_is_ai_session; then :; else
    builtin command "$cmd" "$@"
    return $?
  fi
  # ガード内部からの呼び出しはバイパスして無限ループを防ぐ
  if [[ "${AI_GUARD_ACTIVE:-0}" == "1" ]]; then
    builtin command "$cmd" "$@"
    return $?
  fi
  if _ai_guard_is_target "$cmd"; then
    _ai_guard_dispatch "$cmd" "$@"
  else
    builtin command "$cmd" "$@"
  fi
}

# ============================================================================
# preexec フック: 全コマンド実行前の最終防衛線
# ラップされていないコマンドも含め、全てのコマンドをチェック
# ============================================================================
_ai_guard_preexec_protected_check() {
  local cmd_line="$1"

  # git checkout -b のブロック（Humanのみ、preexec での警告）
  # ※ 実際のブロックは accept-line で行われるが、万が一のための警告
  if ! _ai_guard_is_ai_session && _ai_guard_is_checkout_b "$cmd_line"; then
    _ai_guard_block_checkout_b "$cmd_line"
    return 1
  fi

  # AIセッションでない場合は以降のチェックをスキップ
  _ai_guard_is_ai_session || return 0

  # 保護パターンを含む場合はブロック
  if _ai_guard_check_protected_pattern "$cmd_line"; then
    _ai_guard_block_protected "$cmd_line"
    # preexec からはコマンドを中断できないため、
    # 代わりに BUFFER を空にして実行を防ぐ
    # ただし preexec は実行前の最後の通知なので、
    # 実際のブロックは precmd/accept-line で行う必要がある
    return 1
  fi

  return 0
}

# precmd フック用のフラグ
_AI_GUARD_BLOCKED_CMD=""

# accept-line をオーバーライドして、保護パターンを含むコマンドをブロック
_ai_guard_accept_line_protected() {
  local cmd_line="$BUFFER"

  # AIセッションで保護パターンを含む場合はブロック
  if _ai_guard_is_ai_session && _ai_guard_check_protected_pattern "$cmd_line"; then
    _ai_guard_block_protected "$cmd_line"
    BUFFER=""
    zle redisplay
    return 0
  fi

  # git checkout -b のブロック（Humanのみ）
  if ! _ai_guard_is_ai_session && _ai_guard_is_checkout_b "$cmd_line"; then
    _ai_guard_block_checkout_b "$cmd_line"
    BUFFER=""
    zle redisplay
    return 0
  fi

  # 元の accept-line 処理を実行
  # danger word チェック（既存の _ai_guard_accept_line のロジック）
  local cmd_trim="${cmd_line##[[:space:]]#}"
  local cmd_name="${cmd_trim%% *}"
  if [[ "$cmd_name" == "git" ]]; then
    zle .accept-line
    return 0
  fi
  if _ai_guard_contains_danger_word "$cmd_line"; then
    local prev_exec="${AI_GUARD_EXEC:-}"
    local prev_display="${AI_GUARD_CMD_DISPLAY:-}"
    AI_GUARD_EXEC=":"
    AI_GUARD_CMD_DISPLAY="$cmd_line"
    ai_extreme_confirm :
    local rc=$?
    AI_GUARD_EXEC="$prev_exec"
    AI_GUARD_CMD_DISPLAY="$prev_display"
    if [[ $rc -ne 0 ]]; then
      zle redisplay
      return 0
    fi
  fi
  zle .accept-line
}

# 対話シェルの場合、accept-line を再定義
if [[ -n "${ZSH_VERSION:-}" && -o interactive ]]; then
  zle -N accept-line _ai_guard_accept_line_protected
fi

# preexec フックも追加（二重防御）
if [[ -n "${ZSH_VERSION:-}" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _ai_guard_preexec_protected_check
fi
