# ai_guard: 危険コマンドの実行前に確認を挟み、ログを残す
# 非対話シェルでも可能ならダイアログを出し、失敗時のみ安全側に倒す
[[ -n ${AI_GUARD_LOADED:-} ]] && return
AI_GUARD_LOADED=1

# Detect whether this shell is driven by an AI tool (Codex/Claude等)。
_ai_guard_is_ai_session() {
  [[ "${AI_GUARD_FORCE_AI:-0}" == "1" ]] && return 0

  local pcmd gp pid gp_pid
  pid=${PPID:-0}
  pcmd=$(ps -o command= -p "$pid" 2>/dev/null || true)
  gp_pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
  gp=$(ps -o command= -p "$gp_pid" 2>/dev/null || true)

  if echo "$pcmd" | grep -qiE 'codex|claude|anthropic|openai|aider'; then
    return 0
  fi
  if echo "$gp" | grep -qiE 'codex|claude|anthropic|openai|aider'; then
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

  {
    local cwd shell_proc parent_proc tty_name context_block context_for_log tmux_info tmux_window_name tmux_window_index
    cwd="$(pwd -P 2>/dev/null || pwd)"
    shell_proc="$(ps -o comm= -p "$$" 2>/dev/null | tr -d '\n')"
    parent_proc="$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d '\n')"
    tty_name="$(tty 2>/dev/null || true)"
    [[ -z "$tty_name" ]] && tty_name="(not a tty)"
    [[ -z "$shell_proc" ]] && shell_proc="(unknown)"
    [[ -z "$parent_proc" ]] && parent_proc="(unknown)"
    local base_context_block cwd_display
    if [[ "$cwd" == "$HOME" ]]; then
      cwd_display="~"
    elif [[ "$cwd" == "$HOME"/* ]]; then
      cwd_display="~/${cwd#"$HOME/"}"
    else
      cwd_display="$cwd"
    fi
    base_context_block=$'- 実行ディレクトリ: '"$cwd_display"$'\n- シェル: '"$shell_proc"$'\n- 親プロセス: '"$parent_proc"$'\n- TTY: '"$tty_name"
    context_for_log="[cwd:${cwd}] [shell:${shell_proc}] [ppid:${parent_proc}] [tty:${tty_name}]"

    # tmux 情報（TMUX_PANE が祖先プロセスの pane と一致する場合のみ）
    local tmux_force="${AI_GUARD_TMUX_FORCE:-}"

    local tmux_context_block=""
    if [[ -n "${TMUX_PANE:-}" ]] && builtin command -v tmux >/dev/null 2>&1; then
      local tmux_window_index tmux_window_name tmux_pane_id tmux_pane_title
      tmux_window_name=$(tmux display-message -p -t "${TMUX_PANE}" '#{window_name}' 2>/dev/null | tr -d '\n')
      tmux_window_index=$(tmux display-message -p -t "${TMUX_PANE}" '#{window_index}' 2>/dev/null | tr -d '\n')
      tmux_pane_id=$(tmux display-message -p -t "${TMUX_PANE}" '#{pane_id}' 2>/dev/null | tr -d '\n')
      tmux_pane_title=$(tmux display-message -p -t "${TMUX_PANE}" '#{pane_title}' 2>/dev/null | tr -d '\n')

      if [[ -n "$tmux_window_name" || -n "$tmux_window_index" || -n "$tmux_pane_id" ]]; then
        tmux_info="[tmux ${tmux_window_index:-?}-${tmux_pane_id:-?}] ${tmux_window_name:-(no-name)}"
        local tmux_title_block=""
        if [[ -n "$tmux_pane_title" ]]; then
          tmux_title_block=$'\n- tmux pane title: '"$tmux_pane_title"
        fi
        tmux_context_block=$'- tmux: '"$tmux_info"$tmux_title_block$'\n'
        context_for_log="[tmux:${tmux_info}${tmux_pane_title:+ |title:${tmux_pane_title}}] ${context_for_log}"
      fi
    fi

    # 表示用コンテキストを組み立て（tmux情報→その他）
    local context_block
    context_block="$tmux_context_block$base_context_block"
  } >/dev/null

  local cmd_display cmd_display_for_prompt
  cmd_display="$(printf "%s " "$cmd" "${args[@]}")"
  cmd_display="${cmd_display% }"
  cmd_display_for_prompt=$'- コマンド: '"$cmd_display"

  if (( needs_prompt )); then
    local dialog_output button_choice reason_text

    # GUIダイアログは1回だけ試行し、失敗・却下なら即キャンセル扱い
    # （スクリプト等でGUIを出したくない場合: AI_GUARD_NO_GUI=1）
    if [[ "${AI_GUARD_NO_GUI:-0}" != "1" ]] && command -v osascript >/dev/null 2>&1; then
      local tmp_as
      tmp_as=$(mktemp -t ai_guard_dialog) || tmp_as=""
      if [[ -n "$tmp_as" ]]; then
        cat <<'APPLESCRIPT' >| "$tmp_as"
on run argv
  set cmdText to item 1 of argv
  set ctxText to item 2 of argv
  set promptText to "⚠️ 本当に実行しますか？" & return & cmdText & return & ctxText & return & return & "承認/却下の理由を入力してください。"
  try
    set resp to display dialog promptText default answer "" buttons {"却下", "承認"} default button "却下" with icon stop
    return (button returned of resp) & linefeed & (text returned of resp)
  on error number -128
    return "ESC" & linefeed & ""
  end try
end run
APPLESCRIPT
        dialog_output=$(osascript "$tmp_as" "$cmd_display_for_prompt" "$context_block" 2>/dev/null) || dialog_output=""
        rm -f "$tmp_as"
      fi
    fi

    if [[ -n "$dialog_output" ]]; then
      button_choice="${dialog_output%%$'\n'*}"
      reason_text="${dialog_output#*$'\n'}"
    fi

    if [[ -z "$button_choice" ]]; then
      if [[ -t 0 && -t 1 ]]; then
        printf "⚠️ 本当に実行しますか？\n%s\n%s\n承認する場合は y/yes を入力してください。\n理由: " "$cmd_display_for_prompt" "$context_block" >&2
        read -r reason_text
        printf "承認しますか？ [y/N]: " >&2
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

    if [[ "$button_choice" != "承認" && "$button_choice" != "y" && "$button_choice" != "yes" && "$button_choice" != "Y" ]]; then
      printf "❌ Command cancelled: %s\n" "$cmd_display"
      printf "   理由: %s\n" "${reason_text:-未入力}"
      printf "   %s\n" "$context_block"
      (( log_ready )) && printf "%s\tREJECT\t%s\t%s\n" "$(date -Iseconds)" "$cmd_display" "$log_reason" >> "$log_file"
      AI_GUARD_ACTIVE=${_ai_guard_prev_active}
      return 1
    fi

    (( log_ready )) && printf "%s\tALLOW\t%s\t%s\n" "$(date -Iseconds)" "$cmd_display" "$log_reason" >> "$log_file"
    printf "✅ 承認: %s (理由: %s)\n%s\n" "$cmd_display" "${reason_text:-未入力}" "$context_block"
  fi

  if [[ "$cmd" == "rm" ]]; then
    if command -v trash >/dev/null 2>/dev/null; then
      builtin command trash "${args[@]}"
    else
      builtin command rm "${args[@]}"
    fi
  else
    if [[ -n "${AI_GUARD_EXEC:-}" ]]; then
      eval "$AI_GUARD_EXEC"
    else
      builtin command "$cmd" "${args[@]}"
    fi
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
# - サブコマンド: git reset|restore|checkout|clean|stash|branch|rebase|cherry-pick|merge
# - publish / deploy: 引数のどこかに含まれていれば常に確認（npx cdk deploy 等も検知）
# ※ git push は確認不要
# ※ 新しいCLIツールを使う場合は _AI_GUARD_TARGETS に追加してください

_AI_GUARD_TARGETS=(rm rmdir rimraf trash mv dd mkfs fdisk diskutil format parted gparted git gh npm npx pnpm pnpx yarn bun bunx deno cargo firebase vercel flyctl fly wrangler netlify railway render amplify cdk serverless sls pulumi terraform)

# 自動承認対象のパスかチェック（/tmp, /private/tmp, .artifacts/ 以下）
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

  # /tmp または /private/tmp 以下
  [[ "$abs_path" == /tmp/* || "$abs_path" == /private/tmp/* || "$abs_path" == /tmp || "$abs_path" == /private/tmp ]] && return 0

  # .artifacts/ ディレクトリ内
  [[ "$abs_path" == */.artifacts/* || "$abs_path" == */.artifacts ]] && return 0

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

AI_GUARD_BLOCK_REASON=""
AI_GUARD_GIT_PUSH_DECISION=""
AI_GUARD_GH_PR_CREATE_DECISION=""

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

  local arg remote_name="" remote_name_set=0
  for arg in "$@"; do
    case "$arg" in
      --force|-f|main|*/main|*:main|master|*/master|*:master)
        AI_GUARD_BLOCK_REASON="main/master/--force/-f は禁止です。"
        AI_GUARD_GIT_PUSH_DECISION="block"
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

  # グローバルチェック: 引数のどこかに publish または deploy が含まれていれば確認
  # npx cdk deploy, bunx serverless deploy 等のケースに対応
  local arg
  for arg in "$@"; do
    [[ "$arg" == publish || "$arg" == deploy ]] && return 0
  done

  case "$cmd" in
    rm|rmdir|rimraf|trash)
      # /tmp や .artifacts/ 以下は自動承認
      _ai_guard_all_rm_paths_safe "$@" && return 1
      return 0
      ;;
    mv)
      # /tmp や .artifacts/ 以下への移動は自動承認
      _ai_guard_all_rm_paths_safe "$@" && return 1
      return 0
      ;;
    dd|mkfs|fdisk|diskutil|format|parted|gparted) return 0 ;;
    git)
      # ※ git push は原則確認不要（所有判定不能時は別処理で確認）
      # 以下は未コミットの変更やコードを失う可能性があるため確認が必要
      case "$1" in
        reset|restore) return 0 ;;  # 変更を巻き戻す
        checkout)
          # git checkout <branch> は許可、git checkout <file> や -- <file> は確認
          # 引数が2つ以上あるか、-- が含まれる場合はファイル復元の可能性
          [[ $# -ge 2 || "$*" == *" -- "* || "$2" == -* ]] && return 0
          ;;
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
  esac
  return 1
}

_ai_guard_dispatch() {
  local cmd="$1"; shift
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

  if [[ "$cmd" == "git" ]] && _ai_guard_eval_git_push "$@"; then
    case "$AI_GUARD_GIT_PUSH_DECISION" in
      block)
        ai_guard_block "$cmd_display" "$AI_GUARD_BLOCK_REASON"
        return 1
        ;;
      prompt)
        ai_extreme_confirm "$cmd" "$@"
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
        ai_extreme_confirm "$cmd" "$@"
        return $?
        ;;
    esac
  fi

  if _ai_guard_need_prompt "$cmd" "$@"; then
    ai_extreme_confirm "$cmd" "$@"
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
