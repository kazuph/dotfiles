#!/usr/bin/env node

/**
 * Claude Code Stop Hook - 通知 + tmux復帰
 *
 * 機能:
 * 1. 応答完了時にmacOS通知を送信
 * 2. 通知クリックでtmuxのwindow/paneに自動復帰
 * 3. ベルも鳴らしてtmuxの!フラグを立てる
 */

const { execFileSync, execSync } = require("node:child_process");
const { readFileSync, writeFileSync } = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const fs = require('node:fs');
const debugLog = (msg) => fs.appendFileSync('/tmp/claude-notify-debug.log', `[${new Date().toISOString()}] ${msg}\n`);

try {
    debugLog('Script started');
    const inputRaw = readFileSync(process.stdin.fd, 'utf8');
    debugLog(`Input: ${inputRaw.substring(0, 200)}`);
    const input = JSON.parse(inputRaw);

    // 無限ループ防止: stop hookが既に実行中なら終了
    if (input.stop_hook_active) {
        process.exit(0);
    }

    if (!input.transcript_path) {
        debugLog('No transcript_path, exiting');
        process.exit(0);
    }

    const homeDir = os.homedir();
    let transcriptPath = input.transcript_path;

    if (transcriptPath.startsWith('~/')) {
        transcriptPath = path.join(homeDir, transcriptPath.slice(2));
    }

    const allowedBase = path.join(homeDir, '.claude', 'projects');
    const resolvedPath = path.resolve(transcriptPath);
    debugLog(`resolvedPath: ${resolvedPath}`);

    if (!resolvedPath.startsWith(allowedBase)) {
        debugLog('Path not allowed, exiting');
        process.exit(1);
    }

    let lines;
    try {
        lines = readFileSync(resolvedPath, "utf-8").split("\n").filter(line => line.trim());
        debugLog(`Lines count: ${lines.length}`);
    } catch (e) {
        debugLog(`Read error: ${e.message}`);
        process.exit(0);
    }

    if (lines.length === 0) {
        debugLog('No lines, exiting');
        process.exit(0);
    }

    // 最後のアシスタントテキストメッセージを探す（逆順で検索）
    let lastMessageContent = null;
    for (let i = lines.length - 1; i >= 0; i--) {
        try {
            const entry = JSON.parse(lines[i]);
            // アシスタントのメッセージでテキストコンテンツを持つものを探す
            if (entry?.message?.role === 'assistant' && entry?.message?.content) {
                const textContent = entry.message.content.find(c => c.type === 'text');
                if (textContent?.text) {
                    lastMessageContent = textContent.text;
                    debugLog(`Found text at line ${i}: ${lastMessageContent.substring(0, 50)}`);
                    break;
                }
            }
        } catch (e) {
            // JSONパースエラーは無視して次の行へ
        }
    }

    if (!lastMessageContent) {
        debugLog('No lastMessageContent found, exiting');
        process.exit(0);
    }

    // ベルを鳴らす（tmuxの!フラグ用）
    try {
        execSync('printf "\\a" > /dev/tty 2>/dev/null || printf "\\a" >&2', { shell: true });
    } catch (e) {
        // ベル失敗は無視
    }

    // tmux情報を取得
    let sessionName = "", windowIndex = "", paneIndex = "", paneTitle = "", tmuxSocket = "";
    // TERM_PROGRAMが取得できない場合はGhosttyをデフォルトに（macOSでよく使われる）
    let terminalApp = process.env.TERM_PROGRAM || "Ghostty";

    // TMUXソケットパスを取得
    // 1. 環境変数から取得を試みる
    // 2. なければユーザーIDから推測（/private/tmp/tmux-UID/default）
    const tmuxEnv = process.env.TMUX || "";
    if (tmuxEnv) {
        tmuxSocket = tmuxEnv.split(',')[0];
    } else {
        // フォールバック: ユーザーIDから推測
        try {
            const uid = execFileSync('id', ['-u'], { encoding: 'utf8' }).trim();
            const guessedSocket = `/private/tmp/tmux-${uid}/default`;
            const fs = require('node:fs');
            if (fs.existsSync(guessedSocket)) {
                tmuxSocket = guessedSocket;
            }
        } catch (e) {
            // 推測失敗
        }
    }

    // TMUX_PANEを使って、Claude Codeが動いているpaneを正確に特定
    // （display-messageはアクティブpaneを返すので、ユーザーが別paneにいると間違った値になる）
    const tmuxPane = process.env.TMUX_PANE || "";

    try {
        if (tmuxPane && tmuxSocket) {
            // TMUX_PANEが利用可能な場合、-tオプションで特定のpaneの情報を取得
            const tmuxArgs = ['-S', tmuxSocket, 'display-message', '-t', tmuxPane, '-p'];
            sessionName = execFileSync('tmux', [...tmuxArgs, '#{session_name}'], {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'ignore']
            }).trim();
            windowIndex = execFileSync('tmux', [...tmuxArgs, '#{window_index}'], {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'ignore']
            }).trim();
            paneIndex = execFileSync('tmux', [...tmuxArgs, '#{pane_index}'], {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'ignore']
            }).trim();
            paneTitle = execFileSync('tmux', [...tmuxArgs, '#{pane_title}'], {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'ignore']
            }).trim();
        } else {
            // フォールバック: 従来の方法（アクティブpane）
            sessionName = execFileSync('tmux', ['display-message', '-p', '#{session_name}'], {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'ignore']
            }).trim();
            windowIndex = execFileSync('tmux', ['display-message', '-p', '#{window_index}'], {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'ignore']
            }).trim();
            paneIndex = execFileSync('tmux', ['display-message', '-p', '#{pane_index}'], {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'ignore']
            }).trim();
            paneTitle = execFileSync('tmux', ['display-message', '-p', '#{pane_title}'], {
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'ignore']
            }).trim();
        }
    } catch (e) {
        // tmux外で実行された場合
        debugLog(`tmux error: ${e.message}`);
        sessionName = "";
    }

    // 通知タイトル
    const cleanTitle = paneTitle.replace(/^[^\x00-\x7F]+\s*/, '').substring(0, 30);
    const notificationTitle = sessionName
        ? `Claude Code [${windowIndex}-${paneIndex}] ${cleanTitle}`.trim()
        : 'Claude Code';

    // メッセージを整形
    const cleanedMessage = lastMessageContent
        .replace(/\n+/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
    const truncatedMessage = cleanedMessage.length > 200
        ? cleanedMessage.substring(0, 197) + '...'
        : cleanedMessage;

    // terminal-notifierで通知を送信
    const notifierPath = '/opt/homebrew/bin/terminal-notifier';

    if (sessionName) {
        // tmux内の場合：クリックでwindow/paneに復帰
        // ターミナルアプリのマッピング
        const terminalAppMap = {
            'Apple_Terminal': 'Terminal',
            'iTerm.app': 'iTerm',
            'WezTerm': 'WezTerm',
            'kitty': 'kitty',
            'Alacritty': 'Alacritty',
            'Ghostty': 'Ghostty'
        };
        const appName = terminalAppMap[terminalApp] || terminalApp;

        // クリック時に実行するコマンド
        // 1. ターミナルをアクティブ化
        // 2. tmuxでwindow/paneを選択（ソケットパスを明示的に指定）
        const tmuxCmd = tmuxSocket
            ? `/opt/homebrew/bin/tmux -S "${tmuxSocket}"`
            : '/opt/homebrew/bin/tmux';
        const focusCommand = [
            `osascript -e 'tell application "${appName}" to activate'`,
            `${tmuxCmd} select-window -t "${sessionName}:${windowIndex}"`,
            `${tmuxCmd} select-pane -t "${sessionName}:${windowIndex}.${paneIndex}"`
        ].join(' && ');

        // デバッグ: 実行されるコマンドをログに出力
        const fs = require('node:fs');
        fs.appendFileSync('/tmp/claude-notify-debug.log',
            `[${new Date().toISOString()}]\n` +
            `tmuxSocket: ${tmuxSocket}\n` +
            `sessionName: ${sessionName}\n` +
            `windowIndex: ${windowIndex}\n` +
            `paneIndex: ${paneIndex}\n` +
            `terminalApp: ${terminalApp}\n` +
            `focusCommand: ${focusCommand}\n\n`
        );

        try {
            execFileSync(notifierPath, [
                '-title', notificationTitle,
                '-message', truncatedMessage,
                '-sound', 'default',
                '-execute', focusCommand
            ], { stdio: 'pipe' });
        } catch (e) {
            // フォールバック：AppleScriptで通知
            const script = `display notification "${truncatedMessage.replace(/"/g, '\\"')}" with title "${notificationTitle.replace(/"/g, '\\"')}" sound name "default"`;
            execFileSync('osascript', ['-e', script], { stdio: 'pipe' });
        }
    } else {
        // tmux外の場合：シンプルな通知
        try {
            execFileSync(notifierPath, [
                '-title', notificationTitle,
                '-message', truncatedMessage,
                '-sound', 'default'
            ], { stdio: 'pipe' });
        } catch (e) {
            const script = `display notification "${truncatedMessage.replace(/"/g, '\\"')}" with title "${notificationTitle.replace(/"/g, '\\"')}" sound name "default"`;
            execFileSync('osascript', ['-e', script], { stdio: 'pipe' });
        }
    }

} catch (error) {
    process.exit(0);
}
