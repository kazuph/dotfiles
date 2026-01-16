#!/usr/bin/env bash
# claude_status_segment.sh - Show Claude Code status in tmux status bar
# Displays active Claude sessions or a subtle indicator

# Check if Claude Code is running
claude_panes=$(tmux list-panes -a -F '#{pane_current_command}' 2>/dev/null | grep -c -E '^(claude|node)$')
claude_panes=${claude_panes:-0}

if [[ "$claude_panes" -gt 0 ]]; then
    echo "#[fg=#b8f171,bold] Claude[$claude_panes]#[default]"
fi
