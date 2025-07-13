#!/bin/bash

# 文字エンコーディング設定
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

# 標準入力からJSONを読み取る
INPUT=$(cat)

HOOK_STOP_WORDS_PATH=".claude/hooks/rules/hook_stop_words_rules.json"

# トランスクリプトを処理（.jsonl形式に対応）
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')
if [ -f "$TRANSCRIPT_PATH" ]; then
	# 最後のアシスタントメッセージのみを取得
	LAST_MESSAGE=""
	while IFS= read -r line; do
		if echo "$line" | jq -e '.type == "assistant"' >/dev/null 2>&1; then
			LAST_MESSAGE=$(echo "$line" | jq -r '.message.content[] | select(.type == "text") | .text')
			break
		fi
	done < <(tac "$TRANSCRIPT_PATH")

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
				if echo "$LAST_MESSAGE" | LC_ALL=ja_JP.UTF-8 grep -E -q "$keyword"; then
					# エラーメッセージを直接構成してstderrに出力
					{
						echo "❌ エラー: AIの発言に「${keyword}」が含まれています。"
						echo ""
						echo "ルール: ${RULE_NAME}"
						echo "メッセージ: ${MESSAGE}"
						echo ""
						echo "検出された文脈:"
						echo "$LAST_MESSAGE" | grep -E -C 1 "$keyword" | head -n 5
						echo ""
						echo "作業を中止し、ルールに従って計画を見直してください。"
					} >&2
					exit 2
				fi
			done
		done
	fi
fi

# キーワードが見つからなければ何も出力せずに正常終了
exit 0
