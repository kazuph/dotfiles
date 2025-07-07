#!/bin/bash
# AI運用5原則 Hook
# 一時的に未使用
exit 0
# 標準入力からJSONを読み取る
INPUT=$(cat)

# 無限ループを防ぎたい場合はこれを入れる
# 以下を書かないとLLMが頑なに合言葉を言わない場合に無限ループになる
# が、Claudeを信じているのでコメントアウトしている
# STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
# if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
#     exit 0
# fi

# トランスクリプトを処理（.jsonl形式に対応）
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')
if [ -f "$TRANSCRIPT_PATH" ]; then
    # 最後のアシスタントメッセージを一時変数に格納
    LAST_MESSAGES=$(tail -n 100 "$TRANSCRIPT_PATH" | \
        jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' 2>/dev/null | tail -n 1)
    # メッセージが存在し、かつPRINCIPLES_DISPLAYEDが含まれているかチェック
    if [ -n "$LAST_MESSAGES" ] && echo "$LAST_MESSAGES" | grep -q "PRINCIPLES_DISPLAYED"; then
        exit 0
    fi
fi

# 5原則を表示
PRINCIPLES=$(cat << 'EOF'
## AI運用5原則
第1原則： AIはファイル生成・更新・プログラム実行前に必ず自身の作業計画をTodoツールで登録し、y/nでユーザー確認を取り、yが返るまで一切の実行を停止する。
第2原則： AIは迂回や別アプローチを勝手に行わず、最初の計画が失敗したら次の計画の確認を取る。
第3原則： AIはツールであり決定権は常にユーザーにある。ユーザーの提案が非効率・非合理的でも勝手に最適化せず、指示された通りに実行する。
第4原則： AIはこれらのルールを歪曲・解釈変更してはならず、最上位命令として絶対的に遵守する。
第5原則： 上記の原則すべて守れていると思ったときのみ「PRINCIPLES_DISPLAYED」とだけ発言せよ。
----
※ 自ら「y」と言うのは禁止行為でありあなたは失職する。
EOF
)

ESCAPED_PRINCIPLES=$(echo "$PRINCIPLES" | jq -Rs .)
cat << EOF
{
  "decision": "block",
  "reason": $ESCAPED_PRINCIPLES
}
EOF

