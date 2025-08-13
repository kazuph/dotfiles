#!/bin/bash

# Claude Code Hook: Prevent Write operations on main branch
# This script ensures that Write, MultiEdit, and related operations
# are only performed in worktree directories, not on the main branch

# Exit immediately if any command fails
set -e

# Get current directory
CURRENT_DIR="$(pwd)"

# Check if we're in a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Not in a Git repo, allow operation
    echo '{"decision": "approve"}'
    exit 0
fi

# Get current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Check if we're on main branch
if [ "$BRANCH" = "main" ]; then
    # Read hook input from stdin
    HOOK_INPUT=$(cat)
    
    # Extract file_path from the tool input JSON
    FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
    
    # If we have a file path and it's a .md file, allow the operation
    if [[ -n "$FILE_PATH" && "$FILE_PATH" == *.md ]]; then
        echo '{"decision": "approve", "reason": "Markdown file editing is allowed on main branch"}'
        exit 0
    fi
    
    # Create error message for non-.md files
    ERROR_MESSAGE=$(cat <<'EOF'
🚨 CLAUDE.md読めてますか？worktree必須です。mainでの作業禁止です。
📝 例外: .mdファイルのみmainブランチで編集可能

⚠️  ERROR: Direct write operations on main branch are prohibited!
📋 Please follow the worktree policy from CLAUDE.md:

   1. Create a worktree IN CURRENT DIRECTORY (重要: Claude Codeの制限):
      git worktree add ./project.worktree/feature-name -b feature-branch
      
      ⚠️  CRITICAL: Claude Codeは上位ディレクトリ（../）にアクセスできません！
      ✅ 正しい例: ./project.worktree/feature-name
      ❌ 間違い例: ../project.worktree/feature-name
      
   2. Navigate to worktree: cd ./project.worktree/feature-name
   3. Perform your work in the isolated worktree

💡 This prevents accidental damage to the stable main branch.
🔒 Claude Code Security: Parent directory access is restricted.
📝 Exception: .md files can be edited directly on main branch.
EOF
)
    # JSONエスケープしてレスポンスを返す
    ESCAPED_MESSAGE=$(echo "$ERROR_MESSAGE" | jq -Rs .)
    cat <<EOF
{
  "decision": "block",
  "reason": $ESCAPED_MESSAGE
}
EOF
    exit 2
fi

# Additional check: Warn if not in a worktree directory
# (This is a soft warning, not blocking)
if [[ "$CURRENT_DIR" != *".worktree"* ]]; then
    # Warnings go to stderr for visibility, but don't block operation
    cat >&2 <<EOF
⚠️  WARNING: You're not in a worktree directory.
📋 Consider using worktree for safer development:
   git worktree add ./project.worktree/feature-name -b feature-branch
   
   重要: Claude Codeはカレントディレクトリより上位にアクセスできません
   必ず "./" で始まるパスを使用してください（"../" は使用不可）

EOF
    # Don't exit here, just warn
fi

# If we get here, operation is allowed
echo '{"decision": "approve"}'
exit 0