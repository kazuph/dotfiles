/**
 * agent-os-pi — V8アイソレート内コーディングエージェント（ストリーミング対応）
 *
 * ホスト側でネイティブ https を使い Fireworks API を SSE ストリーミング呼び出し。
 * ツール実行のみ V8 サンドボックスに委譲。トークンはリアルタイムで表示。
 *
 * Usage:
 *   node agent-os-pi.mjs --cwd <dir> --message "prompt"   # ワンショット
 *   node agent-os-pi.mjs --cwd <dir>                       # REPL
 */
import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { createRequire } from 'node:module';
import { execSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import https from 'node:https';

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

// --- Patch node-stdlib-browser ---
const stdlibPath = dirname(require.resolve('node-stdlib-browser/package.json'));
for (const d of ['mock', 'proxy']) mkdirSync(join(stdlibPath, d), { recursive: true });
if (!existsSync(join(stdlibPath, 'mock/empty.js')))
  writeFileSync(join(stdlibPath, 'mock/empty.js'), 'module.exports = {};');
const PROXY_MODULES = [
  'process','buffer','console','constants','domain','events',
  'http','https','os','path','querystring','stream',
  'string_decoder','sys','timers','tty','url','util','vm',
  'zlib','punycode','assert','crypto',
  'fs','child_process',
];
for (const m of PROXY_MODULES) {
  const p = join(stdlibPath, 'proxy', m + '.js');
  if (!existsSync(p)) writeFileSync(p, `module.exports = require('${m}');`);
}

// --- Args ---
const { values: args, positionals } = parseArgs({
  options: {
    cwd: { type: 'string', default: process.cwd() },
    message: { type: 'string', short: 'm' },
    model: { type: 'string', default: 'accounts/fireworks/models/kimi-k2p5' },
    'api-key-file': { type: 'string' },
    help: { type: 'boolean', short: 'h' },
  },
  allowPositionals: true,
});

if (args.help) {
  console.log(`agent-os-pi — Coding agent in V8 isolate (streaming)

Usage:
  agent-os-pi [workspace-dir] [options]

Options:
  --cwd <dir>           Workspace directory (default: cwd)
  --message, -m <text>  One-shot prompt (skip REPL)
  --model <id>          Model ID (default: accounts/fireworks/models/kimi-k2p5)
  --api-key-file <path> Path to Fireworks API key file
  --help, -h            Show this help`);
  process.exit(0);
}

const workspaceDir = resolve(positionals[0] || args.cwd);

// --- API Key ---
function getApiKey() {
  if (args['api-key-file'] && existsSync(args['api-key-file']))
    return readFileSync(args['api-key-file'], 'utf-8').trim();
  if (process.env.FIREWORKS_API_KEY)
    return process.env.FIREWORKS_API_KEY;
  try {
    const key = execSync(
      'eval "$(direnv export bash 2>/dev/null)" && echo $FIREWORKS_API_KEY',
      { shell: '/bin/bash', encoding: 'utf-8', timeout: 5000 }
    ).trim();
    if (key) return key;
  } catch {}
  const cached = '/tmp/.agent-os-fireworks-key';
  if (existsSync(cached)) return readFileSync(cached, 'utf-8').trim();
  console.error('Error: FIREWORKS_API_KEY not found. Set via env, direnv, or --api-key-file');
  process.exit(1);
}

const apiKey = getApiKey();

// --- Read VM tool executor code ---
const toolExecutorCode = readFileSync(join(__dirname, 'vm-coding-agent.js'), 'utf-8');

// --- Agent OS VM Setup ---
const { AgentOs, createHostDirBackend } = await import('@rivet-dev/agent-os-core');
const common = (await import('@rivet-dev/agent-os-common')).default;

console.error(`🚀 Creating V8 isolate...`);
const os = await AgentOs.create({
  software: [common],
  mounts: [
    { path: '/workspace', driver: createHostDirBackend({ hostPath: workspaceDir, readOnly: false }) },
  ],
});
console.error(`✅ V8 isolate ready (workspace: ${workspaceDir})`);

// --- System prompt ---
const SYSTEM_PROMPT = [
  'You are Pi, a coding agent running in a sandboxed V8 isolate.',
  'Your workspace is at /workspace.',
  '',
  '## IMPORTANT: When to use tools',
  '- ONLY use tools when the user explicitly asks you to do something that requires them',
  '- For greetings, questions, explanations, or conversation: just respond with text. NO tools.',
  '- Do NOT proactively explore, list files, or read files unless the user asked for it',
  '- Do NOT verify or double-check your work with extra tool calls unless asked',
  '- Minimize tool calls. Do exactly what was requested, nothing more.',
  '',
  '## Available Tools',
  'To use a tool, output EXACTLY this format (one per line):',
  '<tool_call>{"name":"tool_name","arguments":{"arg":"value"}}</tool_call>',
  '',
  'Tools:',
  '- read_file: Read a file. Args: {"path": "relative/or/absolute/path"}',
  '- write_file: Create/overwrite a file. Args: {"path": "file.js", "content": "full content"}',
  '- list_directory: List directory contents. Args: {"path": "."} (default: workspace root)',
  '- execute_command: Run node or shell built-ins. Args: {"command": "node script.js"} (relative paths auto-resolve to /workspace/)',
  '- search_text: Search text in files. Args: {"pattern": "TODO", "path": "."}',
  '',
  '## Rules',
  '- Always respond in the same language the user used. If asked in Japanese, reply in Japanese.',
  '- Be concise. Do what was asked, report the result, stop.',
  '- For write_file, always include the COMPLETE file content',
  '- All paths are relative to /workspace',
].join('\n');

// --- Parse tool calls from model text ---
function parseToolCalls(text) {
  const calls = [];
  let match;

  // Pattern 1: <tool_call>{"name":"...","arguments":{...}}</tool_call>
  const regex = /<tool_call>\s*(\{[\s\S]*?\})\s*<\/tool_call>/g;
  while ((match = regex.exec(text)) !== null) {
    try {
      const parsed = JSON.parse(match[1]);
      if (parsed.name) calls.push({ name: parsed.name, arguments: parsed.arguments || {} });
    } catch {}
  }
  if (calls.length > 0) return calls;

  // Pattern 2: {"type":"function","name":"...","parameters":{...}}
  const p2 = /\{\s*"type"\s*:\s*"function"\s*,\s*"name"\s*:\s*"([^"]+)"\s*,\s*"parameters"\s*:\s*(\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\})\s*\}/g;
  while ((match = p2.exec(text)) !== null) {
    try {
      calls.push({ name: match[1], arguments: JSON.parse(match[2]) });
    } catch {}
  }
  if (calls.length > 0) return calls;

  // Pattern 3: {"name":"...","arguments":{...}}
  const p3 = /\{\s*"name"\s*:\s*"([^"]+)"\s*,\s*"arguments"\s*:\s*(\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\})\s*\}/g;
  while ((match = p3.exec(text)) !== null) {
    try {
      calls.push({ name: match[1], arguments: JSON.parse(match[2]) });
    } catch {}
  }

  return calls;
}

// --- Fireworks API call with native https SSE streaming ---
function callAPI(msgs, onToken) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      model: args.model,
      messages: msgs,
      max_tokens: 16384,
      stream: true,
    });

    const req = https.request({
      hostname: 'api.fireworks.ai',
      path: '/inference/v1/chat/completions',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
        'Content-Length': Buffer.byteLength(body),
      },
    }, (res) => {
      if (res.statusCode !== 200) {
        let errBody = '';
        res.on('data', (c) => { errBody += c; });
        res.on('end', () => {
          reject(new Error(`API HTTP ${res.statusCode}: ${errBody.substring(0, 500)}`));
        });
        return;
      }

      let buf = '';
      const contentParts = [];

      res.on('data', (chunk) => {
        buf += chunk.toString();
        const lines = buf.split('\n');
        buf = lines.pop();

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed.startsWith('data: ')) continue;
          const data = trimmed.substring(6);
          if (data === '[DONE]') continue;

          try {
            const parsed = JSON.parse(data);
            const choice = parsed.choices?.[0];
            if (!choice?.delta) continue;

            if (choice.delta.content) {
              onToken(choice.delta.content);
              contentParts.push(choice.delta.content);
            }
          } catch {}
        }
      });

      res.on('end', () => resolve(contentParts.join('')));
      res.on('error', reject);
    });

    req.on('error', reject);
    req.setTimeout(120000, () => { req.destroy(); reject(new Error('Request timeout (120s)')); });
    req.write(body);
    req.end();
  });
}

// --- Execute tools in VM sandbox ---
const decoder = new TextDecoder();

async function executeToolsInVM(toolCalls) {
  const config = { tools: toolCalls };
  const configLine = 'var __CONFIG__ = JSON.parse(' +
    JSON.stringify(JSON.stringify(config)) + ');\n';
  const fullCode = configLine + toolExecutorCode;

  return new Promise((resolve, reject) => {
    let stdoutBuf = '';
    const { pid } = os.spawn("node", ["-e", fullCode]);

    os.onProcessStdout(pid, (data) => {
      stdoutBuf += decoder.decode(data);
    });

    os.onProcessStderr(pid, (data) => {
      // Tool executor debug output (if any)
      process.stdout.write(decoder.decode(data));
    });

    os.waitProcess(pid).then((exitCode) => {
      try {
        const trimmed = stdoutBuf.trim();
        if (!trimmed) {
          reject(new Error(`Tool executor produced no output (exit=${exitCode})`));
          return;
        }
        const response = JSON.parse(trimmed);
        resolve(response.results || []);
      } catch (e) {
        reject(new Error(`Failed to parse tool results (exit=${exitCode}): ${e.message}\nRaw: ${stdoutBuf.substring(0, 500)}`));
      }
    }).catch(reject);
  });
}

// --- Agent turn: API call → stream → tools → loop ---
async function runAgentTurn(conversationMessages) {
  const msgs = [{ role: 'system', content: SYSTEM_PROMPT }, ...conversationMessages];
  const MAX_TURNS = 30;

  for (let turn = 0; turn < MAX_TURNS; turn++) {
    let responseText;
    try {
      responseText = await callAPI(msgs, (token) => {
        // Stream tokens to stdout (readline uses stderr, so no conflict)
        process.stdout.write(token);
      });
    } catch (e) {
      process.stdout.write(`\n❌ API Error: ${e.message}\n`);
      break;
    }

    const toolCalls = parseToolCalls(responseText);
    msgs.push({ role: 'assistant', content: responseText });

    // No tool calls → done
    if (toolCalls.length === 0) {
      process.stdout.write('\n');
      break;
    }

    // Execute tools in VM sandbox
    process.stdout.write('\n');
    for (const tc of toolCalls) {
      let argsPreview = JSON.stringify(tc.arguments);
      if (argsPreview.length > 120) argsPreview = argsPreview.substring(0, 120) + '...';
      process.stdout.write(`🔧 ${tc.name}(${argsPreview})\n`);
    }

    let toolResults;
    try {
      toolResults = await executeToolsInVM(toolCalls);
    } catch (e) {
      process.stdout.write(`❌ Tool execution error: ${e.message}\n`);
      break;
    }

    // Display results
    for (const r of toolResults) {
      let preview = r.result.substring(0, 300).replace(/\n/g, '↵');
      if (r.result.length > 300) preview += '...';
      process.stdout.write(`   → ${preview}\n`);
    }

    // Truncate large results for the conversation
    const toolResultText = toolResults.map((r) => {
      let result = r.result;
      if (result.length > 20000) {
        result = result.substring(0, 20000) + '\n...(truncated, ' + result.length + ' bytes total)';
      }
      return `[${r.name}] ${result}`;
    }).join('\n\n');

    msgs.push({ role: 'user', content: `Tool results:\n${toolResultText}` });
    process.stdout.write('\n');
  }

  // Return conversation without system prompt
  return { messages: msgs.slice(1) };
}

// --- One-shot or REPL ---
if (args.message) {
  const messages = [{ role: 'user', content: args.message }];
  try {
    await runAgentTurn(messages);
  } catch (e) {
    console.error(`\n❌ ${e.message}`);
  }
  await os.dispose();
} else {
  // REPL mode
  let conversationMessages = [];
  const readline = await import('node:readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stderr,
    prompt: '\n🥧 pi> ',
  });

  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error('  Coding Agent in V8 Isolate (Streaming)');
  console.error(`  Model: ${args.model}`);
  console.error(`  Workspace: ${workspaceDir}`);
  console.error('  API: Fireworks (native https SSE)');
  console.error('  /quit to exit, /clear to reset');
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  rl.prompt();
  rl.on('line', async (line) => {
    const input = line.trim();
    if (!input) { rl.prompt(); return; }

    if (input === '/quit' || input === '/exit') {
      console.error('\n👋 Bye!');
      await os.dispose();
      process.exit(0);
    }
    if (input === '/clear') {
      conversationMessages = [];
      console.error('🧹 Conversation cleared');
      rl.prompt();
      return;
    }

    conversationMessages.push({ role: 'user', content: input });
    console.error('');

    try {
      const response = await runAgentTurn(conversationMessages);
      conversationMessages = response.messages;
    } catch (e) {
      console.error(`\n❌ ${e.message}`);
      conversationMessages.pop();
    }

    rl.prompt();
  });

  rl.on('close', async () => {
    console.error('\n👋 Bye!');
    await os.dispose();
    process.exit(0);
  });
}
