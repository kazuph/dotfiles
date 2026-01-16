import 'dotenv/config';
import { createServer } from 'http';
import { execSync } from 'child_process';
import crypto from 'crypto';

const BOT_TOKEN = process.env.SLACK_BOT_TOKEN;
const SIGNING_SECRET = process.env.SLACK_SIGNING_SECRET;
const CHANNEL_ID = process.env.SLACK_CHANNEL_ID;

// 保留中の質問を保存 (questionId -> { resolve, questions, messageTs, sessionInfo })
const pendingQuestions = new Map();

// Slackリクエストの署名検証
function verifySlackRequest(req, body) {
  if (!SIGNING_SECRET) {
    console.warn('Warning: SLACK_SIGNING_SECRET not set, skipping verification');
    return true;
  }

  const timestamp = req.headers['x-slack-request-timestamp'];
  const slackSignature = req.headers['x-slack-signature'];

  if (!timestamp || !slackSignature) return false;

  // リプレイ攻撃防止（5分以上古いリクエストは拒否）
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - parseInt(timestamp)) > 300) return false;

  const sigBasestring = `v0:${timestamp}:${body}`;
  const mySignature = 'v0=' + crypto
    .createHmac('sha256', SIGNING_SECRET)
    .update(sigBasestring)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(mySignature),
    Buffer.from(slackSignature)
  );
}

// Slack APIでメッセージ送信
async function postToSlack(channel, text, blocks, threadTs = null) {
  const payload = { channel, text, blocks };
  if (threadTs) {
    payload.thread_ts = threadTs;
  }
  const response = await fetch('https://slack.com/api/chat.postMessage', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${BOT_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });
  return response.json();
}

// 質問用のSlack Blocksを構築
function buildQuestionBlocks(questionId, questionIndex, question) {
  const blocks = [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: `🤖 ${question.header || 'Claude Code'}`,
      },
    },
    {
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: question.question,
      },
    },
    {
      type: 'divider',
    },
  ];

  // 選択肢をボタンとして追加
  const buttons = question.options.map((opt, idx) => ({
    type: 'button',
    text: {
      type: 'plain_text',
      text: opt.label,
    },
    value: JSON.stringify({
      questionId,
      questionIndex,
      optionIndex: idx,
      label: opt.label,
    }),
    action_id: `answer_${questionId}_${questionIndex}_${idx}`,
  }));

  // 「その他（自由記述）」ボタンを必ず追加
  buttons.push({
    type: 'button',
    text: {
      type: 'plain_text',
      text: '✏️ その他（自由記述）',
    },
    style: 'primary',
    value: JSON.stringify({
      questionId,
      questionIndex,
      question: question.question,
    }),
    action_id: `freetext_${questionId}_${questionIndex}`,
  });

  // ボタンを5個ずつのグループに分割（Slackの制限）
  for (let i = 0; i < buttons.length; i += 5) {
    blocks.push({
      type: 'actions',
      elements: buttons.slice(i, i + 5),
    });
  }

  return blocks;
}

// 自由記述用モーダルを構築
function buildFreeTextModal(questionId, questionIndex, originalQuestion) {
  return {
    type: 'modal',
    callback_id: `freetext_modal`,
    title: {
      type: 'plain_text',
      text: '自由記述で回答',
    },
    submit: {
      type: 'plain_text',
      text: '送信',
    },
    close: {
      type: 'plain_text',
      text: 'キャンセル',
    },
    private_metadata: JSON.stringify({ questionId, questionIndex }),
    blocks: [
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*質問:*\n${originalQuestion}`,
        },
      },
      {
        type: 'input',
        block_id: 'freetext_input',
        element: {
          type: 'plain_text_input',
          action_id: 'freetext_value',
          multiline: true,
          placeholder: {
            type: 'plain_text',
            text: '回答を入力してください...',
          },
        },
        label: {
          type: 'plain_text',
          text: '回答',
        },
      },
    ],
  };
}

// モーダルを開く
async function openModal(triggerId, view) {
  const response = await fetch('https://slack.com/api/views.open', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${BOT_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      trigger_id: triggerId,
      view: view,
    }),
  });
  return response.json();
}

// tmux send-keys を実行
function sendToTmux(paneId, text) {
  try {
    const escaped = text.replace(/"/g, '\\"');
    execSync(`tmux send-keys -t "${paneId}" "${escaped}" Enter`);
    console.log(`Sent to tmux pane ${paneId}: ${text}`);
    return true;
  } catch (err) {
    console.error(`Failed to send to tmux: ${err.message}`);
    return false;
  }
}

// Ghosttyをアクティブ化し、tmux paneを選択
function activateTerminal(paneId) {
  if (!paneId) return;

  try {
    // Ghosttyをアクティブ化（AppleScript）
    execSync(`osascript -e 'tell application "Ghostty" to activate'`);

    // paneId は "session:window.pane" 形式（例: "0:2.1"）
    // まずwindowを選択し、次にpaneを選択
    execSync(`tmux select-window -t "${paneId}" 2>/dev/null || true`);
    execSync(`tmux select-pane -t "${paneId}"`);
    console.log(`Activated Ghostty and selected pane: ${paneId}`);
  } catch (err) {
    console.error(`Failed to activate terminal: ${err.message}`);
  }
}

// HTTPサーバー
const server = createServer(async (req, res) => {
  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', async () => {
    const url = new URL(req.url, `http://${req.headers.host}`);

    try {
      // ヘルスチェック
      if (req.method === 'GET' && url.pathname === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok', pending: pendingQuestions.size }));
        return;
      }

      // スキルからの質問送信（Long-polling）
      if (req.method === 'POST' && url.pathname === '/ask-and-wait') {
        const data = JSON.parse(body);
        const { questionId, questions, sessionInfo, paneId } = data;

        // Slackにメッセージ送信し、tsを保存
        let messageTs = null;
        for (let i = 0; i < questions.length; i++) {
          const q = questions[i];
          // セッション情報をヘッダーに追加
          if (sessionInfo) {
            q.header = `${q.header || 'Claude Code'} [${sessionInfo}]`;
          }
          const blocks = buildQuestionBlocks(questionId, i, q);
          const result = await postToSlack(CHANNEL_ID, `🤖 Claude Code: ${q.question}`, blocks);
          console.log(`Slack message sent: ${result.ts || result.error}`);
          if (result.ts && !messageTs) {
            messageTs = result.ts;
          }
        }

        console.log(`New question (long-polling): ${questionId}, session: ${sessionInfo || 'unknown'}, pane: ${paneId || 'none'}`);

        // Long-polling: Promiseを作成してMapに保存、回答が来るまでレスポンスを保留
        const answerPromise = new Promise((resolve) => {
          pendingQuestions.set(questionId, { resolve, questions, messageTs, sessionInfo, paneId });
        });

        // 回答を待つ（タイムアウト: 10分）
        const timeout = setTimeout(() => {
          const pending = pendingQuestions.get(questionId);
          if (pending) {
            pending.resolve({ error: 'timeout', message: 'No answer received within 10 minutes' });
            pendingQuestions.delete(questionId);
          }
        }, 600000);

        const answer = await answerPromise;
        clearTimeout(timeout);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(answer));
        return;
      }

      // PreToolUse hookからの質問送信（tmuxモード）
      if (req.method === 'POST' && url.pathname === '/ask') {
        const data = JSON.parse(body);
        const { questions, tmuxPane, sessionId } = data;

        const questionId = `q_${Date.now()}`;
        pendingQuestions.set(questionId, { tmuxPane, questions, sessionId, mode: 'tmux' });
        console.log(`New question (tmux mode): ${questionId}, pane: ${tmuxPane}`);

        // Slackにメッセージ送信
        for (let i = 0; i < questions.length; i++) {
          const q = questions[i];
          const blocks = buildQuestionBlocks(questionId, i, q);
          const result = await postToSlack(CHANNEL_ID, `🤖 Claude Code: ${q.question}`, blocks);
          console.log(`Slack message sent: ${result.ts || result.error}`);
        }

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, questionId }));
        return;
      }

      // Slackからのインタラクション（ボタンクリック）
      if (req.method === 'POST' && url.pathname === '/slack/interactions') {
        // 署名検証
        if (!verifySlackRequest(req, body)) {
          console.error('Invalid Slack signature');
          res.writeHead(401);
          res.end('Unauthorized');
          return;
        }

        const payload = JSON.parse(new URLSearchParams(body).get('payload'));
        console.log(`Slack interaction: ${payload.type}`);

        if (payload.type === 'block_actions') {
          const action = payload.actions[0];
          const actionId = action.action_id;

          // 自由記述ボタンがクリックされた場合
          if (actionId.startsWith('freetext_')) {
            const data = JSON.parse(action.value);
            const { questionId, questionIndex, question } = data;

            const pending = pendingQuestions.get(questionId);
            if (!pending) {
              res.writeHead(200, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ text: '⚠️ この質問は既に回答済みか、期限切れです。' }));
              return;
            }

            // モーダルを開く
            const modal = buildFreeTextModal(questionId, questionIndex, question);
            const result = await openModal(payload.trigger_id, modal);
            console.log(`Modal opened: ${result.ok ? 'success' : result.error}`);

            res.writeHead(200);
            res.end();
            return;
          }

          // 通常の選択肢ボタンがクリックされた場合
          const data = JSON.parse(action.value);
          const { questionId, optionIndex, label } = data;

          const pending = pendingQuestions.get(questionId);
          if (!pending) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ text: '⚠️ この質問は既に回答済みか、期限切れです。' }));
            return;
          }

          const { resolve, messageTs, paneId } = pending;

          // Long-pollingのresolveを呼び出して回答を返す
          resolve({
            answer: label,
            optionIndex: optionIndex,
            timestamp: Date.now(),
          });

          pendingQuestions.delete(questionId);
          console.log(`Answer resolved: ${questionId} -> ${label}`);

          // Ghosttyをアクティブ化し、tmux paneを選択
          activateTerminal(paneId);

          // スレッドに回答を投稿
          if (messageTs) {
            await postToSlack(
              CHANNEL_ID,
              `✅ 回答: *${label}*`,
              null,
              messageTs
            );
          }

          // Slackのレスポンス（元のメッセージを更新）
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            replace_original: true,
            text: `🤖 Claude Code からの質問（回答済み）`,
          }));
          return;
        }

        // モーダル送信（自由記述）
        if (payload.type === 'view_submission') {
          const metadata = JSON.parse(payload.view.private_metadata);
          const { questionId } = metadata;
          const freeText = payload.view.state.values.freetext_input.freetext_value.value;

          const pending = pendingQuestions.get(questionId);
          if (!pending) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
              response_action: 'errors',
              errors: { freetext_input: 'この質問は既に回答済みか、期限切れです。' }
            }));
            return;
          }

          const { resolve, messageTs, paneId } = pending;

          // Long-pollingのresolveを呼び出して回答を返す
          resolve({
            answer: freeText,
            optionIndex: -1,
            freeText: true,
            timestamp: Date.now(),
          });

          pendingQuestions.delete(questionId);
          console.log(`Answer resolved (free text): ${questionId} -> ${freeText}`);

          // Ghosttyをアクティブ化し、tmux paneを選択
          activateTerminal(paneId);

          // スレッドに回答を投稿
          if (messageTs) {
            await postToSlack(
              CHANNEL_ID,
              `✅ 回答（自由記述）: *${freeText}*`,
              null,
              messageTs
            );
          }

          // モーダルを閉じる
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ response_action: 'clear' }));
          return;
        }

        res.writeHead(200);
        res.end();
        return;
      }

      // 404
      res.writeHead(404);
      res.end('Not Found');
    } catch (err) {
      console.error('Error:', err);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: err.message }));
    }
  });
});

const PORT = process.env.PORT || 3847;

server.listen(PORT, () => {
  console.log(`🌐 HTTP server listening on port ${PORT}`);
  console.log(`📝 POST /ask - 質問送信（hookから）`);
  console.log(`📝 POST /slack/interactions - Slackボタンクリック受信`);
  console.log(`📝 GET /health - ヘルスチェック`);
});
