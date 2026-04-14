---
name: slack
description: Send messages and files to Slack using the existing bot token and the single configured channel. Never use browser automation for this skill. Do not send to any other channel.
allowed-tools: Bash
---

# Slack API Send

Use this skill when the goal is to send a message or file to Slack.

## Rules

- **Do not use browser automation.**
- **Do not inspect or operate the Slack web UI.**
- **Do not choose a destination channel at runtime.**
- **Always use the single configured channel resolved from existing credentials.**
- **If the configured token or channel is missing, stop and report that plainly.**

## Credential source

This skill must reuse the existing Slack configuration already present on the machine.

Resolution order:

1. `~/dotfiles/claude/hooks/.env`
2. `~/.claude/hooks/.env`
3. macOS Keychain entries for `SLACK_BOT_TOKEN` and `SLACK_CHANNEL` / `SLACK_CHANNEL_ID`
4. `pass` entries for `claude/slack-bot-token` and `claude/slack-channel`

The configured channel is **the only allowed destination** for this skill.

## Primary command

Use the bundled script:

```bash
node /Users/kazuph/dotfiles/claude/skills/slack/scripts/slack-send.mjs message "hello"
node /Users/kazuph/dotfiles/claude/skills/slack/scripts/slack-send.mjs file /absolute/path/to/file "optional comment"
```

## Typical workflow

1. Produce or locate the artifact to send.
2. Call `slack-send.mjs message ...` for plain notifications.
3. Call `slack-send.mjs file ...` for attachments.
4. Report success with the returned JSON summary.

## Examples

### Send a message

```bash
node /Users/kazuph/dotfiles/claude/skills/slack/scripts/slack-send.mjs message "Build finished successfully."
```

### Send a file

```bash
node /Users/kazuph/dotfiles/claude/skills/slack/scripts/slack-send.mjs \
  file /tmp/report.txt "Latest report attached."
```

### Inspect configured channel only

```bash
node /Users/kazuph/dotfiles/claude/skills/slack/scripts/slack-send.mjs channel
```

## Notes

- File uploads use Slack's current external upload API.
- The script intentionally does not accept a channel override.
- If a message plus file are both needed, post the message first and then upload the file.
