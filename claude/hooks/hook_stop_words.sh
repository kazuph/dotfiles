#!/bin/bash

# 標準入力からJSONを読み取る
INPUT=$(cat)

HOOK_STOP_WORDS_PATH=".claude/hooks/rules/hook_stop_words_rules.json"

# トランスクリプトを処理（.jsonl形式に対応）
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')
if [ -f "$TRANSCRIPT_PATH" ]; then
	# 最後のアシスタントメッセージのみを取得
	LAST_MESSAGE=$(tac "$TRANSCRIPT_PATH" | while IFS= read -r line; do
		if echo "$line" | jq -e '.type == "assistant"' >/dev/null 2>&1; then
			echo "$line" | jq -r '.message.content[] | select(.type == "text") | .text'
			break
		fi
	done)

	# hook_stop_words.jsonが存在する場合のみ処理
	if [ -f "$HOOK_STOP_WORDS_PATH" ]; then
		# 各ルールをループ処理
		RULES=$(jq -r 'keys[]' "$HOOK_STOP_WORDS_PATH")
		for RULE_NAME in $RULES; do
			# キーワード配列を取得
			KEYWORDS=$(jq -r ".\"$RULE_NAME\".keywords[]" "$HOOK_STOP_WORDS_PATH" 2>/dev/null)
			MESSAGE=$(jq -r ".\"$RULE_NAME\".message" "$HOOK_STOP_WORDS_PATH" 2>/dev/null)

			# 各キーワードをチェック
			for keyword in $KEYWORDS; do
				if echo "$LAST_MESSAGE" | grep -q "$keyword"; then
					# エラーメッセージを構成
					ERROR_MESSAGE=$(
						cat <<EOF
❌ エラー: AIの発言に「$keyword」が含まれています。

ルール: $RULE_NAME
メッセージ: $MESSAGE

検出された文脈:
$(echo "$LAST_MESSAGE" | grep -C 1 "$keyword" | head -n 5)

作業を中止し、ルールに従って計画を見直してください。
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

# キーワードが見つからなければ正常終了
echo '{"decision": "approve"}'
exit 0
