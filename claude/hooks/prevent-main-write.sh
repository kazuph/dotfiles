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
    # Create error message
    ERROR_MESSAGE=$(cat <<'EOF'
🚨 CLAUDE.md読めてますか？worktree必須です。mainでの作業禁止です。

⚠️  ERROR: Direct write operations on main branch are prohibited!
📋 Please follow the worktree policy from CLAUDE.md:

   1. Create a worktree: git worktree add path/to/worktree -b feature-branch
   2. Navigate to worktree: cd path/to/worktree
   3. Perform your work in the isolated worktree

💡 This prevents accidental damage to the stable main branch.
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
   git worktree add path/to/project.worktree/feature-name -b feature-branch

EOF
    # Don't exit here, just warn
fi

# If we get here, operation is allowed
echo '{"decision": "approve"}'
exit 0