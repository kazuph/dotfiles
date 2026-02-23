#!/usr/bin/env bash
set -euo pipefail

# Extract YAML front matter from every SKILL.md under known skill roots.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

roots=(
  "$script_dir"                                  # ~/.claude/skills
  "$HOME/.claude/plugins/cache"                 # plugin cache
  "$HOME/.claude/plugins/marketplaces"          # plugin marketplaces
  "$HOME/.codex/skills"                          # Codex skills
)

declare -A seen
files=()

for root in "${roots[@]}"; do
  if [[ -d "$root" ]]; then
    while IFS= read -r -d '' file; do
      if [[ -z "${seen[$file]:-}" ]]; then
        seen[$file]=1
        files+=("$file")
      fi
    done < <(find "$root" -type f -name "SKILL.md" -print0)
  fi
done

if [[ ${#files[@]} -eq 0 ]]; then
  exit 0
fi

printf '%s\n' "${files[@]}" | sort | while IFS= read -r file; do
  rel_path="$file"
  if [[ "$file" == "$script_dir"/* ]]; then
    rel_path="${file#$script_dir/}"
  fi
  echo "# ${rel_path}"
  awk '
    $0=="---" { marker++; if (marker==1) { print "---"; next } }
    marker==1 { print }
    marker==2 { print "---"; exit }
  ' "$file"
  echo
done
