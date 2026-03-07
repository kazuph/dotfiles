#!/bin/bash
# Slackクレデンシャル取得スクリプト
# 環境変数が未設定の場合、Keychainまたはpassから取得を試みる

# 既に環境変数が設定されていればそのまま使用
if [ -n "$SLACK_BOT_TOKEN" ] && [ -n "$SLACK_CHANNEL" ]; then
    return 0 2>/dev/null || exit 0
fi

# macOS Keychain
if command -v security &>/dev/null; then
    if [ -z "$SLACK_BOT_TOKEN" ]; then
        SLACK_BOT_TOKEN=$(security find-generic-password -w -a claude-slack -s SLACK_BOT_TOKEN 2>/dev/null)
    fi
    if [ -z "$SLACK_CHANNEL" ]; then
        SLACK_CHANNEL=$(security find-generic-password -w -a claude-slack -s SLACK_CHANNEL 2>/dev/null)
    fi
fi

# Linux pass (password-store)
if command -v pass &>/dev/null; then
    if [ -z "$SLACK_BOT_TOKEN" ]; then
        SLACK_BOT_TOKEN=$(pass show claude/slack-bot-token 2>/dev/null)
    fi
    if [ -z "$SLACK_CHANNEL" ]; then
        SLACK_CHANNEL=$(pass show claude/slack-channel 2>/dev/null)
    fi
fi

# Termux (Android) - termux-keystore または 環境変数ファイル
if [ -d "/data/data/com.termux" ]; then
    CRED_FILE="$HOME/.config/claude-slack/credentials"
    if [ -f "$CRED_FILE" ]; then
        source "$CRED_FILE"
    fi
fi

export SLACK_BOT_TOKEN
export SLACK_CHANNEL
