#!/bin/bash
input=$(cat)

USD_JPY=150  # Fixed rate — update occasionally

# --- Platform detection ---
IS_MACOS=false
[[ "$(uname -s)" == "Darwin" ]] && IS_MACOS=true

# Portable tmp directory (Termux cannot write to /tmp)
if [[ -d "/data/data/com.termux/files/usr/tmp" ]]; then
  TMPBASE="/data/data/com.termux/files/usr/tmp"
else
  TMPBASE="/tmp"
fi

# Portable stat: return mtime as epoch seconds
portable_mtime() {
  if $IS_MACOS; then
    stat -f %m "$1" 2>/dev/null || echo 0
  else
    stat -c %Y "$1" 2>/dev/null || echo 0
  fi
}

# --- Usage Limits (API fetch with cache) ---
USAGE_CACHE="$TMPBASE/claude-statusline-usage.json"
USAGE_STAMP="$TMPBASE/claude-statusline-usage.stamp"
USAGE_LOCK="$TMPBASE/claude-statusline-usage.lock"
USAGE_CACHE_AGE=300   # seconds between successful refreshes
USAGE_RETRY_AGE=60    # seconds between retry after failure
USAGE_STALE_MAX=1800  # seconds — hide usage if data older than 30 min

fetch_usage() {
  local token="" creds=""
  if $IS_MACOS; then
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) || return 1
  else
    # Linux/Termux: read credentials from Claude Code's JSON store
    local cred_file="${HOME}/.claude/.credentials.json"
    [[ -f "$cred_file" ]] || return 1
    creds=$(cat "$cred_file" 2>/dev/null) || return 1
  fi
  token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  [[ -z "$token" ]] && return 1
  local tmp="${USAGE_CACHE}.tmp.$$"
  if curl -s --max-time 3 "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Content-Type: application/json" -o "$tmp" 2>/dev/null \
    && [[ -s "$tmp" ]] \
    && jq -e '.five_hour' "$tmp" >/dev/null 2>&1; then
    mv -f "$tmp" "$USAGE_CACHE"
  else
    rm -f "$tmp"
  fi
  # Always update stamp (tracks last attempt, not last success)
  date +%s > "$USAGE_STAMP"
}

# Stale lock recovery: if lock is older than 30s, the holder likely crashed
recover_stale_lock() {
  local lock_pid_file="$USAGE_LOCK/pid"
  if [[ -d "$USAGE_LOCK" ]]; then
    local lock_age=$(( $(date +%s) - $(portable_mtime "$USAGE_LOCK") ))
    if (( lock_age > 30 )); then
      # Lock holder likely dead — reclaim
      rm -rf "$USAGE_LOCK"
      return 0
    fi
    # Check if PID is still alive
    if [[ -f "$lock_pid_file" ]]; then
      local lock_pid
      lock_pid=$(<"$lock_pid_file")
      if ! kill -0 "$lock_pid" 2>/dev/null; then
        rm -rf "$USAGE_LOCK"
        return 0
      fi
    fi
    return 1  # lock is valid
  fi
  return 0  # no lock exists
}

# Decide whether to refresh
needs_refresh=false
NOW=$(date +%s)
LAST_ATTEMPT=$(cat "$USAGE_STAMP" 2>/dev/null || echo 0)

if [[ ! -f "$USAGE_CACHE" ]]; then
  needs_refresh=true
elif (( NOW - $(portable_mtime "$USAGE_CACHE") > USAGE_CACHE_AGE )) \
  && (( NOW - LAST_ATTEMPT > USAGE_RETRY_AGE )); then
  needs_refresh=true
fi

if $needs_refresh; then
  recover_stale_lock
  if mkdir "$USAGE_LOCK" 2>/dev/null; then
    echo $$ > "$USAGE_LOCK/pid"
    fetch_usage
    rm -rf "$USAGE_LOCK"
  fi
fi

# Read usage cache in one jq call (performance: avoid 3 separate jq invocations)
if [[ -f "$USAGE_CACHE" ]]; then
  CACHE_AGE=$(( NOW - $(portable_mtime "$USAGE_CACHE") ))
  if (( CACHE_AGE < USAGE_STALE_MAX )); then
    eval "$(jq -r '
      "USAGE_5H=" + (.five_hour.utilization // 0 | floor | tostring),
      "USAGE_7D=" + (.seven_day.utilization // 0 | floor | tostring),
      "RESETS_5H=" + (.five_hour.resets_at // "" | @sh)
    ' "$USAGE_CACHE" 2>/dev/null)"
  fi
fi

# Parse stdin JSON — single jq call for all fields
eval "$(echo "$input" | jq -r '
  "MODEL=" + (@sh "\(.model.display_name // "?")"),
  "CWD=" + (@sh "\(.workspace.current_dir // "")"),
  "PROJECT_DIR=" + (@sh "\(.workspace.project_dir // "")"),
  "PCT=" + (@sh "\(.context_window.used_percentage // 0 | floor | tostring)"),
  "CTX_SIZE=" + (@sh "\(.context_window.context_window_size // 200000 | tostring)"),
  "LINES_ADD=" + (@sh "\(.cost.total_lines_added // 0 | tostring)"),
  "LINES_DEL=" + (@sh "\(.cost.total_lines_removed // 0 | tostring)"),
  "WT_BRANCH=" + (@sh "\(.worktree.branch // "")"),
  "COST_USD=" + (@sh "\(.cost.total_cost_usd // 0 | tostring)")
' 2>/dev/null)" || true

# --- Colors ---
RST='\033[0m'; DIM='\033[2m'; BOLD='\033[1m'
CYAN='\033[36m'; MAGENTA='\033[35m'; BLUE='\033[34m'
GREEN='\033[32m'; RED='\033[31m'; YELLOW='\033[33m'

# Git branch — prefer WT_BRANCH from stdin JSON, fallback to git command
BRANCH="${WT_BRANCH}"
if [[ -z "$BRANCH" && -n "$PROJECT_DIR" ]] && command -v git >/dev/null 2>&1; then
  BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

# Replace $HOME with ~
DIR_PATH="${CWD/#$HOME/~}"

# NerdFont git branch icon
GIT_ICON=$'\xee\x82\xa0'  # U+E0A0

# --- Line 1: model | branch | dir ---
L1="${BOLD}${CYAN}${MODEL}${RST} ${DIM}|${RST} "
if [[ -n "$BRANCH" ]]; then
  L1+="${MAGENTA}${GIT_ICON} ${BRANCH}${RST}"
  if (( LINES_ADD > 0 || LINES_DEL > 0 )); then
    L1+=" ${GREEN}+${LINES_ADD}${RST}${DIM}/${RST}${RED}-${LINES_DEL}${RST}"
  fi
  L1+=" ${DIM}|${RST} "
fi
L1+="${BLUE}${DIR_PATH}${RST}"

# --- Helper: build a bar ---
make_bar() {
  local pct=$1 width=$2 color=$3
  (( pct > 100 )) && pct=100
  (( pct < 0 )) && pct=0
  local filled=$((pct * width / 100))
  local empty=$((width - filled))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="▓"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  printf '%b' "${color}${bar}${RST}"
}

# Color by percentage
bar_color() {
  local pct=$1
  if (( pct < 50 )); then printf '%b' "$GREEN"
  elif (( pct < 80 )); then printf '%b' "$YELLOW"
  else printf '%b' "$RED"; fi
}

# --- Line 2: three bars (context | 5h | 7d) + cost ---
# Dynamic BAR_WIDTH based on terminal width
# Fixed text in L2 (worst case with reset label):
#   "¥12345 ctx  100%/200k 5h  100%(4h59m) 7d  100%" = ~46 chars + 3 bars
TERM_WIDTH=$(stty size 2>/dev/null </dev/tty 2>/dev/null | awk '{print $2}')
[[ -z "$TERM_WIDTH" || "$TERM_WIDTH" -le 0 ]] 2>/dev/null && TERM_WIDTH=$(tput cols 2>/dev/null)
[[ -z "$TERM_WIDTH" || "$TERM_WIDTH" -le 0 ]] 2>/dev/null && TERM_WIDTH=${COLUMNS:-80}
BAR_WIDTH=$(( (TERM_WIDTH - 48) / 3 ))
(( BAR_WIDTH < 3 )) && BAR_WIDTH=3
(( BAR_WIDTH > 15 )) && BAR_WIDTH=15

# Context size label
if (( CTX_SIZE >= 1000000 )); then CTX_LABEL="1M"; else CTX_LABEL="200k"; fi

# Cost in JPY
COST_JPY=$(awk "BEGIN { printf \"%.0f\", ${COST_USD:-0} * ${USD_JPY} }")

# Usage percentages (clamp 0..100)
U5H_PCT=$(( ${USAGE_5H:-0} > 100 ? 100 : ${USAGE_5H:-0} ))
U7D_PCT=$(( ${USAGE_7D:-0} > 100 ? 100 : ${USAGE_7D:-0} ))
(( U5H_PCT < 0 )) && U5H_PCT=0
(( U7D_PCT < 0 )) && U7D_PCT=0

CTX_C=$(bar_color "$PCT")
U5H_C=$(bar_color "$U5H_PCT")
U7D_C=$(bar_color "$U7D_PCT")

# Reset time remaining for 5h block (pure shell — no python3)
RESET_LABEL=""
if [[ -n "$RESETS_5H" && "$RESETS_5H" != "null" ]]; then
  # Normalize ISO 8601: remove fractional seconds, +09:00 -> +0900, Z -> +0000
  NORM_TS=$(printf '%s' "$RESETS_5H" | sed -E 's/([+-][0-9]{2}):([0-9]{2})$/\1\2/; s/\.[0-9]+([+-][0-9]{4})$/\1/; s/Z$/+0000/')
  if $IS_MACOS; then
    RESET_TS=$(date -j -f '%Y-%m-%dT%H:%M:%S%z' "$NORM_TS" +%s 2>/dev/null || echo 0)
  else
    RESET_TS=$(date -d "$RESETS_5H" +%s 2>/dev/null || echo 0)
  fi
  if (( RESET_TS > NOW )); then
    REMAIN_S=$((RESET_TS - NOW))
    REMAIN_H=$((REMAIN_S / 3600))
    REMAIN_M=$(((REMAIN_S % 3600) / 60))
    RESET_LABEL="${DIM}(${REMAIN_H}h${REMAIN_M}m)${RST}"
  fi
fi

L2="${YELLOW}${BOLD}¥${COST_JPY}${RST}"
L2+=" ${DIM}ctx${RST} $(make_bar "$PCT" "$BAR_WIDTH" "$CTX_C") ${CTX_C}${BOLD}${PCT}%${RST}${DIM}/${CTX_LABEL}${RST}"
if (( U5H_PCT > 0 || U7D_PCT > 0 )) || [[ -n "${USAGE_5H}" ]]; then
  L2+=" ${DIM}5h${RST} $(make_bar "$U5H_PCT" "$BAR_WIDTH" "$U5H_C") ${U5H_C}${BOLD}${U5H_PCT}%${RST}"
  [[ -n "$RESET_LABEL" ]] && L2+="${RESET_LABEL}"
  L2+=" ${DIM}7d${RST} $(make_bar "$U7D_PCT" "$BAR_WIDTH" "$U7D_C") ${U7D_C}${BOLD}${U7D_PCT}%${RST}"
fi

printf '%b\n' "$L1"
printf '%b\n' "$L2"
