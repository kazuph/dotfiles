#!/bin/bash
# PreToolUse hook - コマンド実行前のチェック

INPUT=$(cat)

HOOK_PRE_COMMANDS_PATH="$HOME/.claude/hooks/rules/hook_pre_commands_rules.json"

# ツール名を取得
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

# Bashツールの場合のみチェック
if [ "$TOOL_NAME" = "Bash" ]; then
	# コマンドを取得
	COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

	# git commitコマンドのmainブランチチェック（最優先）
	if echo "$COMMAND" | grep -qE "git\s+commit"; then
		# Gitリポジトリ内かチェック
		if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
			# 現在のブランチを取得
			BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
			if [ "$BRANCH" = "main" ]; then
				# Check if .allow-main file exists (bypass mechanism)
				if [ -f ".allow-main" ]; then
					# バイパス: 処理を続行（エラーメッセージを表示せずに承認）
					:  # no-op, continue to approval
				else
					ERROR_MESSAGE=$(cat <<EOF
🚨 CLAUDE.md読めてますか？worktree必須です。mainでの作業禁止です。

⚠️  ERROR: Git commits on main branch are prohibited!
📋 Please follow the worktree policy from CLAUDE.md:

   1. Create a worktree in CURRENT DIRECTORY (重要: Claude Codeは上位ディレクトリに移動できません):
      git worktree add ./project.worktree/feature-name -b feature-branch
      
   ⚠️  注意: "./project.worktree/" のようにカレントディレクトリ以下に作成すること！
   ❌ NG例: ../project.worktree/ (上位ディレクトリは不可)
   ✅ OK例: ./project.worktree/feature-name
   
   2. Navigate to worktree: cd ./project.worktree/feature-name
   3. Develop and commit in the isolated worktree

💡 This prevents accidental commits to the stable main branch.
🔒 Claude Code Security: Cannot access parent directories
🔓 Bypass: Create .allow-main file to permit all operations on main branch.

Blocked command: $COMMAND
EOF
					)
					ESCAPED_MESSAGE=$(echo "$ERROR_MESSAGE" | jq -Rs .)
					cat <<EOF
{
  "decision": "block", 
  "reason": $ESCAPED_MESSAGE
}
EOF
					exit 0
				fi
			fi
		fi
	fi

	# git merge/rebase/cherry-pickコマンドのmainブランチチェック（pullは許可）
	if echo "$COMMAND" | grep -qE "git\s+(merge|rebase|cherry-pick)"; then
		# Gitリポジトリ内かチェック
		if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
			# 現在のブランチを取得
			BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
			if [ "$BRANCH" = "main" ]; then
				# Check if .allow-main file exists (bypass mechanism)
				if [ -f ".allow-main" ]; then
					# バイパス: 処理を続行（エラーメッセージを表示せずに承認）
					:  # no-op, continue to approval
				else
					# コマンドタイプを判定
					if echo "$COMMAND" | grep -qE "git\s+merge"; then
						OPERATION="merge"
						OPERATION_JP="マージ"
					elif echo "$COMMAND" | grep -qE "git\s+rebase"; then
						OPERATION="rebase"
						OPERATION_JP="リベース"
					elif echo "$COMMAND" | grep -qE "git\s+cherry-pick"; then
						OPERATION="cherry-pick"
						OPERATION_JP="チェリーピック"
					fi
					
					ERROR_MESSAGE=$(cat <<EOF
🚨 危険: mainブランチへの${OPERATION_JP}操作が検出されました！

⚠️  ERROR: Git ${OPERATION} operations on main branch are prohibited!
📋 mainブランチは保護されています:

   ❌ 禁止された操作: ${COMMAND}
   
   ✅ 正しいワークフロー:
   1. worktreeで作業 (重要: カレントディレクトリ以下に作成):
      git worktree add ./project.worktree/feature-name -b feature-branch
      
      ⚠️  Claude Codeの制限: 上位ディレクトリ（../）にアクセスできません
      ✅ OK: ./project.worktree/feature-name
      ❌ NG: ../project.worktree/feature-name
      
   2. cd ./project.worktree/feature-name でworktreeへ移動
   3. featureブランチで開発とテスト
   4. プルリクエスト経由でmainへマージ
   
   💡 mainブランチへの直接的な変更は、予期しない破壊的変更を引き起こす可能性があります。

🔒 このコマンドはセキュリティポリシーによりブロックされました。
🔓 Bypass: Create .allow-main file to permit all operations on main branch.
EOF
					)
					ESCAPED_MESSAGE=$(echo "$ERROR_MESSAGE" | jq -Rs .)
					cat <<EOF
{
  "decision": "block", 
  "reason": $ESCAPED_MESSAGE
}
EOF
					exit 0
				fi
			fi
		fi
	fi

	if [ -n "$COMMAND" ] && [ -f "$HOOK_PRE_COMMANDS_PATH" ]; then
		# 各ルールをループ処理
		RULES=$(jq -r 'keys[]' "$HOOK_PRE_COMMANDS_PATH")
		for RULE_NAME in $RULES; do
			# コマンド配列を取得
			COMMANDS=$(jq -r ".\"$RULE_NAME\".commands[]" "$HOOK_PRE_COMMANDS_PATH" 2>/dev/null)
			MESSAGE=$(jq -r ".\"$RULE_NAME\".message" "$HOOK_PRE_COMMANDS_PATH" 2>/dev/null)

			# 各禁止コマンドをチェック
			for blocked_cmd in $COMMANDS; do
				if echo "$COMMAND" | grep -qF "$blocked_cmd"; then
					# エラーメッセージを構成
					ERROR_MESSAGE=$(
						cat <<EOF
❌ エラー: 禁止されたコマンド「$blocked_cmd」が検出されました。

ルール: $RULE_NAME
メッセージ: $MESSAGE

検出されたコマンド:
$COMMAND

このコマンドの実行は許可されていません。
EOF
					)
					# 色を適用
					COLORED_MESSAGE=$(echo "$ERROR_MESSAGE" | sed 's/^/\033[91m/' | sed 's/$/\033[0m/')

					# JSONエスケープ
					ESCAPED_MESSAGE=$(echo "$COLORED_MESSAGE" | jq -Rs .)

					# blockレスポンスを返す
					cat <<EOF
{
  "decision": "block",
  "reason": $ESCAPED_MESSAGE
}
EOF
					exit 0
				fi
			done
		done
	fi
fi

# 問題なければ承認
echo '{"decision": "approve"}'
exit 0
