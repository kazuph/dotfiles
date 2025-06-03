# ~/.dotfiles/zsh/git-worktree/maintenance.zsh
# Git Worktree メンテナンス機能

# 不要なworktreeの一括削除
wtclean() {
    echo "🧹 Finding merged branches in worktrees..."
    echo ""
    
    local current_dir=${PWD##*/}
    local main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    local removed_count=0
    
    # メインブランチが存在しない場合はmasterを試す
    if ! git show-ref --verify --quiet refs/remotes/origin/${main_branch}; then
        main_branch="master"
    fi
    
    echo "📋 Main branch: $main_branch"
    echo ""
    
    git worktree list | grep -v "$(pwd)" | while IFS= read -r line; do
        local wt_path=$(echo "$line" | awk '{print $1}')
        local wt_branch=$(echo "$line" | grep -o '\[.*\]' | tr -d '[]')
        
        if [[ -n "$wt_branch" && "$wt_branch" != "$main_branch" ]]; then
            echo "🔍 Checking branch: $wt_branch"
            
            # ブランチがマージ済みかチェック
            if git merge-base --is-ancestor "$wt_branch" "origin/$main_branch" 2>/dev/null; then
                echo "✅ Merged branch found: $wt_branch at $(basename $wt_path)"
                read "REPLY?Remove this worktree? (y/N): "
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    git worktree remove "$wt_path"
                    git branch -d "$wt_branch" 2>/dev/null || true
                    echo "🗑️  Removed: $(basename $wt_path)"
                    ((removed_count++))
                else
                    echo "⏭️  Skipped: $(basename $wt_path)"
                fi
            else
                echo "⚠️  Not merged: $wt_branch"
            fi
            echo ""
        fi
    done
    
    echo "🧽 Running worktree prune..."
    git worktree prune
    
    echo ""
    echo "✅ Cleanup completed!"
    if [[ $removed_count -gt 0 ]]; then
        echo "📊 Removed $removed_count worktree(s)"
    else
        echo "📊 No worktrees were removed"
    fi
}

# worktreeの状態確認
wtst() {
    echo "📊 === Worktree Status ==="
    echo ""
    
    local worktree_count=0
    git worktree list | while IFS= read -r line; do
        local wt_path=$(echo "$line" | awk '{print $1}')
        local wt_info=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
        local wt_name=$(basename "$wt_path")
        
        ((worktree_count++))
        
        # 現在のworktreeかどうか判定
        if [[ "$wt_path" == "$(pwd)" ]]; then
            echo "📁 $wt_name: $wt_info 👈 CURRENT"
        else
            echo "📁 $wt_name: $wt_info"
        fi
        
        if [[ -d "$wt_path" ]]; then
            echo "   Status:"
            (cd "$wt_path" && git status --short --branch | head -5 | sed 's/^/   /')
            
            # 未プッシュのコミットがあるかチェック
            local unpushed=$(cd "$wt_path" && git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
            if [[ $unpushed -gt 0 ]]; then
                echo "   ⚠️  $unpushed unpushed commit(s)"
            fi
        else
            echo "   ❌ Directory not found"
        fi
        echo ""
    done
    
    echo "📈 Total worktrees: $(git worktree list | wc -l | tr -d ' ')"
}

# worktreeの詳細情報表示
wtinfo() {
    local target=$1
    local current_dir=${PWD##*/}
    
    if [[ -z "$target" ]]; then
        echo "Usage: wtinfo <worktree-suffix>"
        echo "Example: wtinfo feature-auth"
        echo ""
        echo "Available worktrees:"
        git worktree list | awk '{print $1}' | xargs -I {} basename {} | grep -v "^$(basename $PWD)$"
        return 1
    fi
    
    local target_path="../${current_dir}-${target}"
    if [[ ! -d "$target_path" ]]; then
        echo "❌ Worktree not found: $target_path"
        return 1
    fi
    
    echo "📋 === Worktree Information ==="
    echo "📁 Path: $target_path"
    echo ""
    
    (
        cd "$target_path"
        local branch=$(git branch --show-current)
        local commit=$(git rev-parse --short HEAD)
        local remote_url=$(git remote get-url origin 2>/dev/null || echo "No remote")
        
        echo "🌿 Branch: $branch"
        echo "📝 Commit: $commit ($(git log -1 --format='%s'))"
        echo "🔗 Remote: $remote_url"
        echo ""
        
        echo "📊 Status:"
        git status --short --branch
        echo ""
        
        # 最近のコミット履歴
        echo "📜 Recent commits:"
        git log --oneline -5 | sed 's/^/   /'
        echo ""
        
        # ファイル数の統計
        local total_files=$(find . -type f -not -path './.git/*' | wc -l | tr -d ' ')
        local tracked_files=$(git ls-files | wc -l | tr -d ' ')
        echo "📈 Files: $total_files total, $tracked_files tracked"
        
        # 未プッシュのコミット
        local unpushed=$(git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
        if [[ $unpushed -gt 0 ]]; then
            echo "⚠️  Unpushed commits: $unpushed"
        fi
    )
}

# 全worktreeで同じコマンドを実行
wtexec() {
    local command="$*"
    if [[ -z "$command" ]]; then
        echo "Usage: wtexec <command>"
        echo "Example: wtexec git status"
        echo "Example: wtexec npm install"
        return 1
    fi
    
    echo "🚀 Executing '$command' in all worktrees..."
    echo ""
    
    git worktree list | while IFS= read -r line; do
        local wt_path=$(echo "$line" | awk '{print $1}')
        local wt_name=$(basename "$wt_path")
        
        echo "📁 === $wt_name ==="
        if [[ -d "$wt_path" ]]; then
            (cd "$wt_path" && eval "$command")
        else
            echo "❌ Directory not found"
        fi
        echo ""
    done
}

# worktreeのバックアップ作成
wtbackup() {
    local backup_dir="$HOME/.worktree-backups/$(date +%Y%m%d_%H%M%S)"
    
    echo "💾 Creating worktree backup..."
    mkdir -p "$backup_dir"
    
    git worktree list > "$backup_dir/worktree_list.txt"
    git branch -a > "$backup_dir/branches.txt"
    
    echo "✅ Backup created: $backup_dir"
    echo "📋 Contains:"
    echo "   - worktree_list.txt"
    echo "   - branches.txt"
}
