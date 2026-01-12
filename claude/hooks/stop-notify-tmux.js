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

try {
    const inputRaw = readFileSync(process.stdin.fd, 'utf8');
    const input = JSON.parse(inputRaw);

    // 無限ループ防止: stop hookが既に実行中なら終了
    if (input.stop_hook_active) {
        process.exit(0);
    }

    if (!input.transcript_path) {
        process.exit(0);
    }

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

    const lastLine = lines[lines.length - 1];
    let transcript, lastMessageContent;
    try {
        transcript = JSON.parse(lastLine);
        lastMessageContent = transcript?.message?.content?.[0]?.text;
    } catch (e) {
        process.exit(0);
    }

    if (!lastMessageContent) {
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
    let terminalApp = process.env.TERM_PROGRAM || "Terminal";

    // TMUXソケットパスを環境変数から取得（例: /private/tmp/tmux-501/default,12345,0）
    const tmuxEnv = process.env.TMUX || "";
    if (tmuxEnv) {
        tmuxSocket = tmuxEnv.split(',')[0];
    }

    try {
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
    } catch (e) {
        // tmux外で実行された場合
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
