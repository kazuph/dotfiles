#!/usr/bin/env node

/**
 * Claude Code PreToolUse Hook - AskUserQuestion通知
 *
 * AskUserQuestionツールが呼ばれる直前にmacOS通知を送信し、
 * ユーザーに質問待ち状態であることを知らせる。
 */

const { execFileSync, execSync } = require("node:child_process");
const { readFileSync } = require("node:fs");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const debugLog = (msg) =>
  fs.appendFileSync(
    "/tmp/claude-ask-notify-debug.log",
    `[${new Date().toISOString()}] ${msg}\n`
  );

try {
  debugLog("Script started");
  const inputRaw = readFileSync(process.stdin.fd, "utf8");
  debugLog(`Input: ${inputRaw.substring(0, 300)}`);
  const input = JSON.parse(inputRaw);

  // tool_inputから質問内容を抽出
  let questionSummary = "質問があります";
  if (input.tool_input?.questions) {
    const firstQ = input.tool_input.questions[0];
    if (firstQ?.question) {
      questionSummary = firstQ.question.substring(0, 150);
    }
  }

  // ベルを鳴らす（tmuxの!フラグ用）
  try {
    execSync('printf "\\a" > /dev/tty 2>/dev/null || printf "\\a" >&2', {
      shell: true,
    });
  } catch (e) {
    // ベル失敗は無視
  }

  // tmux情報を取得
  let sessionName = "",
    windowIndex = "",
    paneIndex = "",
    paneTitle = "",
    tmuxSocket = "";
  let terminalApp = process.env.TERM_PROGRAM || "Ghostty";

  const tmuxEnv = process.env.TMUX || "";
  if (tmuxEnv) {
    tmuxSocket = tmuxEnv.split(",")[0];
  } else {
    try {
      const uid = execFileSync("id", ["-u"], { encoding: "utf8" }).trim();
      const guessedSocket = `/private/tmp/tmux-${uid}/default`;
      if (fs.existsSync(guessedSocket)) {
        tmuxSocket = guessedSocket;
      }
    } catch (e) {
      // 推測失敗
    }
  }

  const tmuxPane = process.env.TMUX_PANE || "";

  try {
    if (tmuxPane && tmuxSocket) {
      const tmuxArgs = [
        "-S",
        tmuxSocket,
        "display-message",
        "-t",
        tmuxPane,
        "-p",
      ];
      sessionName = execFileSync(
        "tmux",
        [...tmuxArgs, "#{session_name}"],
        { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }
      ).trim();
      windowIndex = execFileSync(
        "tmux",
        [...tmuxArgs, "#{window_index}"],
        { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }
      ).trim();
      paneIndex = execFileSync("tmux", [...tmuxArgs, "#{pane_index}"], {
        encoding: "utf8",
        stdio: ["pipe", "pipe", "ignore"],
      }).trim();
      paneTitle = execFileSync("tmux", [...tmuxArgs, "#{pane_title}"], {
        encoding: "utf8",
        stdio: ["pipe", "pipe", "ignore"],
      }).trim();
    } else {
      sessionName = execFileSync(
        "tmux",
        ["display-message", "-p", "#{session_name}"],
        { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }
      ).trim();
      windowIndex = execFileSync(
        "tmux",
        ["display-message", "-p", "#{window_index}"],
        { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }
      ).trim();
      paneIndex = execFileSync(
        "tmux",
        ["display-message", "-p", "#{pane_index}"],
        { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }
      ).trim();
      paneTitle = execFileSync(
        "tmux",
        ["display-message", "-p", "#{pane_title}"],
        { encoding: "utf8", stdio: ["pipe", "pipe", "ignore"] }
      ).trim();
    }
  } catch (e) {
    debugLog(`tmux error: ${e.message}`);
    sessionName = "";
  }

  // 通知タイトル
  const cleanTitle = paneTitle
    .replace(/^[^\x00-\x7F]+\s*/, "")
    .substring(0, 30);
  const notificationTitle = sessionName
    ? `Claude Code [${windowIndex}-${paneIndex}] ${cleanTitle}`.trim()
    : "Claude Code";

  const notifierPath = "/opt/homebrew/bin/terminal-notifier";

  const terminalAppMap = {
    Apple_Terminal: "Terminal",
    "iTerm.app": "iTerm",
    WezTerm: "WezTerm",
    kitty: "kitty",
    Alacritty: "Alacritty",
    Ghostty: "Ghostty",
  };
  const appName = terminalAppMap[terminalApp] || terminalApp;

  const tmuxCmd = tmuxSocket
    ? `/opt/homebrew/bin/tmux -S "${tmuxSocket}"`
    : "/opt/homebrew/bin/tmux";
  const focusCommand = sessionName
    ? [
        `osascript -e 'tell application "${appName}" to activate'`,
        `${tmuxCmd} select-window -t "${sessionName}:${windowIndex}"`,
        `${tmuxCmd} select-pane -t "${sessionName}:${windowIndex}.${paneIndex}"`,
      ].join(" && ")
    : "";

  const notifyMessage = `🙋 ${questionSummary}`;

  if (sessionName) {
    try {
      execFileSync(
        notifierPath,
        [
          "-title",
          notificationTitle,
          "-subtitle",
          "質問待ち",
          "-message",
          notifyMessage,
          "-sound",
          "default",
          "-execute",
          focusCommand,
        ],
        { stdio: "pipe" }
      );
    } catch (e) {
      const script = `display notification "${notifyMessage.replace(/"/g, '\\"')}" with title "${notificationTitle.replace(/"/g, '\\"')}" subtitle "質問待ち" sound name "default"`;
      execFileSync("osascript", ["-e", script], { stdio: "pipe" });
    }
  } else {
    try {
      execFileSync(
        notifierPath,
        [
          "-title",
          notificationTitle,
          "-subtitle",
          "質問待ち",
          "-message",
          notifyMessage,
          "-sound",
          "default",
        ],
        { stdio: "pipe" }
      );
    } catch (e) {
      const script = `display notification "${notifyMessage.replace(/"/g, '\\"')}" with title "${notificationTitle.replace(/"/g, '\\"')}" subtitle "質問待ち" sound name "default"`;
      execFileSync("osascript", ["-e", script], { stdio: "pipe" });
    }
  }

  debugLog("AskUserQuestion notification sent successfully");
} catch (error) {
  debugLog(`Error: ${error.message}`);
  process.exit(0);
}
