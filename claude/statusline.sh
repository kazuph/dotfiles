#!/bin/bash
input=$(cat)

USD_JPY=150  # Fixed rate — update occasionally

# Single jq call — output shell variable assignments (no tab delimiter issues)
eval "$(echo "$input" | jq -r '
  "MODEL=" + (@sh "\(.model.display_name // "?")"),
  "CWD=" + (@sh "\(.workspace.current_dir // "")"),
  "PROJECT_DIR=" + (@sh "\(.workspace.project_dir // "")"),
  "PCT=" + (@sh "\(.context_window.used_percentage // 0 | floor | tostring)"),
  "CTX_SIZE=" + (@sh "\(.context_window.context_window_size // 200000 | tostring)"),
  "DURATION_MS=" + (@sh "\(.cost.total_duration_ms // 0 | tostring)"),
  "API_MS=" + (@sh "\(.cost.total_api_duration_ms // 0 | tostring)"),
  "LINES_ADD=" + (@sh "\(.cost.total_lines_added // 0 | tostring)"),
  "LINES_DEL=" + (@sh "\(.cost.total_lines_removed // 0 | tostring)"),
  "WT_NAME=" + (@sh "\(.worktree.name // "")"),
  "WT_BRANCH=" + (@sh "\(.worktree.branch // "")"),
  "COST_USD=" + (@sh "\(.cost.total_cost_usd // 0 | tostring)")
')"

# --- Colors ---
RST='\033[0m'; DIM='\033[2m'; BOLD='\033[1m'
CYAN='\033[36m'; MAGENTA='\033[35m'; BLUE='\033[34m'
GREEN='\033[32m'; RED='\033[31m'; YELLOW='\033[33m'

# Context bar color
if (( PCT < 50 )); then BAR_COLOR="$GREEN"
elif (( PCT < 80 )); then BAR_COLOR="$YELLOW"
else BAR_COLOR="$RED"; fi

# Git branch
BRANCH=""
if [[ -n "$PROJECT_DIR" ]] && command -v git >/dev/null 2>&1; then
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

# --- Line 2: progress bar + changes + time + cost ---
BAR_WIDTH=15
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="▓"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

# Context size label
if (( CTX_SIZE >= 1000000 )); then CTX_LABEL="1M"; else CTX_LABEL="200k"; fi

# Duration
DURATION_S=$((DURATION_MS / 1000))
if (( DURATION_S >= 3600 )); then
  TIME="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m"
elif (( DURATION_S >= 60 )); then
  TIME="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  TIME="${DURATION_S}s"
fi

# API wait ratio
if (( DURATION_MS > 0 )); then API_RATIO=$((API_MS * 100 / DURATION_MS)); else API_RATIO=0; fi

# Cost in JPY
COST_JPY=$(awk "BEGIN { printf \"%.0f\", ${COST_USD:-0} * ${USD_JPY} }")

L2="${YELLOW}${BOLD}¥${COST_JPY}${RST}"
L2+=" ${BAR_COLOR}${BAR}${RST} ${BAR_COLOR}${BOLD}${PCT}%${RST}${DIM}/${CTX_LABEL}${RST}"
L2+=" ${DIM}|${RST} ${DIM}${TIME} (api ${API_RATIO}%)${RST}"

printf '%b\n' "$L1"
printf '%b\n' "$L2"
