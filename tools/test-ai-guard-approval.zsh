#!/usr/bin/env zsh
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/ai_guard_test.XXXXXX")
fake_home="$tmpdir/home"
fake_bin="$tmpdir/bin"
fake_dotfiles="$fake_home/dotfiles"
fake_skill_dir="$fake_dotfiles/claude/skills/slack-ask/scripts"
pid_file="$tmpdir/osascript.pid"
event_file="$tmpdir/osascript.events"

cleanup() {
  if [[ -f "$pid_file" ]]; then
    local pid
    pid=$(<"$pid_file")
    case "$pid" in
      ''|*[!0-9]*) ;;
      *)
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      ;;
    esac
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT INT TERM

mkdir -p "$fake_skill_dir" "$fake_bin"
: >| "$event_file"
chmod 700 "$fake_bin"

print -r -- '#!/usr/bin/env bash
set -euo pipefail
cmd=""
for arg in "$@"; do
  case "$arg" in
    approve-post|approve-wait|approve-resolve)
      cmd="$arg"
      ;;
  esac
done
case "$cmd" in
  approve-post)
    printf "{\"ts\":\"thread123\"}\n"
    ;;
  approve-wait)
    sleep 0.3
    printf "承認\nSlack approval\n"
    ;;
  approve-resolve)
    ;;
  *)
    echo "unexpected node args: $*" >&2
    exit 1
    ;;
esac
' >| "$fake_bin/node"

print -r -- '#!/usr/bin/env bash
set -euo pipefail
printf "thread123\n"
' >| "$fake_bin/jq"

print -r -- '#!/usr/bin/env bash
set -euo pipefail
: "${FAKE_OSASCRIPT_PID_FILE:?}"
: "${FAKE_OSASCRIPT_EVENT_FILE:?}"
printf "%s\n" "$$" >| "$FAKE_OSASCRIPT_PID_FILE"
printf "started\n" >> "$FAKE_OSASCRIPT_EVENT_FILE"
trap '"'"'printf "terminated\n" >> "$FAKE_OSASCRIPT_EVENT_FILE"; exit 0'"'"' TERM INT HUP
while :; do
  read -r -t 1 _ || true
done
' >| "$fake_bin/osascript"

chmod 755 "$fake_bin/node" "$fake_bin/jq" "$fake_bin/osascript"
touch "$fake_skill_dir/slack-approval.mjs"

export HOME="$fake_home"
export PATH="$fake_bin:$PATH"
export FAKE_OSASCRIPT_PID_FILE="$pid_file"
export FAKE_OSASCRIPT_EVENT_FILE="$event_file"
export AI_GUARD_FORCE_AI=1
export AI_GUARD_APPROVAL_MODE=auto
export AI_GUARD_NO_GUI=0
export AI_GUARD_EXEC=':'

source "$repo_root/.config/shell/ai-guard-common.sh"
source "$repo_root/.ai_guard.zsh"

ai_extreme_confirm echo guarded-command >/dev/null
sleep 0.5

if [[ ! -f "$pid_file" ]]; then
  echo "FAIL: osascript pid was not recorded" >&2
  exit 1
fi

osascript_pid=$(<"$pid_file")
case "$osascript_pid" in
  ''|*[!0-9]*)
    echo "FAIL: invalid osascript pid: $osascript_pid" >&2
    exit 1
    ;;
esac

if kill -0 "$osascript_pid" 2>/dev/null; then
  echo "FAIL: osascript is still running after Slack approval" >&2
  exit 1
fi

if ! grep -q '^terminated$' "$event_file"; then
  echo "FAIL: osascript did not receive termination signal" >&2
  exit 1
fi

echo "PASS: Slack approval closes the AppleScript dialog"
