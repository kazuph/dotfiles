#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import process from "node:process";

const DEFAULT_TIMEOUT_SECONDS = 600;
const POLL_INTERVAL_MS = 3000;
const NUMBER_EMOJIS = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseEnvFile(filePath) {
  if (!fs.existsSync(filePath)) {
    return {};
  }

  const env = {};
  const content = fs.readFileSync(filePath, "utf8");
  for (const rawLine of content.split("\n")) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#") || !line.includes("=")) {
      continue;
    }
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

function loadCredentials() {
  const home = os.homedir();
  const envFiles = [
    path.join(home, "dotfiles", "claude", "hooks", ".env"),
    path.join(home, ".claude", "hooks", ".env"),
    path.join(home, ".config", "claude-slack", "credentials"),
  ];

  let token = process.env.SLACK_BOT_TOKEN || "";
  let channel =
    process.env.SLACK_CHANNEL ||
    process.env.SLACK_CHANNEL_ID ||
    "";

  for (const filePath of envFiles) {
    const env = parseEnvFile(filePath);
    token ||= env.SLACK_BOT_TOKEN || "";
    channel ||= env.SLACK_CHANNEL || env.SLACK_CHANNEL_ID || "";
  }

  if (!token) {
    token = readKeychainValue("SLACK_BOT_TOKEN");
  }
  if (!channel) {
    channel = readKeychainValue("SLACK_CHANNEL") || readKeychainValue("SLACK_CHANNEL_ID");
  }

  return { token, channel };
}

const GET_METHODS = new Set([
  "conversations.replies",
  "conversations.history",
  "conversations.info",
  "conversations.list",
  "conversations.members",
  "reactions.get",
  "users.info",
  "users.list",
]);

async function callSlackApi(token, method, params) {
  const isGet = GET_METHODS.has(method);
  const url = new URL(`https://slack.com/api/${method}`);
  const headers = { Authorization: `Bearer ${token}` };
  const fetchOptions = { signal: AbortSignal.timeout(30000) };

  if (isGet) {
    for (const [key, value] of Object.entries(params)) {
      url.searchParams.set(key, String(value));
    }
    fetchOptions.method = "GET";
    fetchOptions.headers = headers;
  } else {
    fetchOptions.method = "POST";
    headers["Content-Type"] = "application/json; charset=utf-8";
    fetchOptions.headers = headers;
    fetchOptions.body = JSON.stringify(params);
  }

  const response = await fetch(url.toString(), fetchOptions);
  const json = await response.json();
  if (!json.ok) {
    const error = new Error(json.error || "unknown_slack_error");
    error.payload = json;
    throw error;
  }
  return json;
}

function normalizeText(text) {
  return (text || "").normalize("NFKC").trim();
}

function parseDecision(text) {
  const normalized = normalizeText(text);
  if (!normalized) {
    return null;
  }

  const checks = [
    { regex: /^(3分承認|temp[- ]?allow|temporary[- ]?allow|ta)\b[:：\-\s]*/i, button: "3分間承認" },
    { regex: /^(3分却下|temp[- ]?reject|temporary[- ]?reject|tr)\b[:：\-\s]*/i, button: "3分間却下" },
    { regex: /^(承認|approve|approved|yes|y|ok|lgtm|go)\b[:：\-\s]*/i, button: "承認" },
    { regex: /^(却下|reject|rejected|cancel|no|n|stop|中止|キャンセル)\b[:：\-\s]*/i, button: "却下" },
  ];

  for (const check of checks) {
    if (check.regex.test(normalized)) {
      const reason = normalized.replace(check.regex, "").trim();
      return {
        button: check.button,
        reason: reason || normalized,
        raw: normalized,
      };
    }
  }

  return null;
}

// --- Block Kit Builders ---

function buildAskBlocks(question, optionsList, timeoutSeconds, meta) {
  const blocks = [
    {
      type: "header",
      text: { type: "plain_text", text: "🤖 Claude Code からの質問", emoji: true },
    },
  ];

  // Context fields (dir, branch, etc.)
  if (meta && Object.keys(meta).length > 0) {
    const fields = [];
    if (meta.repo) fields.push({ type: "mrkdwn", text: `*リポジトリ*\n\`${meta.repo}\`` });
    if (meta.branch) fields.push({ type: "mrkdwn", text: `*ブランチ*\n\`${meta.branch}\`` });
    if (fields.length > 0) {
      blocks.push({ type: "section", fields });
    }
  }

  blocks.push({
    type: "section",
    text: { type: "mrkdwn", text: `*${question}*` },
  });

  if (optionsList.length > 0) {
    blocks.push({ type: "divider" });
    const optionText = optionsList
      .map((opt, i) => `:${NUMBER_EMOJIS[i]}: ${opt}`)
      .join("\n");
    blocks.push({
      type: "section",
      text: { type: "mrkdwn", text: optionText },
    });
    blocks.push({
      type: "context",
      elements: [
        {
          type: "mrkdwn",
          text: `リアクションで選択 or スレッドに自由記述で返信  |  ⏱️ ${timeoutSeconds}秒`,
        },
      ],
    });
  } else {
    blocks.push({
      type: "context",
      elements: [
        {
          type: "mrkdwn",
          text: `スレッドに返信してください  |  ⏱️ ${timeoutSeconds}秒`,
        },
      ],
    });
  }

  return blocks;
}

function buildApprovalBlocks(title, description, timeoutSeconds, meta) {
  const blocks = [
    {
      type: "header",
      text: { type: "plain_text", text: "🔐 承認リクエスト", emoji: true },
    },
  ];

  if (meta && Object.keys(meta).length > 0) {
    // Structured table-like display with meta info
    const fields = [];
    if (meta.cmd) fields.push({ type: "mrkdwn", text: `*コマンド*\n\`${meta.cmd}\`` });
    if (meta.repo) fields.push({ type: "mrkdwn", text: `*リポジトリ*\n\`${meta.repo}\`` });
    if (meta.branch) fields.push({ type: "mrkdwn", text: `*ブランチ*\n\`${meta.branch}\`` });

    if (fields.length > 0) {
      blocks.push({ type: "section", fields });
    }

    // Full command as a code block if longer than the summary
    if (meta.full_cmd && meta.full_cmd !== meta.cmd) {
      blocks.push({
        type: "section",
        text: { type: "mrkdwn", text: `*実行コマンド全体*\n\`\`\`${meta.full_cmd}\`\`\`` },
      });
    }
  } else {
    // Fallback: plain text display
    blocks.push({
      type: "section",
      text: { type: "mrkdwn", text: `*${title}*` },
    });
    if (description) {
      blocks.push({
        type: "section",
        text: { type: "mrkdwn", text: description },
      });
    }
  }

  blocks.push({ type: "divider" });
  blocks.push({
    type: "section",
    text: {
      type: "mrkdwn",
      text: ":white_check_mark: 承認  |  :three: 3分承認  |  :x: 却下",
    },
  });
  blocks.push({
    type: "context",
    elements: [
      { type: "mrkdwn", text: `スレッド返信 = 却下（内容が理由に）| 承認はリアクションで  |  ⏱️ ${timeoutSeconds}秒` },
    ],
  });

  return blocks;
}

function buildNotifyBlocks(message) {
  return [
    {
      type: "header",
      text: { type: "plain_text", text: "📢 Claude Code からの通知", emoji: true },
    },
    {
      type: "section",
      text: { type: "mrkdwn", text: message },
    },
  ];
}

// --- Posting ---

async function postBlockMessage(token, channel, fallbackText, blocks) {
  return callSlackApi(token, "chat.postMessage", {
    channel,
    text: fallbackText,
    blocks,
  });
}

async function uploadFile(token, channel, filePath, threadTs) {
  const fileData = fs.readFileSync(filePath);
  const fileName = path.basename(filePath);

  // Step 1: Get upload URL (requires form-urlencoded)
  const urlRes = await fetch("https://slack.com/api/files.getUploadURLExternal", {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/x-www-form-urlencoded" },
    body: `filename=${encodeURIComponent(fileName)}&length=${fileData.length}`,
    signal: AbortSignal.timeout(30000),
  });
  const urlJson = await urlRes.json();
  if (!urlJson.ok) throw new Error(urlJson.error || "upload_url_failed");

  // Step 2: Upload file to the URL
  await fetch(urlJson.upload_url, { method: "POST", body: fileData });

  // Step 3: Complete the upload
  const completeBody = { files: [{ id: urlJson.file_id, title: fileName }] };
  if (channel) completeBody.channel_id = channel;
  if (threadTs) completeBody.thread_ts = threadTs;

  await callSlackApi(token, "files.completeUploadExternal", completeBody);
  return { file_id: urlJson.file_id, filename: fileName };
}

const MIME_TO_EXT = {
  "image/png": ".png",
  "image/jpeg": ".jpg",
  "image/gif": ".gif",
  "image/webp": ".webp",
  "image/heic": ".heic",
  "image/heif": ".heif",
  "image/svg+xml": ".svg",
  "application/pdf": ".pdf",
};

async function downloadSlackFile(token, fileUrl, destDir) {
  const response = await fetch(fileUrl, {
    headers: { Authorization: `Bearer ${token}` },
    signal: AbortSignal.timeout(30000),
  });
  if (!response.ok) return null;

  const buffer = Buffer.from(await response.arrayBuffer());
  const contentType = response.headers.get("content-type") || "";

  // Determine extension from Content-Type, fallback to URL path
  const urlPath = new URL(fileUrl).pathname;
  let fileName = path.basename(urlPath);
  const correctExt = MIME_TO_EXT[contentType.split(";")[0].trim()];
  if (correctExt && !fileName.endsWith(correctExt)) {
    fileName = fileName.replace(/\.[^.]+$/, "") + correctExt;
  }

  const destPath = path.join(destDir, `slack_${Date.now()}_${fileName}`);
  fs.writeFileSync(destPath, buffer);
  return { localPath: destPath, contentType: contentType.split(";")[0].trim(), size: buffer.length };
}

function extractFiles(message) {
  const files = message.files || [];
  return files
    .filter((f) => f.url_private && !f.is_external)
    .map((f) => ({
      id: f.id,
      name: f.name || f.title || "unknown",
      mimetype: f.mimetype || "",
      url: f.url_private,
      size: f.size || 0,
    }));
}

async function addReactions(token, channel, ts, emojiNames) {
  for (const name of emojiNames) {
    try {
      await callSlackApi(token, "reactions.add", { channel, timestamp: ts, name });
    } catch {
      // ignore duplicate reaction errors
    }
  }
}

// --- Waiting for response ---

async function waitForResponse({ token, channel, threadTs, botUserId, timeoutSeconds, mode, optionsList }) {
  const seen = new Set([threadTs]);
  const deadline = Date.now() + timeoutSeconds * 1000;

  while (Date.now() < deadline) {
    // Check reactions first (for ask with options or approval)
    if (mode === "ask" && optionsList.length > 0) {
      const reactionResult = await checkOptionReactions(token, channel, threadTs, botUserId, optionsList);
      if (reactionResult) return reactionResult;
    }
    if (mode === "decision") {
      const approvalResult = await checkApprovalReactions(token, channel, threadTs, botUserId);
      if (approvalResult) return approvalResult;
    }

    // Check thread replies as fallback
    const replies = await callSlackApi(token, "conversations.replies", {
      channel,
      ts: threadTs,
      inclusive: true,
      limit: 50,
    });

    for (const message of replies.messages || []) {
      if (!message.ts || seen.has(message.ts)) {
        continue;
      }
      seen.add(message.ts);

      if (message.subtype === "bot_message" || message.user === botUserId) {
        continue;
      }

      const text = message.text || "";
      const msgFiles = extractFiles(message);

      // Download any attached files to /tmp
      const downloadedFiles = [];
      for (const f of msgFiles) {
        const dl = await downloadSlackFile(token, f.url, os.tmpdir());
        if (dl) {
          downloadedFiles.push({ ...f, localPath: dl.localPath, contentType: dl.contentType, downloadedSize: dl.size });
        }
      }

      if (mode === "decision") {
        const decision = parseDecision(text);
        if (decision) {
          return {
            approved: decision.button === "承認" || decision.button === "3分間承認",
            button: decision.button,
            response: decision.reason,
            user: message.user || "",
            raw: decision.raw,
            files: downloadedFiles,
          };
        }
        // Any non-matching reply = reject with the reply text as reason
        return {
          approved: false,
          button: "却下",
          response: normalizeText(text),
          user: message.user || "",
          raw: normalizeText(text),
          files: downloadedFiles,
        };
      }

      return {
        approved: false,
        button: "custom",
        response: normalizeText(text),
        user: message.user || "",
        raw: normalizeText(text),
        files: downloadedFiles,
      };
    }

    await sleep(POLL_INTERVAL_MS);
  }

  throw new Error("timeout");
}

async function fetchMessageReactions(token, channel, ts) {
  try {
    const result = await callSlackApi(token, "conversations.history", {
      channel,
      latest: ts,
      inclusive: true,
      limit: 1,
    });
    return result.messages?.[0]?.reactions || [];
  } catch {
    return [];
  }
}

async function checkOptionReactions(token, channel, ts, botUserId, optionsList) {
  const reactions = await fetchMessageReactions(token, channel, ts);
  for (const reaction of reactions) {
    const idx = NUMBER_EMOJIS.indexOf(reaction.name);
    if (idx === -1 || idx >= optionsList.length) continue;
    const users = (reaction.users || []).filter((u) => u !== botUserId);
    if (users.length > 0) {
      return {
        approved: false,
        button: `option_${idx + 1}`,
        response: optionsList[idx],
        user: users[0],
        raw: optionsList[idx],
        optionIndex: idx,
      };
    }
  }
  return null;
}

async function checkApprovalReactions(token, channel, ts, botUserId) {
  const reactions = await fetchMessageReactions(token, channel, ts);
  for (const reaction of reactions) {
    const users = (reaction.users || []).filter((u) => u !== botUserId);
    if (users.length === 0) continue;
    if (reaction.name === "white_check_mark") {
      return { approved: true, button: "承認", response: "承認 (リアクション)", user: users[0], raw: "✅" };
    }
    if (reaction.name === "three") {
      return { approved: true, button: "3分間承認", response: "3分間承認 (リアクション)", user: users[0], raw: "3️⃣" };
    }
    if (reaction.name === "x") {
      return { approved: false, button: "却下", response: "却下 (リアクション)", user: users[0], raw: "❌" };
    }
  }
  return null;
}

// --- Utilities ---

function shellPrint(button, reason) {
  process.stdout.write(`${button}\n${reason || ""}\n`);
}

function jsonPrint(payload) {
  process.stdout.write(`${JSON.stringify(payload)}\n`);
}

function parseArgs(argv) {
  const args = [...argv];
  const options = {
    format: "json",
    timeoutSeconds: DEFAULT_TIMEOUT_SECONDS,
  };

  // Parse flags from anywhere in the args (before or after command)
  const remaining = [];
  while (args.length > 0) {
    const token = args[0];
    if (token === "--format") {
      args.shift();
      options.format = args.shift() || "json";
    } else if (token === "--timeout-seconds") {
      args.shift();
      options.timeoutSeconds = Number(args.shift() || DEFAULT_TIMEOUT_SECONDS);
    } else if (token === "--channel") {
      args.shift();
      options.channel = args.shift() || "";
    } else if (token === "--meta") {
      args.shift();
      try { options.meta = JSON.parse(args.shift() || "{}"); } catch { options.meta = {}; }
    } else {
      remaining.push(args.shift());
    }
  }

  const command = remaining.shift() || "";
  return { command, options, args: remaining };
}

async function authTest(token) {
  const result = await callSlackApi(token, "auth.test", {});
  return {
    user_id: result.user_id,
    team: result.team,
    bot_id: result.bot_id,
  };
}

// --- Main ---

async function main() {
  const { command, options, args } = parseArgs(process.argv.slice(2));
  const { token, channel: detectedChannel } = loadCredentials();
  const channel = options.channel || detectedChannel;

  if (!token || !channel) {
    throw new Error("missing_credentials");
  }

  if (command === "auth-test") {
    const result = await authTest(token);
    jsonPrint({ success: true, channel, ...result });
    return;
  }

  if (command === "notify") {
    const message = args.join(" ").trim();
    if (!message) {
      throw new Error("message_required");
    }
    const blocks = buildNotifyBlocks(message);
    const posted = await postBlockMessage(token, channel, message, blocks);
    jsonPrint({ success: true, channel, ts: posted.ts });
    return;
  }

  if (command === "upload") {
    const filePath = args[0] || "";
    const threadTs = args[1] || "";
    if (!filePath) {
      throw new Error("file_path_required");
    }
    if (!fs.existsSync(filePath)) {
      throw new Error(`file_not_found: ${filePath}`);
    }
    const result = await uploadFile(token, channel, filePath, threadTs || undefined);
    jsonPrint({ success: true, channel, ...result });
    return;
  }

  if (command === "ask") {
    const auth = await authTest(token);
    const question = args[0] || "";
    const optionsStr = args[1] || "";
    if (!question) {
      throw new Error("title_required");
    }

    const optionsList = optionsStr
      ? optionsStr.split(",").map((s) => s.trim()).filter(Boolean)
      : [];

    const blocks = buildAskBlocks(question, optionsList, options.timeoutSeconds, options.meta);
    const fallback = optionsList.length > 0
      ? `${question}\n${optionsList.map((o, i) => `${i + 1}. ${o}`).join("\n")}`
      : question;

    const posted = await postBlockMessage(token, channel, fallback, blocks);

    // Add number emoji reactions for options
    if (optionsList.length > 0) {
      const emojis = NUMBER_EMOJIS.slice(0, optionsList.length);
      await addReactions(token, channel, posted.ts, emojis);
    }

    const response = await waitForResponse({
      token,
      channel,
      threadTs: posted.ts,
      botUserId: auth.user_id,
      timeoutSeconds: options.timeoutSeconds,
      mode: "ask",
      optionsList,
    });

    const payload = {
      success: true,
      approved: response.approved,
      button: response.button,
      response: response.response,
      user: response.user,
      ts: posted.ts,
      channel,
    };
    if (response.optionIndex != null) {
      payload.optionIndex = response.optionIndex;
    }
    if (response.files?.length > 0) {
      payload.files = response.files;
    }

    if (options.format === "shell") {
      shellPrint(response.button, response.response);
      return;
    }
    jsonPrint(payload);
    return;
  }

  if (command === "approve") {
    const auth = await authTest(token);
    const title = args[0] || "";
    const description = args[1] || "";
    if (!title) {
      throw new Error("title_required");
    }

    const blocks = buildApprovalBlocks(title, description, options.timeoutSeconds, options.meta);
    const fallback = description ? `${title}\n${description}` : title;

    const posted = await postBlockMessage(token, channel, fallback, blocks);

    // Add approval/rejection emoji reactions
    await addReactions(token, channel, posted.ts, ["white_check_mark", "three", "x"]);

    const response = await waitForResponse({
      token,
      channel,
      threadTs: posted.ts,
      botUserId: auth.user_id,
      timeoutSeconds: options.timeoutSeconds,
      mode: "decision",
      optionsList: [],
    });

    const payload = {
      success: true,
      approved: response.approved,
      button: response.button,
      response: response.response,
      user: response.user,
      ts: posted.ts,
      channel,
    };
    if (response.files?.length > 0) {
      payload.files = response.files;
    }

    if (options.format === "shell") {
      shellPrint(response.button, response.response);
      return;
    }
    jsonPrint(payload);
    return;
  }

  throw new Error("unsupported_command");
}

main().catch((error) => {
  const message = error?.message || "unknown_error";
  jsonPrint({ success: false, error: message });
  process.exit(1);
});
