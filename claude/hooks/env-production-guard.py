#!/usr/bin/env python3
"""
PreToolUse guard - .env.production usage warning/block

Bash tool commands containing .env.production or env.production:
- WRITE operations: deny (must use .env.staging or .env.staging2 instead)
- READ operations: warn with specific guidance, but allow
- Ambiguous: warn but allow
"""

import json
import re
import sys
from typing import Optional


# Patterns that indicate read-only intent
READ_PATTERNS = [
    r"\bdotenvx\s+get\b",
    r"\baws\s+\S+\s+describe-",
    r"\baws\s+\S+\s+list-",
    r"\baws\s+\S+\s+get-",
    r"\baws\s+\S+\s+scan\b",
    r"\baws\s+\S+\s+query\b",
    r"\baws\s+sts\s+get-caller-identity\b",
    r"\baws\s+logs\s+filter-log-events\b",
    r"\baws\s+logs\s+describe-log-groups\b",
    r"\baws\s+s3\s+ls\b",
    r"\bwrangler\s+secret\s+list\b",
    r"\bterraform\s+plan\b",
    r"\bcat\b",
    r"\bgrep\b",
    r"\bhead\b",
    r"\btail\b",
]

# Patterns that indicate write/mutating intent
WRITE_PATTERNS = [
    # dotenvx
    r"\bdotenvx\s+set\b",
    r"\bdotenvx\s+(unset|encrypt|rotate)\b",
    # AWS generic mutating verbs
    r"\baws\s+\S+\s+update-",
    r"\baws\s+\S+\s+put-",
    r"\baws\s+\S+\s+delete-",
    r"\baws\s+\S+\s+create-",
    r"\baws\s+\S+\s+deploy\b",
    # AWS side-effect verbs (start, stop, terminate, etc.)
    r"\baws\s+\S+\s+(start-|stop-|terminate-|reboot-|enable-|disable-|associate-|disassociate-|attach-|detach-|register-|deregister-|revoke-|execute-|run-)\w+",
    r"\baws\s+\S+\s+publish(?:\b|-)",
    r"\baws\s+lambda\s+invoke\b",
    # AWS IoT data plane
    r"\baws\s+iot-data\s+(publish|update-thing-shadow|delete-thing-shadow)\b",
    # AWS DynamoDB batch/execute (must be before generic execute- pattern)
    r"\baws\s+dynamodb\s+batch-write-item\b",
    r"\baws\s+dynamodb\s+execute-statement\b",
    # AWS S3 mutating
    r"\baws\s+s3\s+cp\b",
    r"\baws\s+s3\s+mv\b",
    r"\baws\s+s3\s+rm\b",
    r"\baws\s+s3\s+sync\b",
    # CDK / Terraform
    r"\bcdk\s+deploy\b",
    r"\bcdk\s+destroy\b",
    r"\bterraform\s+(apply|destroy)\b",
    # Wrangler deploy/mutate
    r"\bwrangler\s+deploy\b",
    r"\bwrangler\s+(publish|pages\s+deploy)\b",
    r"\bwrangler\s+secret\s+(put|delete)\b",
    r"\bwrangler\s+kv:key\s+(put|delete)\b",
    r"\bwrangler\s+r2\s+object\s+(put|delete)\b",
    r"\bwrangler\s+d1\s+migrations\s+apply\b",
    r"\bwrangler\s+d1\s+execute\b.*--file\b",
    # D1 mutating SQL
    r"\bwrangler\s+d1\s+execute\b.*--command\s+.*\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE)\b",
]

READ_WARNING_MSG = (
    "⚠️ .env.production を参照中（READ操作）。\n"
    ".env.production と .env.staging は同じAWSアカウント(536697249627)を指します。\n"
    "代替案:\n"
    "  - Prod Account(536697249627)の操作 → .env.staging を使用\n"
    "  - Dev Account(075309977233)の操作 → .env.staging2 を使用\n"
    "本当に .env.production でなければならない理由がありますか？"
)

AMBIGUOUS_WARNING_MSG = (
    "⚠️ .env.production を参照中（操作種別不明）。\n"
    "代替案:\n"
    "  - Prod Account(536697249627)の操作 → .env.staging を使用\n"
    "  - Dev Account(075309977233)の操作 → .env.staging2 を使用\n"
    "コマンドの意図を確認してください。"
)

DENY_MSG = (
    "🚫 .env.production での更新操作は禁止です。\n"
    "代替案:\n"
    "  - Prod Account(536697249627)の操作 → .env.staging を使用\n"
    "  - Dev Account(075309977233)の操作 → .env.staging2 を使用\n"
    "どうしても .env.production が必要な場合は、手順書を作成してユーザーに実行を依頼してください。"
)


def emit_decision(decision: str, reason: Optional[str] = None) -> None:
    payload = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
        }
    }
    if reason:
        payload["hookSpecificOutput"]["permissionDecisionReason"] = reason
    print(json.dumps(payload, ensure_ascii=False))
    sys.exit(0)


def matches_any(command: str, patterns: list) -> bool:
    for pattern in patterns:
        if re.search(pattern, command, re.IGNORECASE):
            return True
    return False


def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")

    # Only guard Bash tool
    if tool_name != "Bash":
        emit_decision("allow", f"not Bash tool: {tool_name}")

    command = input_data.get("tool_input", {}).get("command", "")

    # Check if command references .env.production
    if ".env.production" not in command and "env.production" not in command:
        emit_decision("allow", "no .env.production reference")

    # Command references .env.production — check write first (higher priority)
    if matches_any(command, WRITE_PATTERNS):
        emit_decision("deny", DENY_MSG)

    # Check if it's a known read operation
    if matches_any(command, READ_PATTERNS):
        emit_decision("allow", READ_WARNING_MSG)

    # Ambiguous — warn but allow
    emit_decision("allow", AMBIGUOUS_WARNING_MSG)


if __name__ == "__main__":
    main()
