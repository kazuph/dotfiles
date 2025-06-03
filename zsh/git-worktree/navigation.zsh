# ~/.dotfiles/zsh/git-worktree/navigation.zsh
# Git Worktree ナビゲーション機能

# worktreeに移動
wtcd() {
    local target=$1
    local current_dir=${PWD##*/}
    
    if [[ -z "$target" ]]; then
        echo "Available worktrees:"
        git worktree list | grep -v "$(pwd)" | awk '{print $1}' | xargs -I {} basename {} | sed "s/^${current_dir}-//"
        echo ""
        echo "Usage: wtcd <worktree-suffix>"
        echo "Example: wtcd feature-auth"
        return 1
    fi
    
    local target_path="../${current_dir}-${target}"
    if [[ -d "$target_path" ]]; then
        cd "$target_path"
        echo "🚀 Switched to worktree: $(basename $target_path)"
        echo ""
        git status --short --branch
    else
        echo "❌ Worktree not found: $target_path"
        echo "Available worktrees:"
        git worktree list
    fi
}

# メインworktreeに戻る
wtback() {
    local current_dir=${PWD##*/}
    # 現在のディレクトリ名から-で分割して最初の部分を取得
    local main_project=$(echo $current_dir | cut -d'-' -f1)
    local main_path="../${main_project}"
    
    if [[ -d "$main_path" ]]; then
        cd "$main_path"
        echo "🏠 Back to main worktree: $(basename $main_path)"
        echo ""
        git status --short --branch
    else
        echo "❌ Main worktree not found: $main_path"
        echo "Current worktrees:"
        git worktree list
    fi
}

# worktree間のスマート切り替え
wts() {
    local target=$1
    if [[ -z "$target" ]]; then
        echo "Available worktrees:"
        git worktree list --porcelain | grep "worktree" | sed 's/worktree //' | xargs -I {} basename {} | grep -v "^$(basename $PWD)$"
        echo ""
        echo "Usage: wts <worktree-name-or-suffix>"
        echo "Supports both full name and partial matching"
        return 1
    fi
    
    # 完全一致で検索
    local exact_match=$(git worktree list --porcelain | grep "worktree" | sed 's/worktree //' | grep "/${target}$")
    if [[ -n "$exact_match" ]]; then
        cd "$exact_match"
        echo "🎯 Switched to: $(basename $exact_match)"
        echo ""
        git status --short --branch
        return 0
    fi
    
    # 部分一致で検索
    local partial_match=$(git worktree list --porcelain | grep "worktree" | sed 's/worktree //' | grep "$target" | head -1)
    if [[ -n "$partial_match" ]]; then
        cd "$partial_match"
        echo "🔍 Switched to: $(basename $partial_match)"
        echo ""
        git status --short --branch
    else
        echo "❌ No worktree found matching: $target"
        echo "Available worktrees:"
        git worktree list
    fi
}

# 現在のworktreeでの作業完了→プッシュ→削除の一連の流れ
wtdone() {
    echo "🏁 Finishing current worktree work..."
    echo ""
    
    # 変更があるかチェック
    if [[ -n $(git status --porcelain) ]]; then
        echo "📝 Uncommitted changes found:"
        git status --short
        echo ""
        read "REPLY?Commit all changes? (y/N): "
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read "commit_msg?Enter commit message: "
            git add -A
            git commit -m "$commit_msg"
            echo "✅ Changes committed!"
        else
            echo "❌ Please commit or stash changes first"
            return 1
        fi
    fi
    
    # 現在のブランチを取得
    local current_branch=$(git branch --show-current)
    local current_path=$(pwd)
    
    # プッシュ
    if [[ -n "$current_branch" ]]; then
        echo "📤 Pushing $current_branch..."
        git push origin "$current_branch"
        if [[ $? -eq 0 ]]; then
            echo "✅ Pushed successfully!"
        else
            echo "❌ Push failed"
            return 1
        fi
    fi
    
    # メインworktreeに戻る
    echo ""
    echo "🏠 Returning to main worktree..."
    wtback
    
    # worktree削除の確認
    echo ""
    read "REPLY?Remove worktree $(basename $current_path)? (y/N): "
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git worktree remove "$current_path"
        if [[ $? -eq 0 ]]; then
            echo "🗑️  Worktree removed: $(basename $current_path)"
            echo "✅ Work completed successfully!"
        fi
    else
        echo "ℹ️  Worktree kept: $(basename $current_path)"
    fi
}
