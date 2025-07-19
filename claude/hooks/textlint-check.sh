#!/bin/bash
exit 0

# textlint hook for markdown files using JSON output
# Returns results to Claude via JSON format

# Debug log file
DEBUG_LOG="/tmp/textlint-hook-debug.log"

# Lock file to prevent duplicate execution
LOCK_FILE="/tmp/textlint-hook.lock"
if [ -f "$LOCK_FILE" ]; then
	if [ "$(($(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)))" -gt 2 ]; then
		rm -f "$LOCK_FILE"
	else
		exit 0
	fi
fi

# Create lock file
touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

echo "[$(date)] === textlint hook started (supports Write/MultiEdit/Obsidian MCP) ===" >>"$DEBUG_LOG"

# Read JSON input from stdin
INPUT_JSON=$(cat)

# Extract tool name and input from JSON
TOOL_NAME=$(echo "$INPUT_JSON" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(data.get('tool_name', ''))
except:
    pass
" 2>>"$DEBUG_LOG")

echo "Tool name: $TOOL_NAME" >>"$DEBUG_LOG"

# Only process Write, MultiEdit, and Obsidian MCP tools
if [[ "$TOOL_NAME" != "Write" ]] && [[ "$TOOL_NAME" != "MultiEdit" ]] && [[ "$TOOL_NAME" != "mcp__obsidian__obsidian_write_note" ]]; then
	exit 0
fi

# Extract tool input
TOOL_INPUT=$(echo "$INPUT_JSON" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    tool_input = data.get('tool_input', {})
    print(json.dumps(tool_input))
except:
    print('{}')
" 2>>"$DEBUG_LOG")

# Extract file path from tool input
FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    # Try file_path first (Write/MultiEdit), then path (Obsidian MCP)
    file_path = data.get('file_path', '') or data.get('path', '')
    print(file_path)
except:
    pass
" 2>>"$DEBUG_LOG")

echo "Extracted FILE_PATH: $FILE_PATH" >>"$DEBUG_LOG"

# Only process markdown files (.md)
if [[ ! "$FILE_PATH" =~ \.md$ ]]; then
	exit 0
fi

# Skip if file path is empty
if [[ -z "$FILE_PATH" ]]; then
	exit 0
fi

# Create temporary file with content
TEMP_FILE=$(mktemp /tmp/textlint-check.XXXXXX.md)

# Extract content from tool input
if [[ "$TOOL_NAME" == "Write" ]] || [[ "$TOOL_NAME" == "mcp__obsidian__obsidian_write_note" ]]; then
	CONTENT=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    content = data.get('content', '')
    print(content)
except:
    pass
" 2>>"$DEBUG_LOG")

	echo "$CONTENT" >"$TEMP_FILE"
elif [[ "$TOOL_NAME" == "MultiEdit" ]]; then
	rm -f "$TEMP_FILE"
	exit 0
fi

# Check if temp file has content
if [[ ! -s "$TEMP_FILE" ]]; then
	rm -f "$TEMP_FILE"
	exit 0
fi

# Run textlint on the temporary file
echo "Running textlint on $TEMP_FILE" >>"$DEBUG_LOG"
TEXTLINT_OUTPUT=$(textlint "$TEMP_FILE" 2>&1)
TEXTLINT_EXIT_CODE=$?
echo "textlint exit code: $TEXTLINT_EXIT_CODE" >>"$DEBUG_LOG"

# Clean up temp file
rm -f "$TEMP_FILE"

# Prepare response based on result
FILENAME=$(basename "$FILE_PATH")

if [[ $TEXTLINT_EXIT_CODE -eq 0 ]]; then
	# No issues found - send notification but continue
	NOTIFICATION_MSG="✅ textlintチェック完了: $FILENAME - 問題なし"
	osascript -e "display notification \"$NOTIFICATION_MSG\" with title \"textlint\" sound name \"Pop\"" 2>/dev/null || true

	# Return JSON with success info
	cat <<EOF
{
  "continue": true,
  "decision": "approve",
  "reason": "textlint check passed for $FILE_PATH - no issues found"
}
EOF
else
	# Format the output
	FORMATTED_OUTPUT=$(echo "$TEXTLINT_OUTPUT" | sed 's|/tmp/textlint-check\.[^:]*.md|'"$FILE_PATH"'|g')
	ISSUE_COUNT=$(echo "$TEXTLINT_OUTPUT" | grep -c "error")
	NOTIFICATION_MSG="⚠️ textlintチェック完了: $FILENAME - ${ISSUE_COUNT}件の改善提案"

	# Send notification
	osascript -e "display notification \"$NOTIFICATION_MSG\" with title \"textlint\" sound name \"Pop\"" 2>/dev/null || true

	# Output to stderr so Claude Code can see it (exit code 1 = non-blocking error)
	echo "⚠️ textlint found issues in $FILE_PATH:" >&2
	echo "$FORMATTED_OUTPUT" >&2
	echo "" >&2
	echo "Consider fixing these issues for better readability." >&2

	# Exit with code 2 (blocking error) so Claude Code receives stderr
	exit 2
fi
