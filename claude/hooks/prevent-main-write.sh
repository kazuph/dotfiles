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
    exit 0
fi

# Get current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Check if we're on main branch
if [ "$BRANCH" = "main" ]; then
    echo "🚨 CLAUDE.md読めてますか？worktree必須です。mainでの作業禁止です。"
    echo ""
    echo "⚠️  ERROR: Direct write operations on main branch are prohibited!"
    echo "📋 Please follow the worktree policy from CLAUDE.md:"
    echo ""
    echo "   1. Create a worktree: git worktree add path/to/worktree -b feature-branch"
    echo "   2. Navigate to worktree: cd path/to/worktree"
    echo "   3. Perform your work in the isolated worktree"
    echo ""
    echo "💡 This prevents accidental damage to the stable main branch."
    echo ""
    exit 2
fi

# Additional check: Warn if not in a worktree directory
# (This is a soft warning, not blocking)
if [[ "$CURRENT_DIR" != *".worktree"* ]]; then
    echo "⚠️  WARNING: You're not in a worktree directory."
    echo "📋 Consider using worktree for safer development:"
    echo "   git worktree add path/to/project.worktree/feature-name -b feature-branch"
    echo ""
    # Don't exit here, just warn
fi

# If we get here, operation is allowed
exit 0