#!/bin/bash
# Slackクレデンシャル取得スクリプト
# 優先順位:
# 1. 既存の環境変数
# 2. hooks/.env
# 3. macOS Keychain
# 4. pass
# 5. Termux credentials

_slack_load_env_file() {
    local env_file="$1"
    [ -f "$env_file" ] || return 0

    while IFS='=' read -r key value; do
        case "$key" in
            ''|\#*) continue ;;
        esac

        key="$(printf '%s' "$key" | xargs)"
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"

        case "$key" in
            SLACK_BOT_TOKEN)
                [ -n "$SLACK_BOT_TOKEN" ] || SLACK_BOT_TOKEN="$value"
                ;;
            SLACK_CHANNEL|SLACK_CHANNEL_ID)
                [ -n "$SLACK_CHANNEL" ] || SLACK_CHANNEL="$value"
                ;;
        esac
    done <"$env_file"
}

if [ -n "$SLACK_BOT_TOKEN" ] && [ -z "$SLACK_CHANNEL" ] && [ -n "$SLACK_CHANNEL_ID" ]; then
    SLACK_CHANNEL="$SLACK_CHANNEL_ID"
fi

if [ -n "$SLACK_BOT_TOKEN" ] && [ -n "$SLACK_CHANNEL" ]; then
    export SLACK_BOT_TOKEN
    export SLACK_CHANNEL
    export SLACK_CHANNEL_ID="${SLACK_CHANNEL_ID:-$SLACK_CHANNEL}"
    return 0 2>/dev/null || exit 0
fi

_slack_load_env_file "$HOME/dotfiles/claude/hooks/.env"
_slack_load_env_file "$HOME/.claude/hooks/.env"

if command -v security >/dev/null 2>&1; then
    if [ -z "$SLACK_BOT_TOKEN" ]; then
        SLACK_BOT_TOKEN=$(security find-generic-password -w -a claude-slack -s SLACK_BOT_TOKEN 2>/dev/null)
    fi
    if [ -z "$SLACK_CHANNEL" ]; then
        SLACK_CHANNEL=$(security find-generic-password -w -a claude-slack -s SLACK_CHANNEL 2>/dev/null)
    fi
    if [ -z "$SLACK_CHANNEL" ]; then
        SLACK_CHANNEL=$(security find-generic-password -w -a claude-slack -s SLACK_CHANNEL_ID 2>/dev/null)
    fi
fi

if command -v pass >/dev/null 2>&1; then
    if [ -z "$SLACK_BOT_TOKEN" ]; then
        SLACK_BOT_TOKEN=$(pass show claude/slack-bot-token 2>/dev/null)
    fi
    if [ -z "$SLACK_CHANNEL" ]; then
        SLACK_CHANNEL=$(pass show claude/slack-channel 2>/dev/null)
    fi
fi

if [ -d "/data/data/com.termux" ]; then
    CRED_FILE="$HOME/.config/claude-slack/credentials"
    _slack_load_env_file "$CRED_FILE"
fi

export SLACK_BOT_TOKEN
export SLACK_CHANNEL
export SLACK_CHANNEL_ID="${SLACK_CHANNEL_ID:-$SLACK_CHANNEL}"
