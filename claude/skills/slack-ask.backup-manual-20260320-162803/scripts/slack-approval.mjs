#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import process from "node:process";

const DEFAULT_TIMEOUT_SECONDS = 600;
const POLL_INTERVAL_MS = 3000;
const NUMBER_EMOJIS = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];
const CODEX_NOTIFY_TMUX_PANE = process.env.SLACK_APPROVAL_CODEX_TMUX_PANE || "%91";
const CODEX_NOTIFY_DELAY_MS = Number(process.env.SLACK_APPROVAL_CODEX_NOTIFY_DELAY_MS || 200);
const SLACK_ATTENTION_MENTION = process.env.SLACK_APPROVAL_MENTION || "<@U06778BS5LK>";
const THREAD_CACHE_FILE = path.join(os.homedir(), ".slack-approval-threads.json");
const MAX_THREAD_MESSAGES = 30;

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

function sleepSync(ms) {
  const waitMs = Math.max(0, Number(ms) || 0);
  if (waitMs === 0) {
    return;
  }
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, waitMs);
}

function detectInvokerProcessName() {
  try {
    return execFileSync(
      "ps",
      ["-o", "comm=", "-p", String(process.ppid)],
      { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },
    ).trim();
  } catch {
    return "";
  }
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
    { regex: /^(?:3分承認|temp[- ]?allow\b|temporary[- ]?allow\b|ta\b)[:：\-\s]*/i, button: "3分間承認" },
    { regex: /^(?:3分却下|temp[- ]?reject\b|temporary[- ]?reject\b|tr\b)[:：\-\s]*/i, button: "3分間却下" },
    { regex: /^(?:承認|approve\b|approved\b|yes\b|y\b|ok\b|lgtm\b|go\b)[:：\-\s]*/i, button: "承認" },
    { regex: /^(?:却下|reject\b|rejected\b|cancel\b|no\b|n\b|stop\b|中止|キャンセル)[:：\-\s]*/i, button: "却下" },
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

function buildHeaderText(label, statusText, locationLabel = "") {
  const mention = (SLACK_ATTENTION_MENTION || "").trim();
  const pieces = [label];
  if (mention) pieces.push(mention);
  if (locationLabel) pieces.push(locationLabel);
  return `【${statusText}】${pieces.join(" | ")}`;
}

function deriveLocationLabel(meta = {}) {
  const parts = [];
  const dir = meta?.dir || "";
  if (dir) {
    const base = path.basename(dir);
    parts.push(base && base !== "." ? base : dir);
  }
  if (meta?.branch) {
    parts.push(meta.branch);
  }
  return parts.join(" | ");
}

function buildAskBlocks(question, optionsList, timeoutSeconds, meta, statusText = ":hourglass_flowing_sand: 回答待ち") {
  const blocks = [
    {
      type: "context",
      elements: [{ type: "mrkdwn", text: buildHeaderText("質問", statusText) }],
    },
  ];

  if (meta && Object.keys(meta).length > 0) {
    const lines = [];
    const repoBits = [];
    if (meta.repo) repoBits.push(`*リポジトリ* \`${meta.repo}\``);
    if (meta.branch) repoBits.push(`*ブランチ* \`${meta.branch}\``);
    if (repoBits.length > 0) lines.push(repoBits.join(" | "));
    if (meta.dir) lines.push(`*ディレクトリ* \`${meta.dir}\``);
    if (lines.length > 0) {
      blocks.push({
        type: "section",
        text: { type: "mrkdwn", text: lines.join("\n") },
      });
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

function buildApprovalBlocks(title, description, timeoutSeconds, meta, statusText = ":hourglass_flowing_sand: 確認待ち") {
  const blocks = [
    {
      type: "context",
      elements: [{ type: "mrkdwn", text: buildHeaderText("コマンド確認", statusText) }],
    },
  ];

  if (meta && Object.keys(meta).length > 0) {
    const lines = [];
    if (meta.cmd) lines.push(`*コマンド* \`${meta.cmd}\``);
    const repoBits = [];
    if (meta.repo) repoBits.push(`*リポジトリ* \`${meta.repo}\``);
    if (meta.branch) repoBits.push(`*ブランチ* \`${meta.branch}\``);
    if (repoBits.length > 0) lines.push(repoBits.join(" | "));
    if (meta.dir) lines.push(`*ディレクトリ* \`${meta.dir}\``);

    if (lines.length > 0) {
      blocks.push({
        type: "section",
        text: { type: "mrkdwn", text: lines.join("\n") },
      });
    }
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
    type: "context",
    elements: [
      { type: "mrkdwn", text: `スレッド返信 = 却下（内容が理由に）  |  ⏱️ ${timeoutSeconds}秒` },
    ],
  });

  return blocks;
}

function buildNotifyBlocks(message, meta = {}) {
  const locationLabel = [deriveLocationLabel(meta), "no reply"].filter(Boolean).join(" | ");
  return [
    {
      type: "context",
      elements: [{ type: "mrkdwn", text: buildHeaderText("通知", "通知", locationLabel) }],
    },
    {
      type: "section",
      text: { type: "mrkdwn", text: message },
    },
  ];
}

function withAttentionMention(text) {
  const mention = (SLACK_ATTENTION_MENTION || "").trim();
  if (!mention) {
    return text;
  }
  return `${mention} ${text}`.trim();
}

// --- Posting ---

async function postBlockMessage(token, channel, fallbackText, blocks) {
  return postBlockMessageInThread(token, channel, fallbackText, blocks);
}

async function postBlockMessageInThread(token, channel, fallbackText, blocks, threadTs, replyBroadcast = false) {
  return callSlackApi(token, "chat.postMessage", {
    channel,
    text: fallbackText,
    blocks,
    ...(threadTs ? { thread_ts: threadTs } : {}),
    ...(threadTs && replyBroadcast ? { reply_broadcast: true } : {}),
  });
}

async function updateBlockMessage(token, channel, ts, fallbackText, blocks) {
  return callSlackApi(token, "chat.update", {
    channel,
    ts,
    text: fallbackText,
    blocks,
  });
}

async function deleteMessage(token, channel, ts) {
  return callSlackApi(token, "chat.delete", {
    channel,
    ts,
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

function readThreadCache() {
  try {
    if (!fs.existsSync(THREAD_CACHE_FILE)) {
      return {};
    }
    const parsed = JSON.parse(fs.readFileSync(THREAD_CACHE_FILE, "utf8"));
    return parsed && typeof parsed === "object" ? parsed : {};
  } catch {
    return {};
  }
}

function writeThreadCache(cache) {
  try {
    fs.writeFileSync(THREAD_CACHE_FILE, JSON.stringify(cache, null, 2));
    fs.chmodSync(THREAD_CACHE_FILE, 0o600);
  } catch {
    // ignore cache write failures
  }
}

function getThreadCacheKey(channel, meta) {
  if (!channel || !meta?.dir) {
    return "";
  }
  return `${channel}:${meta.dir}`;
}

function getReusableThread(channel, meta) {
  const key = getThreadCacheKey(channel, meta);
  if (!key) {
    return { key: "", rootTs: "" };
  }
  const cache = readThreadCache();
  const entry = cache[key];
  if (!entry?.rootTs || !Number(entry.count)) {
    return { key, rootTs: "" };
  }
  if (Number(entry.count) >= MAX_THREAD_MESSAGES) {
    return { key, rootTs: "" };
  }
  return { key, rootTs: entry.rootTs };
}

function recordPostedThread(channel, meta, rootTs, postedTs) {
  const key = getThreadCacheKey(channel, meta);
  if (!key || !postedTs) {
    return;
  }

  const cache = readThreadCache();
  const prev = cache[key];
  if (rootTs && prev?.rootTs === rootTs) {
    cache[key] = {
      rootTs,
      count: Math.min(Number(prev.count || 0) + 1, MAX_THREAD_MESSAGES),
      updatedAt: Date.now(),
    };
  } else {
    cache[key] = {
      rootTs: postedTs,
      count: 1,
      updatedAt: Date.now(),
    };
  }
  writeThreadCache(cache);
}

function clearRecordedThread(channel, meta) {
  const key = getThreadCacheKey(channel, meta);
  if (!key) {
    return;
  }
  const cache = readThreadCache();
  if (!cache[key]) {
    return;
  }
  delete cache[key];
  writeThreadCache(cache);
}

async function postPromptMessage(token, channel, fallbackText, blocks, meta) {
  const threadInfo = getReusableThread(channel, meta);
  let posted;
  let parentThreadTs = threadInfo.rootTs || "";
  const replyBroadcast = Boolean(threadInfo.rootTs);

  try {
    posted = await postBlockMessageInThread(token, channel, fallbackText, blocks, threadInfo.rootTs || undefined, replyBroadcast);
    parentThreadTs = threadInfo.rootTs || posted.ts;
  } catch (error) {
    const slackError = error?.message || error?.payload?.error || "";
    if (threadInfo.rootTs && (slackError === "thread_not_found" || slackError === "invalid_thread_ts")) {
      clearRecordedThread(channel, meta);
      posted = await postBlockMessageInThread(token, channel, fallbackText, blocks);
      parentThreadTs = posted.ts;
    } else {
      throw error;
    }
  }

  recordPostedThread(channel, meta, parentThreadTs, posted.ts);

  return {
    ...posted,
    parent_thread_ts: parentThreadTs,
  };
}

async function postApprovalRequest(token, channel, timeoutSeconds, meta, title, description) {
  const blocks = buildApprovalBlocks(title, description, timeoutSeconds, meta);
  const fallback = withAttentionMention(description ? `${title}\n${description}` : title);
  const posted = await postPromptMessage(token, channel, fallback, blocks, meta);
  await addReactions(token, channel, posted.ts, ["white_check_mark", "three", "x"]);
  return posted;
}

function buildApprovalResolutionBlocks({ button, reason, source, title, description }) {
  const isApproved = button === "承認" || button === "3分間承認";
  const statusText = isApproved ? ":white_check_mark: 承認済み" : ":x: 却下済み";
  const sourceText = source === "dialog"
    ? "AppleScript ダイアログ"
    : source === "slack"
      ? "Slack"
      : "不明";

  const blocks = [
    {
      type: "context",
      elements: [{ type: "mrkdwn", text: buildHeaderText("コマンド確認", statusText) }],
    },
  ];

  if (title || description) {
    const originalLines = [];
    if (title) originalLines.push(`*元の確認*\n${title}`);
    if (description) originalLines.push(description);
    blocks.push({
      type: "section",
      text: { type: "mrkdwn", text: originalLines.join("\n\n") },
    });
  }

  blocks.push({
    type: "section",
    text: {
      type: "mrkdwn",
      text: `*結果* ${button}\n*操作元* ${sourceText}${reason ? `\n*理由* ${reason}` : ""}`,
    },
  });

  return blocks;
}

function buildAskResolutionBlocks({ question, optionsList, timeoutSeconds, meta, response }) {
  const blocks = buildAskBlocks(question, optionsList, timeoutSeconds, meta, ":white_check_mark: 回答済み");
  blocks.push({
    type: "section",
    text: { type: "mrkdwn", text: `*回答* ${response}` },
  });
  return blocks;
}

async function resolveAskRequest(token, channel, ts, { question, optionsList, timeoutSeconds, meta, response }) {
  const blocks = buildAskResolutionBlocks({ question, optionsList, timeoutSeconds, meta, response });
  const fallback = [question, response].filter(Boolean).join("\n");
  await updateBlockMessage(token, channel, ts, fallback, blocks);
  return { action: "update" };
}

async function resolveApprovalRequest(token, channel, ts, { button, reason, source, resolution, title, description }) {
  if (resolution === "delete") {
    await deleteMessage(token, channel, ts);
    return { action: "delete" };
  }

  if (resolution === "delete_or_update") {
    try {
      await deleteMessage(token, channel, ts);
      return { action: "delete" };
    } catch {
      // Fall through to update when deletion is unavailable.
    }
  }

  const blocks = buildApprovalResolutionBlocks({ button, reason, source, title, description });
  const fallbackBase = [title, description, `${button}${reason ? `: ${reason}` : ""} (${source})`]
    .filter(Boolean)
    .join("\n");
  const fallback = fallbackBase || `${button}${reason ? `: ${reason}` : ""} (${source})`;
  await updateBlockMessage(token, channel, ts, fallback, blocks);
  return { action: "update" };
}

// --- Waiting for response ---

async function waitForResponse({ token, channel, threadTs, promptTs, botUserId, timeoutSeconds, mode, optionsList }) {
  const seen = new Set();
  const deadline = Date.now() + timeoutSeconds * 1000;
  const promptTsNumber = Number(promptTs || threadTs || 0);

  while (Date.now() < deadline) {
    // Check reactions first (for ask with options or approval)
    if (mode === "ask" && optionsList.length > 0) {
      const reactionResult = await checkOptionReactions(token, channel, promptTs || threadTs, botUserId, optionsList);
      if (reactionResult) return reactionResult;
    }
    if (mode === "decision") {
      const approvalResult = await checkApprovalReactions(token, channel, promptTs || threadTs, botUserId);
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
      if (Number(message.ts) <= promptTsNumber) {
        seen.add(message.ts);
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
    } else if (token === "--thread-ts") {
      args.shift();
      options.threadTs = args.shift() || "";
    } else if (token === "--resolution") {
      args.shift();
      options.resolution = args.shift() || "update";
    } else if (token === "--source") {
      args.shift();
      options.source = args.shift() || "";
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

function deriveRuntimeMeta(meta = {}) {
  const merged = { ...(meta || {}) };

  merged.dir ||= process.cwd();

  if (!merged.branch) {
    try {
      merged.branch = execFileSync(
        "git",
        ["rev-parse", "--abbrev-ref", "HEAD"],
        { encoding: "utf8", cwd: merged.dir, stdio: ["ignore", "pipe", "ignore"] },
      ).trim();
    } catch {
      // ignore
    }
  }

  if (!merged.repo) {
    try {
      const repoRoot = execFileSync(
        "git",
        ["rev-parse", "--show-toplevel"],
        { encoding: "utf8", cwd: merged.dir, stdio: ["ignore", "pipe", "ignore"] },
      ).trim();
      if (repoRoot) {
        merged.repo = path.basename(repoRoot);
      }
    } catch {
      // ignore
    }
  }

  merged.process ||= detectInvokerProcessName() || path.basename(process.env._ || process.argv[0] || "node");

  return merged;
}

function shouldNotifyCodex(meta = {}) {
  return /codex/i.test(meta?.process || "");
}

function tmuxPaneExists(paneId) {
  if (!paneId) {
    return false;
  }
  try {
    const panes = execFileSync(
      "tmux",
      ["list-panes", "-a", "-F", "#{pane_id}"],
      { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },
    );
    return panes.split("\n").some((pane) => pane.trim() === paneId);
  } catch {
    return false;
  }
}

function notifyCodexPane(meta = {}, message) {
  if (!shouldNotifyCodex(meta) || !message || !tmuxPaneExists(CODEX_NOTIFY_TMUX_PANE)) {
    return;
  }
  try {
    execFileSync(
      "tmux",
      ["send-keys", "-t", CODEX_NOTIFY_TMUX_PANE, "-l", message],
      { stdio: ["ignore", "ignore", "ignore"] },
    );
    sleepSync(CODEX_NOTIFY_DELAY_MS);
    execFileSync(
      "tmux",
      ["send-keys", "-t", CODEX_NOTIFY_TMUX_PANE, "Enter"],
      { stdio: ["ignore", "ignore", "ignore"] },
    );
  } catch {
    // ignore tmux notification failures
  }
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

  if (command === "tmux-notify-test") {
    const meta = deriveRuntimeMeta(options.meta);
    const message = args.join(" ").trim() || `Slack helper finished in ${meta.dir || process.cwd()}.`;
    notifyCodexPane(meta, message);
    jsonPrint({ success: true, notified: shouldNotifyCodex(meta), pane: CODEX_NOTIFY_TMUX_PANE, message });
    return;
  }

  if (command === "notify") {
    const message = args.join(" ").trim();
    if (!message) {
      throw new Error("message_required");
    }
    const notifyMeta = deriveRuntimeMeta(options.meta);
    const blocks = buildNotifyBlocks(message, notifyMeta);
    const posted = await postBlockMessage(token, channel, withAttentionMention(message), blocks);
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

    const askMeta = deriveRuntimeMeta(options.meta);
    const blocks = buildAskBlocks(question, optionsList, options.timeoutSeconds, askMeta);
    const fallback = withAttentionMention(optionsList.length > 0
      ? `${question}\n${optionsList.map((o, i) => `${i + 1}. ${o}`).join("\n")}`
      : question);

    const posted = await postPromptMessage(token, channel, fallback, blocks, askMeta);

    // Add number emoji reactions for options
    if (optionsList.length > 0) {
      const emojis = NUMBER_EMOJIS.slice(0, optionsList.length);
      await addReactions(token, channel, posted.ts, emojis);
    }

    const response = await waitForResponse({
      token,
      channel,
      threadTs: posted.parent_thread_ts || posted.ts,
      promptTs: posted.ts,
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
      thread_ts: posted.parent_thread_ts || posted.ts,
      channel,
    };
    if (response.optionIndex != null) {
      payload.optionIndex = response.optionIndex;
    }
    if (response.files?.length > 0) {
      payload.files = response.files;
    }

    await resolveAskRequest(token, channel, posted.ts, {
      question,
      optionsList,
      timeoutSeconds: options.timeoutSeconds,
      meta: askMeta,
      response: response.response,
    });

    if (options.format === "shell") {
      notifyCodexPane(askMeta, `Slack ask complete in ${askMeta.dir || process.cwd()}. Check result.`);
      shellPrint(response.button, response.response);
      return;
    }
    notifyCodexPane(askMeta, `Slack ask complete in ${askMeta.dir || process.cwd()}. Check result.`);
    jsonPrint(payload);
    return;
  }

  if (command === "approve-post") {
    const title = args[0] || "";
    const description = args[1] || "";
    if (!title) {
      throw new Error("title_required");
    }

    const auth = await authTest(token);
    const posted = await postApprovalRequest(token, channel, options.timeoutSeconds, options.meta, title, description);

    jsonPrint({
      success: true,
      channel,
      ts: posted.ts,
      thread_ts: posted.parent_thread_ts || posted.ts,
      user_id: auth.user_id,
    });
    return;
  }

  if (command === "approve-wait") {
    const threadTs = options.threadTs || args[0] || "";
    if (!threadTs) {
      throw new Error("thread_ts_required");
    }

    const auth = await authTest(token);
    const waitMeta = deriveRuntimeMeta(options.meta);
    const response = await waitForResponse({
      token,
      channel,
      threadTs,
      promptTs: threadTs,
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
      ts: threadTs,
      channel,
    };
    if (response.files?.length > 0) {
      payload.files = response.files;
    }

    if (options.format === "shell") {
      notifyCodexPane(waitMeta, `Slack approval complete in ${waitMeta.dir || process.cwd()}. Check result.`);
      shellPrint(response.button, response.response);
      return;
    }
    notifyCodexPane(waitMeta, `Slack approval complete in ${waitMeta.dir || process.cwd()}. Check result.`);
    jsonPrint(payload);
    return;
  }

  if (command === "approve-resolve") {
    const threadTs = options.threadTs || args[0] || "";
    const button = args[1] || "";
    const reason = args[2] || "";
    const title = args[3] || "";
    const description = args[4] || "";
    if (!threadTs) {
      throw new Error("thread_ts_required");
    }
    if (!button) {
      throw new Error("button_required");
    }

    const result = await resolveApprovalRequest(token, channel, threadTs, {
      button,
      reason,
      title,
      description,
      source: options.source || "unknown",
      resolution: options.resolution || "update",
    });

    jsonPrint({
      success: true,
      channel,
      ts: threadTs,
      action: result.action,
    });
    return;
  }

  if (command === "approve") {
    const auth = await authTest(token);
    const title = args[0] || "";
    const description = args[1] || "";
    if (!title) {
      throw new Error("title_required");
    }

    const approveMeta = deriveRuntimeMeta(options.meta);
    const posted = await postApprovalRequest(token, channel, options.timeoutSeconds, approveMeta, title, description);

    const response = await waitForResponse({
      token,
      channel,
      threadTs: posted.parent_thread_ts || posted.ts,
      promptTs: posted.ts,
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
      thread_ts: posted.parent_thread_ts || posted.ts,
      channel,
    };
    if (response.files?.length > 0) {
      payload.files = response.files;
    }

    if (options.format === "shell") {
      notifyCodexPane(approveMeta, `Slack approval complete in ${approveMeta.dir || process.cwd()}. Check result.`);
      shellPrint(response.button, response.response);
      return;
    }
    notifyCodexPane(approveMeta, `Slack approval complete in ${approveMeta.dir || process.cwd()}. Check result.`);
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
