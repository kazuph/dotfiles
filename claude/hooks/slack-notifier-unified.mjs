#!/usr/bin/env node

import { readFileSync, appendFileSync, existsSync, unlinkSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { execFileSync, spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { URL } from 'node:url';
import path from 'node:path';
import os from 'node:os';
import dotenv from 'dotenv';

// Load environment variables from multiple possible locations
const possibleEnvPaths = [
    path.join(path.dirname(new URL(import.meta.url).pathname), '.env'),
    path.join(os.homedir(), 'dotfiles', 'claude', 'hooks', 'slack-notifier', '.env'),
    path.join(os.homedir(), '.claude', 'hooks', 'slack-notifier', '.env')
];

for (const envPath of possibleEnvPaths) {
    if (existsSync(envPath)) {
        dotenv.config({ path: envPath });
        break;
    }
}

// Configuration
const SLACK_BOT_TOKEN = process.env.SLACK_BOT_TOKEN;
const SLACK_CHANNEL_ID = process.env.SLACK_CHANNEL_ID;
const WEBHOOK_PORT = process.env.WEBHOOK_PORT || 3000;
const WEBHOOK_PATH = process.env.WEBHOOK_PATH || '/slack/webhook';

if (!SLACK_BOT_TOKEN || !SLACK_CHANNEL_ID) {
    console.error('Missing required environment variables. Please check .env file.');
    process.exit(1);
}

// Response file management
const RESPONSE_DIR = path.join(os.homedir(), '.claude', 'slack-responses');
const RESPONSE_FILE = path.join(RESPONSE_DIR, 'latest-response.json');
const LOCK_FILE = path.join(RESPONSE_DIR, 'processing.lock');

// Global process management
process.setMaxListeners(0);
let cleanupFunctions = new Set();
let webhookServer = null;

// Atomic process lock implementation
function acquireProcessLock() {
    try {
        // Ensure directory exists
        execFileSync('mkdir', ['-p', RESPONSE_DIR], { stdio: 'ignore' });
        
        // Try to acquire lock atomically using file creation with O_CREAT|O_EXCL semantics
        // This is more atomic than check-then-create
        const lockData = {
            pid: process.pid,
            timestamp: Date.now(),
            command: process.argv.join(' ')
        };
        
        // Use temporary file + atomic rename for lock acquisition
        const tempLock = LOCK_FILE + '.tmp.' + process.pid;
        writeFileSync(tempLock, JSON.stringify(lockData));
        
        try {
            // This will fail if lock file already exists (atomic check)
            execFileSync('ln', [tempLock, LOCK_FILE], { stdio: 'ignore' });
            // Successfully acquired lock
            unlinkSync(tempLock);
            return true;
        } catch {
            // Lock already exists, check if stale
            unlinkSync(tempLock);
            
            if (existsSync(LOCK_FILE)) {
                try {
                    const existingLock = JSON.parse(readFileSync(LOCK_FILE, 'utf8'));
                    // Check if lock is stale (older than 3 minutes)
                    if (Date.now() - existingLock.timestamp > 180000) {
                        // Remove stale lock and try again
                        unlinkSync(LOCK_FILE);
                        return acquireProcessLock(); // Retry once
                    }
                } catch {
                    // Corrupted lock file, remove it
                    unlinkSync(LOCK_FILE);
                    return acquireProcessLock(); // Retry once
                }
            }
            return false;
        }
    } catch (error) {
        console.error('Failed to acquire process lock:', error.message);
        return false;
    }
}

function releaseProcessLock() {
    try {
        if (existsSync(LOCK_FILE)) {
            unlinkSync(LOCK_FILE);
        }
    } catch {
        // Ignore errors during cleanup
    }
}

// Global cleanup
function globalCleanup() {
    releaseProcessLock();
    if (webhookServer) {
        try {
            webhookServer.close();
        } catch {}
    }
    cleanupFunctions.forEach(cleanup => {
        try {
            cleanup();
        } catch {}
    });
}

process.on('exit', globalCleanup);
process.on('SIGINT', () => {
    globalCleanup();
    process.exit(0);
});
process.on('SIGTERM', () => {
    globalCleanup();
    process.exit(0);
});

// Slack API helper
async function callSlackAPI(method, data) {
    const response = await fetch(`https://slack.com/api/${method}`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${SLACK_BOT_TOKEN}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data),
        signal: AbortSignal.timeout(900000) // 15分タイムアウト
    });
    
    return response.json();
}

// Message analysis
function analyzeMessage(content) {
    const approvalPatterns = [
        /承認.*(してください|お願いします|してもらえ|していただけ)/i,
        /よろしい(でしょうか|ですか)/i,
        /(進めて|実行して)もよろしいでしょうか/i,
        /どちらを.*(希望|選択|お望み)/i,
        /選択肢|オプション|どれを選/i,
        /\b(A|B|C)\b.*選んで/i,
        /\b(1|2|3)\b.*どちら/i
    ];

    const hasApproval = approvalPatterns.some(pattern => pattern.test(content));
    
    return {
        needsInteraction: hasApproval,
        type: hasApproval ? 'approval_choice' : 'notification'
    };
}

// Slack blocks creation
function createInteractiveBlocks(content) {
    return [
        {
            type: 'section',
            text: {
                type: 'mrkdwn',
                text: `🤖 *Claude Code からの通知*\n\n${content}`
            }
        },
        {
            type: 'divider'
        },
        {
            type: 'actions',
            elements: [
                {
                    type: 'button',
                    text: {
                        type: 'plain_text',
                        text: '✅ 承認・実行'
                    },
                    value: 'approve',
                    action_id: 'claude_approve',
                    style: 'primary'
                },
                {
                    type: 'button',
                    text: {
                        type: 'plain_text',
                        text: '❌ キャンセル'
                    },
                    value: 'reject',
                    action_id: 'claude_reject',
                    style: 'danger'
                },
                {
                    type: 'button',
                    text: {
                        type: 'plain_text',
                        text: '💬 カスタム返答'
                    },
                    value: 'custom',
                    action_id: 'claude_custom'
                }
            ]
        }
    ];
}

// Context information
function getTmuxInfo() {
    try {
        const windowIndex = execFileSync('tmux', ['display-message', '-p', '#{window_index}'], {
            encoding: 'utf8',
            stdio: ['pipe', 'pipe', 'ignore']
        }).trim();
        
        const paneIndex = execFileSync('tmux', ['display-message', '-p', '#{pane_index}'], {
            encoding: 'utf8',
            stdio: ['pipe', 'pipe', 'ignore']
        }).trim();
        
        const paneTitle = execFileSync('tmux', ['display-message', '-p', '#{pane_title}'], {
            encoding: 'utf8',
            stdio: ['pipe', 'pipe', 'ignore']
        }).trim();
        
        const cleanTitle = paneTitle.replace(/^[✳️✳]\s*/, '');
        return `[${windowIndex}-${paneIndex}] ${cleanTitle}`;
    } catch {
        return null;
    }
}

// Response file management
function saveUserResponse(responseData) {
    try {
        execFileSync('mkdir', ['-p', RESPONSE_DIR], { stdio: 'ignore' });
        
        const response = {
            timestamp: new Date().toISOString(),
            action: responseData.action,
            text: responseData.text || '',
            user_id: responseData.user_id,
            channel_id: responseData.channel_id
        };
        
        // Atomic write using temp file + rename
        const tempFile = RESPONSE_FILE + '.tmp';
        writeFileSync(tempFile, JSON.stringify(response, null, 2));
        execFileSync('mv', [tempFile, RESPONSE_FILE]);
        
        console.log('✅ Saved user response:', response);
        return true;
    } catch (error) {
        console.error('❌ Failed to save user response:', error.message);
        return false;
    }
}

// Response waiting with improved polling
async function waitForUserResponse(timeout = 900000) {
    console.log('⏳ Waiting for user response...');
    
    return new Promise((resolve) => {
        const startTime = Date.now();
        let intervalId;
        
        const cleanup = () => {
            if (intervalId) clearInterval(intervalId);
            cleanupFunctions.delete(cleanup);
        };
        
        cleanupFunctions.add(cleanup);
        
        const checkForResponse = () => {
            if (Date.now() - startTime >= timeout) {
                cleanup();
                console.log('⏰ Timeout waiting for user response');
                resolve(null);
                return;
            }
            
            if (existsSync(RESPONSE_FILE)) {
                try {
                    const responseData = JSON.parse(readFileSync(RESPONSE_FILE, 'utf8'));
                    console.log('✅ User response received:', responseData);
                    
                    cleanup();
                    
                    try {
                        unlinkSync(RESPONSE_FILE);
                    } catch {}
                    
                    resolve(responseData);
                } catch (error) {
                    console.error('❌ Failed to parse response file:', error.message);
                }
            }
        };
        
        intervalId = setInterval(checkForResponse, 1000);
        checkForResponse(); // Initial check
    });
}

// Webhook server implementation
function createWebhookServer() {
    const server = createServer(async (req, res) => {
        // CORS headers
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        
        if (req.method === 'OPTIONS') {
            res.writeHead(200);
            res.end();
            return;
        }
        
        const url = new URL(req.url, `http://localhost:${WEBHOOK_PORT}`);
        
        // Health check endpoint
        if (url.pathname === '/health') {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                status: 'ok',
                timestamp: new Date().toISOString(),
                service: 'claude-slack-webhook-unified'
            }));
            return;
        }
        
        // Webhook endpoint
        if (url.pathname === WEBHOOK_PATH && req.method === 'POST') {
            let body = '';
            req.on('data', chunk => {
                body += chunk.toString();
            });
            
            req.on('end', async () => {
                try {
                    // Handle URL verification challenge
                    if (body.startsWith('challenge=')) {
                        const challenge = new URLSearchParams(body).get('challenge');
                        res.writeHead(200, { 'Content-Type': 'text/plain' });
                        res.end(challenge);
                        return;
                    }
                    
                    // Parse payload
                    let payload;
                    if (body.startsWith('payload=')) {
                        const params = new URLSearchParams(body);
                        payload = JSON.parse(params.get('payload'));
                    } else {
                        payload = JSON.parse(body);
                    }
                    
                    let responseData = { ok: true };
                    
                    // Handle different interaction types
                    if (payload.type === 'block_actions') {
                        const action = payload.actions[0];
                        const userResponse = {
                            action: action.value,
                            user_id: payload.user.id,
                            channel_id: payload.channel.id
                        };
                        
                        if (action.value === 'custom') {
                            // Show modal for custom input
                            try {
                                await callSlackAPI('views.open', {
                                    trigger_id: payload.trigger_id,
                                    view: {
                                        type: 'modal',
                                        callback_id: 'custom_response_modal',
                                        private_metadata: payload.channel.id,
                                        title: {
                                            type: 'plain_text',
                                            text: 'カスタム返答'
                                        },
                                        submit: {
                                            type: 'plain_text',
                                            text: '送信'
                                        },
                                        close: {
                                            type: 'plain_text',
                                            text: 'キャンセル'
                                        },
                                        blocks: [
                                            {
                                                type: 'section',
                                                text: {
                                                    type: 'mrkdwn',
                                                    text: 'Claude Codeへの返答を入力してください：'
                                                }
                                            },
                                            {
                                                type: 'input',
                                                block_id: 'custom_response_block',
                                                element: {
                                                    type: 'plain_text_input',
                                                    action_id: 'custom_response_input',
                                                    multiline: true,
                                                    placeholder: {
                                                        type: 'plain_text',
                                                        text: 'ここに返答を入力...'
                                                    }
                                                },
                                                label: {
                                                    type: 'plain_text',
                                                    text: '返答内容'
                                                }
                                            }
                                        ]
                                    }
                                });
                            } catch (error) {
                                console.error('Failed to open modal:', error);
                                responseData = { text: 'エラーが発生しました。' };
                            }
                        } else {
                            saveUserResponse(userResponse);
                            responseData = {
                                text: action.value === 'approve' ? 
                                    '✅ 承認されました。Claude Codeが処理を続行します。' :
                                    '❌ キャンセルされました。Claude Codeに伝えました。',
                                replace_original: false,
                                response_type: 'ephemeral'
                            };
                        }
                    } else if (payload.type === 'view_submission') {
                        // Handle modal submission
                        const values = payload.view.state.values;
                        const customText = values.custom_response_block?.custom_response_input?.value || '';
                        
                        saveUserResponse({
                            action: 'custom',
                            text: customText,
                            user_id: payload.user.id,
                            channel_id: payload.view.private_metadata
                        });
                        
                        responseData = { response_action: 'clear' };
                    }
                    
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify(responseData));
                    
                    // Auto-shutdown after response received
                    if (payload.type === 'block_actions' && payload.actions[0].value !== 'custom') {
                        setTimeout(() => {
                            console.log('🔄 Response received, shutting down webhook server...');
                            globalCleanup();
                            process.exit(0);
                        }, 1000);
                    }
                    
                } catch (error) {
                    console.error('Webhook error:', error);
                    res.writeHead(500, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'Internal server error' }));
                }
            });
            return;
        }
        
        // 404 for other paths
        res.writeHead(404);
        res.end('Not Found');
    });
    
    return server;
}

// Start webhook server
async function startWebhookServer() {
    if (webhookServer) {
        return true; // Already running
    }
    
    try {
        // Check if port is already in use
        try {
            const response = await fetch(`http://localhost:${WEBHOOK_PORT}/health`, { signal: AbortSignal.timeout(3000) });
            if (response.ok) {
                console.log('✅ Webhook server already running');
                return true;
            }
        } catch {
            // Port is free, start server
        }
        
        webhookServer = createWebhookServer();
        
        return new Promise((resolve) => {
            webhookServer.listen(WEBHOOK_PORT, () => {
                console.log(`✅ Webhook server started on port ${WEBHOOK_PORT}`);
                resolve(true);
            });
            
            webhookServer.on('error', (error) => {
                console.error('❌ Failed to start webhook server:', error.message);
                resolve(false);
            });
        });
    } catch (error) {
        console.error('❌ Error starting webhook server:', error.message);
        return false;
    }
}

// Find latest transcript
function findLatestTranscript(projectsDir) {
    if (!existsSync(projectsDir)) {
        return null;
    }
    
    const files = [];
    
    function scanDirectory(dir) {
        try {
            const entries = readdirSync(dir);
            for (const entry of entries) {
                const fullPath = path.join(dir, entry);
                const stat = statSync(fullPath);
                
                if (stat.isDirectory()) {
                    scanDirectory(fullPath);
                } else if (entry.endsWith('.jsonl')) {
                    files.push({
                        name: entry,
                        path: fullPath,
                        mtime: stat.mtime
                    });
                }
            }
        } catch {
            // Skip unreadable directories
        }
    }
    
    scanDirectory(projectsDir);
    files.sort((a, b) => b.mtime - a.mtime);
    
    return files.length > 0 ? files[0].path : null;
}

// Main transcript processing
async function processTranscript(input) {
    const homeDir = os.homedir();
    let transcriptPath = input.transcript_path;

    if (transcriptPath.startsWith('~/')) {
        transcriptPath = path.join(homeDir, transcriptPath.slice(2));
    }

    const allowedBase = path.join(homeDir, '.claude', 'projects');
    const resolvedPath = path.resolve(transcriptPath);

    if (!resolvedPath.startsWith(allowedBase)) {
        process.exit(1);
    }

    let lines;
    try {
        lines = readFileSync(resolvedPath, "utf-8").split("\n").filter(line => line.trim());
    } catch (e) {
        process.exit(0);
    }
    
    if (lines.length === 0) {
        process.exit(0);
    }

    // Find most recent message with text content
    let lastMessageContent = null;
    
    for (let i = lines.length - 1; i >= 0; i--) {
        try {
            const lineData = JSON.parse(lines[i]);
            
            if (lineData?.message?.role !== 'assistant') {
                continue;
            }
            
            const content = lineData?.message?.content;
            if (content && Array.isArray(content)) {
                for (const item of content) {
                    if (item.type === 'text' && item.text && item.text.trim()) {
                        lastMessageContent = item.text;
                        break;
                    }
                }
            }
            
            if (lastMessageContent) {
                break;
            }
        } catch (e) {
            continue;
        }
    }

    const defaultMessage = lastMessageContent || "Claude Code からの通知";
    // Force interactive mode per user requirement
    const analysis = { needsInteraction: true, type: 'approval_choice' };
    
    const tmuxInfo = getTmuxInfo();
    const cleanedMessage = defaultMessage
        .replace(/\n{3,}/g, '\n\n')  // 3つ以上の連続改行を2つに制限
        .replace(/[ \t]+/g, ' ')     // タブとスペースを正規化（改行は保持）
        .trim();

    try {
        // Start webhook server
        await startWebhookServer();
        
        // Send Slack notification
        const blocks = createInteractiveBlocks(cleanedMessage);
        
        await callSlackAPI('chat.postMessage', {
            channel: SLACK_CHANNEL_ID,
            text: `Claude Code からの通知${tmuxInfo ? ` - ${tmuxInfo}` : ''}`,
            blocks: blocks
        });
        
        // Wait for user response
        const userResponse = await waitForUserResponse();
        
        if (userResponse) {
            console.log(`📝 Final response: ${userResponse.action} - ${userResponse.text || '(button response)'}`);
            
            // Log response
            const responseLogFile = path.join(os.homedir(), 'slack-user-response.log');
            const timestamp = new Date().toISOString();
            appendFileSync(responseLogFile, `[${timestamp}] ${userResponse.action}: ${userResponse.text || '(button response)'}\n`);
            
            // Send response to Claude via stderr (exit code 2)
            if (userResponse.action === 'approve') {
                console.error('✅ ユーザーが承認しました。処理を続行してください。');
                process.exit(2);
            } else if (userResponse.action === 'reject') {
                console.error('❌ ユーザーがキャンセルしました。処理を中止してください。');
                process.exit(2);
            } else if (userResponse.action === 'custom') {
                const customMessage = userResponse.text || 'カスタム返答が提供されました';
                console.error(`💬 ユーザーからのカスタム返答: ${customMessage}`);
                process.exit(2);
            }
        } else {
            console.log('⚠️ No user response received within timeout');
            console.error('⏰ ユーザー応答のタイムアウト。処理を中止します。');
            process.exit(2);
        }
        
    } catch (error) {
        console.error('Error sending Slack notification:', error.message);
        
        const errorLogFile = path.join(os.homedir(), 'slack-notifier-error.log');
        const timestamp = new Date().toISOString();
        appendFileSync(errorLogFile, `[${timestamp}] Error: ${error.message}\n`);
        
        process.exit(1);
    }
}

// Main execution
async function main() {
    // Acquire process lock to prevent duplicates
    if (!acquireProcessLock()) {
        console.log('⚠️ Another process is already handling this request');
        process.exit(0);
    }
    
    try {
        let inputRaw;
        let retryCount = 0;
        const maxRetries = 5;
        
        // Retry reading stdin on EAGAIN errors
        while (retryCount <= maxRetries) {
            try {
                inputRaw = readFileSync(process.stdin.fd, 'utf8');
                break;
            } catch (readError) {
                if (readError.code === 'EAGAIN' && retryCount < maxRetries) {
                    retryCount++;
                    const delay = 10 * Math.pow(2, retryCount - 1);
                    await new Promise(resolve => setTimeout(resolve, delay));
                } else {
                    throw readError;
                }
            }
        }
        
        // Debug logging
        const debugLog = path.join(os.homedir(), 'hook-input-debug.log');
        const timestamp = new Date().toISOString();
        appendFileSync(debugLog, `[${timestamp}] Unified hook - PID:${process.pid} - Input: ${inputRaw?.length || 0} chars\n`);
        
        if (!inputRaw || inputRaw.trim() === '') {
            // Find latest transcript manually for stop hooks
            const projectsDir = path.join(os.homedir(), '.claude', 'projects');
            const transcriptPath = findLatestTranscript(projectsDir);
            
            if (transcriptPath) {
                appendFileSync(debugLog, `[${timestamp}] Found transcript: ${transcriptPath}\n`);
                const input = { transcript_path: transcriptPath };
                await processTranscript(input);
                return;
            }
            
            process.exit(0);
        }
        
        const input = JSON.parse(inputRaw);
        await processTranscript(input);
        
    } catch (error) {
        const logFile = path.join(os.homedir(), 'slack-notifier-error.log');
        const timestamp = new Date().toISOString();
        try {
            appendFileSync(logFile, `[${timestamp}] Unified Error: ${error.message}\n${error.stack}\n\n`);
        } catch {}
        process.exit(0);
    }
}

main();