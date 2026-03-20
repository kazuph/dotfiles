#!/bin/bash
input=$(cat)

USD_JPY=150  # Fixed rate — update occasionally

# --- Platform detection ---
IS_MACOS=false
[[ "$(uname -s)" == "Darwin" ]] && IS_MACOS=true

# Parse stdin JSON — single jq call for all fields (including rate_limits)
eval "$(echo "$input" | jq -r '
  "MODEL=" + (@sh "\(.model.display_name // "?")"),
  "CWD=" + (@sh "\(.workspace.current_dir // "")"),
  "PROJECT_DIR=" + (@sh "\(.workspace.project_dir // "")"),
  "PCT=" + (@sh "\(.context_window.used_percentage // 0 | floor | tostring)"),
  "CTX_SIZE=" + (@sh "\(.context_window.context_window_size // 200000 | tostring)"),
  "LINES_ADD=" + (@sh "\(.cost.total_lines_added // 0 | tostring)"),
  "LINES_DEL=" + (@sh "\(.cost.total_lines_removed // 0 | tostring)"),
  "WT_BRANCH=" + (@sh "\(.worktree.branch // "")"),
  "COST_USD=" + (@sh "\(.cost.total_cost_usd // 0 | tostring)"),
  "USAGE_5H=" + (.rate_limits.five_hour.used_percentage // 0 | floor | tostring),
  "USAGE_7D=" + (.rate_limits.seven_day.used_percentage // 0 | floor | tostring),
  "RESETS_5H=" + (.rate_limits.five_hour.resets_at // 0 | tostring)
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

# Replace $HOME with ~ and shorten intermediate dirs to first char
# e.g. ~/src/github.com/Photosynth-inc/checkin-poc → ~/s/g/P/checkin-poc
DIR_PATH="${CWD/#$HOME/~}"
if [[ "$DIR_PATH" == */* ]]; then
  local_ifs="$IFS"; IFS='/'
  read -ra parts <<< "$DIR_PATH"
  IFS="$local_ifs"
  last_idx=$(( ${#parts[@]} - 1 ))
  short=""
  for i in "${!parts[@]}"; do
    p="${parts[$i]}"
    if [[ $i -eq 0 ]]; then
      short="$p"  # ~ or empty (root)
    elif [[ $i -eq $last_idx ]]; then
      short+="/$p"  # keep last dir full
    else
      short+="/${p:0:1}"  # first char only
    fi
  done
  DIR_PATH="$short"
fi

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

# Reset time remaining for 5h block (resets_at is now Unix epoch — no parsing needed!)
NOW=$(date +%s)
RESET_LABEL=""
if [[ -n "$RESETS_5H" && "$RESETS_5H" != "0" && "$RESETS_5H" != "null" ]]; then
  if (( RESETS_5H > NOW )); then
    REMAIN_S=$((RESETS_5H - NOW))
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
