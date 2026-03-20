#!/usr/bin/env node

const { readFileSync } = require("node:fs");

function truncate(text, max = 200) {
  if (!text) return "";
  return text.length > max ? `${text.slice(0, max - 1)}…` : text;
}

try {
  const inputRaw = readFileSync(process.stdin.fd, "utf8");
  const input = JSON.parse(inputRaw);
  const questions = Array.isArray(input.tool_input?.questions) ? input.tool_input.questions : [];
  const first = questions[0] || {};
  const question = truncate(first.question || "質問があります");
  const options = Array.isArray(first.options)
    ? first.options.map((option) => option.label).filter(Boolean).slice(0, 5)
    : [];

  const optionArgs = options.map((label) => `"${String(label).replace(/"/g, '\\"')}"`).join(" ");
  const command = [
    "~/.claude/skills/slack-bridge/scripts/ask-via-slack.sh",
    `"${question.replace(/"/g, '\\"')}"`,
    optionArgs,
  ]
    .filter(Boolean)
    .join(" ");

  const reason = [
    "AskUserQuestion は Slack bridge にリダイレクトしてください。",
    "次のコマンドを Bash(run_in_background: true) で実行し、TaskOutput で待機してください。",
    command,
  ].join("\n");

  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: reason,
      },
    }),
  );
} catch (error) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: `AskUserQuestion を Slack bridge にリダイレクトしてください。hook error: ${error.message}`,
      },
    }),
  );
}
