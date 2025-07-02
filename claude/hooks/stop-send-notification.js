#!/usr/bin/env node

const { execFileSync } = require("node:child_process");
const { readFileSync, appendFileSync } = require("node:fs");
const path = require("node:path");
const os = require("node:os");

try {
    const inputRaw = readFileSync(process.stdin.fd, 'utf8');
    const input = JSON.parse(inputRaw);
    
    // Debug log - write raw input to debug.log
    const debugPath = path.join(os.homedir(), 'debug.log');
    const timestamp = new Date().toISOString();
    // appendFileSync(debugPath, `\n[${timestamp}] stop-send-notification.js received:\n${inputRaw}\n`);
    
    if (!input.transcript_path) {
        // appendFileSync(debugPath, `[${timestamp}] No transcript_path, exiting\n`);
        process.exit(0);
    }

    const homeDir = os.homedir();
    let transcriptPath = input.transcript_path;

    if (transcriptPath.startsWith('~/')) {
        transcriptPath = path.join(homeDir, transcriptPath.slice(2));
    }

    const allowedBase = path.join(homeDir, '.claude', 'projects');
    const resolvedPath = path.resolve(transcriptPath);
    // appendFileSync(debugPath, `[${timestamp}] Resolved path: ${resolvedPath}\n`);

    if (!resolvedPath.startsWith(allowedBase)) {
        // appendFileSync(debugPath, `[${timestamp}] Path not allowed, exiting\n`);
        process.exit(1);
    }

    let lines;
    try {
        lines = readFileSync(resolvedPath, "utf-8").split("\n").filter(line => line.trim());
        // appendFileSync(debugPath, `[${timestamp}] Read ${lines.length} lines from transcript\n`);
    } catch (e) {
        // File not found or not readable
        // appendFileSync(debugPath, `[${timestamp}] Error reading file: ${e.message}\n`);
        process.exit(0);
    }
    
    if (lines.length === 0) {
        // appendFileSync(debugPath, `[${timestamp}] No lines in file, exiting\n`);
        process.exit(0);
    }

    const lastLine = lines[lines.length - 1];
    let transcript, lastMessageContent;
    try {
        transcript = JSON.parse(lastLine);
        lastMessageContent = transcript?.message?.content?.[0]?.text;
        // appendFileSync(debugPath, `[${timestamp}] Got message content: ${lastMessageContent ? 'YES' : 'NO'}\n`);
    } catch (e) {
        // appendFileSync(debugPath, `[${timestamp}] Error parsing JSON: ${e.message}\n`);
        process.exit(0);
    }

    if (lastMessageContent) {
        // Get tmux window and pane info
        let tmuxInfo = "";
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
            
            // Remove emoji prefix if present
            const cleanTitle = paneTitle.replace(/^[✳️✳]\s*/, '');
            
            // Format: Claude Code - [window-pane] process/title
            tmuxInfo = `Claude Code - [${windowIndex}-${paneIndex}] ${cleanTitle}`;
        } catch {
            // Not in tmux or tmux command failed, skip prefix
        }

        // Remove newlines and normalize whitespace
        const cleanedMessage = lastMessageContent
            .replace(/\n+/g, ' ')  // Replace newlines with space
            .replace(/\s+/g, ' ')  // Normalize multiple spaces
            .trim();
        
        // Truncate message to fit macOS notification limits (around 240 chars)
        const maxLength = 235;
        const truncatedMessage = cleanedMessage.length > maxLength 
            ? cleanedMessage.substring(0, maxLength - 3) + '...' 
            : cleanedMessage;
        
        // Create notification title - put Claude Code after tmux info
        const notificationTitle = tmuxInfo ? `${tmuxInfo.trim()}` : 'Claude Code';

        // Use AppleScript for notification
        const script = `display notification "${truncatedMessage.replace(/"/g, '\\"').replace(/\\/g, '\\\\')}" with title "${notificationTitle.replace(/"/g, '\\"')}" sound name "default"`;
        // appendFileSync(debugPath, `[${timestamp}] Sending notification with title: ${notificationTitle}\n`);
        // appendFileSync(debugPath, `[${timestamp}] Message: ${truncatedMessage}\n`);
        
        try {
            execFileSync('osascript', ['-e', script], {
                stdio: 'pipe'
            });
            // appendFileSync(debugPath, `[${timestamp}] Notification sent successfully\n`);
        } catch (e) {
            // appendFileSync(debugPath, `[${timestamp}] Notification error: ${e.message}\n`);
        }
    }
} catch (error) {
    // Silent exit on error - hooks should not output to stderr
    process.exit(0);
}