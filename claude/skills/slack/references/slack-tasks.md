# Common Slack Send Tasks

Reference guide for sending messages and files to the single configured Slack channel.

## Task: Send a plain message

### Goal
Post a text notification to the configured Slack channel.

### Command

```bash
node /Users/kazuph/dotfiles/claude/skills/slack/scripts/slack-send.mjs \
  message "Build finished successfully."
```

### Notes

- Do not override the channel.
- The script resolves the only allowed channel from existing credentials.

---

## Task: Send a file

### Goal
Upload a local file to the configured Slack channel.

### Command

```bash
node /Users/kazuph/dotfiles/claude/skills/slack/scripts/slack-send.mjs \
  file /absolute/path/to/file "Optional comment shown as a Slack message"
```

### Notes

- File uploads use `files.getUploadURLExternal` and `files.completeUploadExternal`.
- If a comment is supplied, it is posted as a normal Slack message before the file upload.

---

## Task: Confirm which channel will be used

### Goal
Verify the only channel this skill is allowed to use.

### Command

```bash
node /Users/kazuph/dotfiles/claude/skills/slack/scripts/slack-send.mjs channel
```

---

## Rules

- Never use browser automation for this skill.
- Never send to any channel other than the configured one.
- Stop if the token or channel cannot be resolved from the existing machine configuration.
