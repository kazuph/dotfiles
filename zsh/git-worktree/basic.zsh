# ~/.dotfiles/zsh/git-worktree/basic.zsh
# Git Worktree 基本操作

# 新しいブランチでworktree作成
wta() {
    local branch_name=$1
    local current_dir=${PWD##*/}
    if [[ -z "$branch_name" ]]; then
        echo "Usage: wta <branch-name>"
        echo "Creates: ../${current_dir}-<branch-name> with new branch"
        return 1
    fi
    
    echo "Creating worktree: ../${current_dir}-${branch_name}"
    git worktree add ../${current_dir}-${branch_name} -b ${branch_name}
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Worktree created successfully!"
        echo "💡 Use 'wtcd ${branch_name}' to switch to it"
    fi
}

# 既存ブランチでworktree作成
wte() {
    local branch_name=$1
    local current_dir=${PWD##*/}
    if [[ -z "$branch_name" ]]; then
        echo "Usage: wte <existing-branch-name>"
        echo "Creates: ../${current_dir}-<branch-name> with existing branch"
        return 1
    fi
    
    # ブランチが存在するかチェック
    if ! git show-ref --verify --quiet refs/heads/${branch_name} && 
       ! git show-ref --verify --quiet refs/remotes/origin/${branch_name}; then
        echo "❌ Branch '${branch_name}' not found"
        echo "Available branches:"
        git branch -a | grep -v HEAD | sed 's/^..//' | head -10
        return 1
    fi
    
    echo "Creating worktree: ../${current_dir}-${branch_name}"
    git worktree add ../${current_dir}-${branch_name} ${branch_name}
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Worktree created successfully!"
        echo "💡 Use 'wtcd ${branch_name}' to switch to it"
    fi
}

# worktree削除
wtr() {
    local target=$1
    local current_dir=${PWD##*/}
    
    if [[ -z "$target" ]]; then
        echo "Current worktrees:"
        git worktree list
        echo ""
        echo "Usage: wtr <worktree-suffix>"
        echo "Example: wtr feature-auth  # removes ../${current_dir}-feature-auth"
        return 1
    fi
    
    local target_path="../${current_dir}-${target}"
    if [[ -d "$target_path" ]]; then
        echo "Removing worktree: $target_path"
        git worktree remove "$target_path"
        if [[ $? -eq 0 ]]; then
            echo "✅ Worktree removed successfully!"
        fi
    else
        echo "❌ Worktree not found: $target_path"
        echo "Available worktrees:"
        git worktree list
    fi
}

# worktree一覧表示（簡潔版）
alias wtls='git worktree list'
