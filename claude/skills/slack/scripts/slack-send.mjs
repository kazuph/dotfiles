#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { execFileSync } from "node:child_process";

const ENV_FILES = [
  path.join(os.homedir(), "dotfiles", "claude", "hooks", ".env"),
  path.join(os.homedir(), ".claude", "hooks", ".env"),
  path.join(os.homedir(), ".config", "claude-slack", "credentials"),
];

function usage() {
  console.error(
    [
      "Usage:",
      "  slack-send.mjs channel",
      "  slack-send.mjs message <text>",
      "  slack-send.mjs file <absolute-or-relative-path> [comment] [title]",
    ].join("\n"),
  );
  process.exit(1);
}

function parseEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const env = {};
  for (const rawLine of fs.readFileSync(filePath, "utf8").split("\n")) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#") || !line.includes("=")) continue;
    const [key, ...rest] = line.split("=");
    const value = rest.join("=").trim().replace(/^['"]|['"]$/g, "");
    env[key.trim()] = value;
  }
  return env;
}

function readKeychainValue(service) {
  try {
    return execFileSync(
      "security",
      ["find-generic-password", "-w", "-a", "claude-slack", "-s", service],
      { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },
    ).trim();
  } catch {
    return "";
  }
}

function readPassValue(entry) {
  try {
    return execFileSync("pass", ["show", entry], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    })
      .trim()
      .split("\n")[0]
      .trim();
  } catch {
    return "";
  }
}

function loadCredentials() {
  let token = process.env.SLACK_BOT_TOKEN || "";
  let channel = process.env.SLACK_CHANNEL || process.env.SLACK_CHANNEL_ID || "";

  for (const envFile of ENV_FILES) {
    const env = parseEnvFile(envFile);
    token ||= env.SLACK_BOT_TOKEN || "";
    channel ||= env.SLACK_CHANNEL || env.SLACK_CHANNEL_ID || "";
  }

  token ||= readKeychainValue("SLACK_BOT_TOKEN");
  channel ||= readKeychainValue("SLACK_CHANNEL") || readKeychainValue("SLACK_CHANNEL_ID");

  token ||= readPassValue("claude/slack-bot-token");
  channel ||= readPassValue("claude/slack-channel");

  if (!token) throw new Error("SLACK_BOT_TOKEN is not configured");
  if (!channel) throw new Error("SLACK_CHANNEL is not configured");

  return { token, channel };
}

async function callSlackApi(token, method, params, useForm = false) {
  const url = `https://slack.com/api/${method}`;
  const headers = { Authorization: `Bearer ${token}` };
  const options = {
    method: "POST",
    headers,
    signal: AbortSignal.timeout(120_000),
  };

  if (useForm) {
    headers["Content-Type"] = "application/x-www-form-urlencoded";
    options.body = new URLSearchParams(params).toString();
  } else {
    headers["Content-Type"] = "application/json; charset=utf-8";
    options.body = JSON.stringify(params);
  }

  const response = await fetch(url, options);
  const json = await response.json();
  if (!json.ok) {
    throw new Error(`${method}: ${json.error || "unknown_slack_error"}`);
  }
  return json;
}

async function sendMessage(token, channel, text) {
  const result = await callSlackApi(token, "chat.postMessage", { channel, text });
  return { ok: true, type: "message", channel, ts: result.ts };
}

async function sendFile(token, channel, filePath, comment = "", title = "") {
  const resolvedPath = path.resolve(filePath);
  if (!fs.existsSync(resolvedPath)) {
    throw new Error(`file not found: ${resolvedPath}`);
  }

  const fileData = fs.readFileSync(resolvedPath);
  const fileName = path.basename(resolvedPath);
  const fileTitle = title || fileName;

  let messageTs = "";
  if (comment.trim()) {
    const messageResult = await callSlackApi(token, "chat.postMessage", {
      channel,
      text: comment,
    });
    messageTs = messageResult.ts || "";
  }

  const uploadMeta = await callSlackApi(
    token,
    "files.getUploadURLExternal",
    { filename: fileName, length: String(fileData.length) },
    true,
  );

  const uploadResponse = await fetch(uploadMeta.upload_url, {
    method: "POST",
    body: fileData,
    signal: AbortSignal.timeout(300_000),
  });
  if (!uploadResponse.ok) {
    throw new Error(`binary upload failed: ${uploadResponse.status}`);
  }

  await callSlackApi(token, "files.completeUploadExternal", {
    files: [{ id: uploadMeta.file_id, title: fileTitle }],
    channel_id: channel,
  });

  return {
    ok: true,
    type: "file",
    channel,
    file_id: uploadMeta.file_id,
    message_ts: messageTs,
    path: resolvedPath,
  };
}

async function main() {
  const [, , command, ...args] = process.argv;
  if (!command) usage();

  const { token, channel } = loadCredentials();

  if (command === "channel") {
    console.log(JSON.stringify({ ok: true, channel }, null, 2));
    return;
  }

  if (command === "message") {
    const text = args.join(" ").trim();
    if (!text) usage();
    console.log(JSON.stringify(await sendMessage(token, channel, text), null, 2));
    return;
  }

  if (command === "file") {
    const [filePath, comment = "", title = ""] = args;
    if (!filePath) usage();
    console.log(JSON.stringify(await sendFile(token, channel, filePath, comment, title), null, 2));
    return;
  }

  usage();
}

main().catch((error) => {
  console.error(error.message || String(error));
  process.exit(1);
});
