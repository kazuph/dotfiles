---
name: ccxbot
description: X(Twitter) notifications from Claude Code. Send messages that appear as native-looking notifications on X's /notifications page. Use this skill when you want to notify the user or ask them a question via X notifications. Requires Chrome extension + WebSocket server.
---

# ccxbot - X Notification System for Claude Code

Send notifications to the user's X (Twitter) /notifications page and optionally wait for their reply.

## Prerequisites

- Chrome extension loaded from `~/src/github.com/kazuph/ccxbot/extension/`
- User must have X (x.com) open in Chrome

## Server Management

**IMPORTANT**: Before sending any notification, check if the server is already running. Do NOT start a duplicate.

```bash
# Check if server is running
lsof -i :18765 -sTCP:LISTEN >/dev/null 2>&1 && echo "RUNNING" || echo "NOT RUNNING"
```

If NOT RUNNING, start it in background:

```bash
node ~/src/github.com/kazuph/ccxbot/server/src/index.js &
# Wait briefly for startup
sleep 1
```

If RUNNING, do nothing. One server handles all sessions.

## Sending Notifications

```bash
# Simple notification (fire and forget)
node ~/src/github.com/kazuph/ccxbot/cli/send.js "Your message here"

# Send and wait for user's reply (RECOMMENDED for questions)
node ~/src/github.com/kazuph/ccxbot/cli/send.js "Your question?" --listen

# Custom bot name (default: current directory name)
node ~/src/github.com/kazuph/ccxbot/cli/send.js "Hello!" --name my-bot --listen

# Timeout after N seconds
node ~/src/github.com/kazuph/ccxbot/cli/send.js "Quick question?" --listen --timeout 300
```

## Options

| Option | Description |
|--------|-------------|
| `--listen` | Wait for user reply, print it to stdout, then exit |
| `--name <name>` | Bot display name (default: directory name) |
| `--timeout <seconds>` | Exit after N seconds (0 = wait forever) |
| `--interactive` | Two-way chat mode |
| `--stdin` | Read message from stdin pipe |

## Usage Patterns

### Ask user a question and get reply
```bash
REPLY=$(node ~/src/github.com/kazuph/ccxbot/cli/send.js "Which approach do you prefer? A or B?" --listen --name project-bot)
echo "User replied: $REPLY"
```

### Notify task completion
```bash
node ~/src/github.com/kazuph/ccxbot/cli/send.js "Build completed successfully!" --name my-project
```

### Report with reply
```bash
node ~/src/github.com/kazuph/ccxbot/cli/send.js "Deployment done. Any issues?" --listen --name deploy-bot
```

## Architecture Notes

- Single server (port 18765) supports multiple Claude Code sessions simultaneously
- Reply broadcasts to ALL connected `--listen` clients
- If user replies on X, the reply text is printed to stdout; logs go to stderr
- Chrome extension polls every 3 seconds for new notifications
- Replied notifications auto-disappear from X's notification page

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "connection timeout" | Server not running. Start it. |
| Notification not showing | Reload Chrome extension at chrome://extensions |
| Reply not received | Ensure `--listen` flag is set |
| Old notifications persist | Reload X page; server auto-filters replied messages |
