# Shared loader for bash and zsh.
if [[ -n "${AI_GUARD_LOADER_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
AI_GUARD_LOADER_LOADED=1

if [[ -z "${PREFIX:-}" || "${PREFIX}" != *"com.termux"* ]]; then
  if [[ -f "$HOME/.ai_guard.zsh" ]]; then
    . "$HOME/.ai_guard.zsh"
  fi
fi
