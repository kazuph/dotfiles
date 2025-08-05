#!/bin/bash
# PreToolUse hook - コマンド実行前のチェック

INPUT=$(cat)

HOOK_PRE_COMMANDS_PATH=".claude/hooks/rules/hook_pre_commands_rules.json"

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
				ERROR_MESSAGE=$(cat <<EOF
🚨 CLAUDE.md読めてますか？worktree必須です。mainでの作業禁止です。

⚠️  ERROR: Git commits on main branch are prohibited!
📋 Please follow the worktree policy from CLAUDE.md:

   1. Create a worktree: git worktree add path/to/worktree -b feature-branch
   2. Navigate to worktree: cd path/to/worktree  
   3. Develop and commit in the isolated worktree

💡 This prevents accidental commits to the stable main branch.

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
