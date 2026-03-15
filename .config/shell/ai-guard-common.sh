# Shared AI guard settings for bash and zsh.
if [[ -n "${AI_GUARD_COMMON_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
AI_GUARD_COMMON_LOADED=1

_AI_GUARD_PROTECTED_PATTERNS=(
  ".allow-main"
  ".allow_main"
  "allow-main"
  "allow_main"
)

_AI_GUARD_AI_PROCESS_PATTERNS=(
  "claude"
  "anthropic"
  "codex"
  "openai"
  "aider"
  "opencode"
  "opencode"
  "github-copilot"
  "copilot"
  "cursor-agent"
  "cursor"
)

_ai_guard_check_protected_pattern() {
  local cmd_line="$1"
  local pattern
  for pattern in "${_AI_GUARD_PROTECTED_PATTERNS[@]}"; do
    if [[ "$cmd_line" == *"$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}

_ai_guard_process_matches_ai() {
  local process_name="${1:-}"
  local lowered pattern
  lowered=$(printf "%s" "$process_name" | tr "[:upper:]" "[:lower:]")
  for pattern in "${_AI_GUARD_AI_PROCESS_PATTERNS[@]}"; do
    if [[ "$lowered" == *"$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}
