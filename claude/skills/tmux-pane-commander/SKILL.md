---
name: tmux-pane-commander
description: Send prompts to other AI CLIs (Codex, Claude Code) running in sibling tmux panes and receive results back. Use this skill when the user asks to send a question or task to Codex or another Claude Code instance in a tmux pane. Handles pane discovery, CLI startup if needed, prompt delivery with proper Enter timing, delivery verification, and result return via tmux send-keys.
allowed-tools: Bash, Read
---

# tmux Pane Commander

Orchestrate AI CLIs (Codex CLI, Claude Code) across tmux panes as a team.
The core loop: **Send task → Child works → Child reports back to parent pane.**

## Philosophy

You are the **parent (manager)**. Other AI CLIs in sibling panes are **children (workers)**.
This is a team: tasks go out, results come back. Both directions use tmux send-keys.

## Full Workflow (MANDATORY - follow every step)

### Step 0: Know your own pane ID

**Before anything else**, get YOUR pane ID. You will embed this in every prompt you send.

```bash
MY_PANE_ID=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_id}')
echo "My pane ID: $MY_PANE_ID"
```

This `$MY_PANE_ID` (e.g., `%85`) is how children will report back to you.

### Step 1: Discover panes in current window

```bash
WINDOW_INDEX=$(tmux display-message -p -t "$TMUX_PANE" '#I')
tmux list-panes -t "$WINDOW_INDEX" -F '#{pane_index} #{pane_id} #{pane_pid} #{pane_current_command} #{pane_tty}'
```

Identify target pane by process name:
- **Codex CLI**: `node` process with `codex` in the process tree
- **Claude Code**: `node` process with `claude` in the process tree

Verify with:
```bash
ps aux | grep -E 'codex|claude' | grep -v grep
```

Cross-reference PID and TTY to find the correct **pane ID** (e.g., `%87`).

### Step 2: Check pane state BEFORE sending

**IMPORTANT**: Capture enough lines to see the actual work area, not just the prompt and status bar.
AI CLIs (Claude Code, Codex) display status bars and input prompts at the bottom (~10-15 lines).
If you only capture 15-20 lines, you'll only see the chrome and miss the actual output area where
work status (e.g., "Compacting conversation...", "Working...", error messages) is displayed.

```bash
# Capture 50 lines to see both the work area AND the status bar
tmux capture-pane -t "${TARGET_PANE_ID}" -p | tail -50
```

Check what you see **in the output area above the prompt** (not just the prompt line):
- **Prompt ready** (`>` or `›`) AND no active status messages above: Can send text directly
- **Working/Processing** (e.g., "Working", "Thinking", "Compacting conversation..."): Wait and re-check
- **Not running**: Start the CLI first (see Step 2b)
- **Text already in prompt**: DO NOT resend text, skip to Step 4 (Enter only)

**Common misread**: An empty prompt `❯` does NOT always mean idle. Check for status messages
like "Compacting conversation..." or "auto-compact: 0%" in the lines ABOVE the prompt.
The status bar field `Context left until auto-compact: 0%` means compaction is imminent or active.

### Step 2b: Start CLI if not running (only if needed)

**Codex CLI:**
```bash
tmux send-keys -t "${TARGET_PANE_ID}" "codex --sandbox workspace-write --config sandbox_workspace_write.network_access=true --dangerously-bypass-approvals-and-sandbox" && sleep 0.5 && tmux send-keys -t "${TARGET_PANE_ID}" Enter
sleep 5
```

**Claude Code:**
```bash
tmux send-keys -t "${TARGET_PANE_ID}" "claude --dangerously-skip-permissions" && sleep 0.5 && tmux send-keys -t "${TARGET_PANE_ID}" Enter
sleep 5
```

Wait for the CLI to be ready (check with capture-pane) before proceeding.

### Step 3: Build the prompt WITH return instructions

**CRITICAL**: Every prompt MUST include:
1. The actual task/question
2. Your pane ID for reporting back
3. The reporting format instructions

**Prompt template:**

```
[TASK]
(Your actual task here)

[REPORT BACK]
作業完了後、以下のコマンドで親ペインに結果をワンライナーで報告してください:
tmux send-keys -t {MY_PANE_ID} '[{TARGET_PANE_ID}] 報告内容をここにワンライナーで' && sleep 0.1 && tmux send-keys -t {MY_PANE_ID} Enter

報告形式:
- 必ず [{TARGET_PANE_ID}] プレフィックスを付ける
- ワンライナーで要約（改行不可）
- 成功/失敗を明示
```

Replace `{MY_PANE_ID}` with your actual pane ID (e.g., `%85`) and `{TARGET_PANE_ID}` with the child's pane ID (e.g., `%87`).

### Step 4: Send the prompt text

```bash
tmux send-keys -t "${TARGET_PANE_ID}" "Your full prompt including report-back instructions"
```

**IMPORTANT**: Do NOT include `Enter` in this command. Text and Enter MUST be separate steps.

### Step 5: Sleep then send Enter

```bash
sleep 0.5
tmux send-keys -t "${TARGET_PANE_ID}" Enter
```

The sleep is MANDATORY. Without it, the Enter arrives before the text is fully rendered in the target CLI's input buffer, causing the prompt to not be submitted.

### Step 6: Verify delivery

Wait a few seconds, then capture enough lines to see the work area (not just the status bar):

```bash
sleep 3
tmux capture-pane -t "${TARGET_PANE_ID}" -p | tail -50
```

Look for **in the output area above the prompt**:
- **Success indicators**: "Working", "Thinking", spinner, tool calls, file reads
- **Failure indicators**: Text still sitting in the prompt without processing
- **Busy indicators**: "Compacting conversation...", high token usage warnings

If delivery failed, retry Step 5 only (Enter, NOT the text).

### Step 7: Wait for child's report

The child will send a report back to your pane via `tmux send-keys -t {MY_PANE_ID}`.
You can also proactively check their progress:

```bash
tmux capture-pane -t "${TARGET_PANE_ID}" -p -S -200 | tail -50
```

## Concrete Example

Parent pane `%85` sends task to Codex in pane `%87`:

```bash
# Step 0: My ID
MY_PANE_ID="%85"

# Step 3+4: Send prompt with return instructions
tmux send-keys -t "%87" "mimamori-expo-bff のマイグレーション整合性を調査してください。drizzle/ と migrations/ の2つのディレクトリの状態を確認し、問題があれば修正案を提示。完了後: tmux send-keys -t %85 '[%87] 調査完了: (結果要約)' && sleep 0.1 && tmux send-keys -t %85 Enter"

# Step 5: Enter
sleep 0.5
tmux send-keys -t "%87" Enter

# Step 6: Verify (50 lines to see work area, not just status bar)
sleep 3
tmux capture-pane -t "%87" -p | tail -50
```

## Token Management (Parent's Responsibility)

When a child's context is getting full, the parent can clear it:

```bash
tmux send-keys -t "${TARGET_PANE_ID}" "/clear" && sleep 0.5 && tmux send-keys -t "${TARGET_PANE_ID}" Enter
```

Timing:
- After task completion
- When child shows high token usage (e.g., "10% context left")
- When errors accumulate

## Retrieving Long Results

For when the child's report-back is insufficient and you need their full output:

```bash
# Last 100 lines
tmux capture-pane -t "${TARGET_PANE_ID}" -p -S -100

# Last 500 lines (for very long outputs)
tmux capture-pane -t "${TARGET_PANE_ID}" -p -S -500
```

## Token-Efficient Monitoring (サイコン方式)

**CRITICAL**: Direct tmux operations from the parent session are EXPENSIVE.
Every `capture-pane` output (50+ lines) gets added to your context permanently.
Repeated monitoring eats through your 200k context window fast.

### The Problem

```
❌ BAD: Parent directly runs capture-pane
   Parent context: +500 tokens per check × 5 checks = +2,500 tokens wasted
   Result: Context exhaustion, auto-compact triggered early
```

### The Solution: Delegate monitoring to disposable subagents

```
✅ GOOD: Parent spawns haiku subagent for monitoring
   Subagent: does all heavy capture-pane work internally (doesn't affect parent)
   Returns: 1-line summary (~30 tokens added to parent)
```

**Why this works**: Task tool subagents have their OWN context window.
Their internal tool calls (capture-pane, grep, etc.) do NOT consume parent context.
Only the final return message gets added to the parent's context.

### Quick Status Check (use Task tool with model: haiku)

When you need to check on children's progress, ALWAYS delegate to a haiku subagent:

```
Task(subagent_type=Bash, model=haiku):
  prompt: |
    Run this command and parse the output into a single-line status report.

    tmux capture-pane -t "%87" -p | tail -50

    Return ONLY one line in this exact format (no extra text):
    PANE:%87|STATUS:{idle/working/compacting/error}|CTX:{N%}|TASK:{10-word-max}|COST:{$N.NN}

    Parse rules:
    - STATUS: "idle" if prompt `❯`/`>` visible with no work above, "working" if spinner/tool calls,
      "compacting" if "Compacting conversation" visible, "error" if errors shown
    - CTX: extract from status bar "N% context left" or "🧠 ... (N%)"
    - TASK: last visible task description (from todo list or working message)
    - COST: from "💰 $X.XX session" in status bar
```

### Multi-Pane Dashboard (single subagent for all panes)

For checking ALL panes at once, use ONE subagent to check everything:

```
Task(subagent_type=Bash, model=haiku):
  prompt: |
    Check these tmux panes and return a dashboard. Run capture-pane for each.

    Panes: %85, %87, %102

    For each pane, run: tmux capture-pane -t "{PANE_ID}" -p | tail -50

    Return ONLY this format (one line per pane, no extra text):
    %85|idle|ctx:15%|EAS build done|$111.38
    %87|working|ctx:60%|migration check|$0.00
    %102|compacting|ctx:5%|doc update|$45.20
```

### Deep Investigation (when summary isn't enough)

If you need to investigate a specific issue (e.g., why a child is stuck):

```
Task(subagent_type=Bash, model=haiku):
  prompt: |
    Investigate pane %87. It appears stuck.

    1. Run: tmux capture-pane -t "%87" -p -S -200
    2. Look for: error messages, repeated failures, permission issues, stuck loops
    3. Return ONLY a 2-3 sentence diagnosis and recommended action.
       Do NOT include raw capture output.
```

### Rules for Parent Session

1. **NEVER run `capture-pane` directly** from the parent session for routine monitoring
2. **ALWAYS use Task(model: haiku)** for tmux state checks — haiku is cheapest
3. **Enforce strict return format** — subagent must return compressed summary only
4. **One subagent per monitoring round** — check all panes in a single Task call
5. **Direct capture-pane is OK ONLY for**: initial pane discovery (Step 1) and delivery verification (Step 6) — these are one-time operations, not repeated monitoring

### Token Budget Reference

| Operation | Context cost (parent) | Method |
|-----------|----------------------|--------|
| Direct capture-pane (50 lines) | ~500 tokens | ❌ Avoid for monitoring |
| Direct capture-pane (200 lines) | ~2,000 tokens | ❌ Never for monitoring |
| Task(haiku) status check | ~30-50 tokens | ✅ Use this |
| Task(haiku) multi-pane dashboard | ~50-100 tokens | ✅ Use this |
| Task(haiku) deep investigation | ~100-200 tokens | ✅ Use for debugging |

## Common Mistakes (NEVER do these)

| Mistake | Why it fails | Correct approach |
|---------|-------------|-----------------|
| `send-keys "text" Enter` in one call | Enter may arrive before text renders | Separate: send text, sleep 0.5, send Enter |
| Resending text when Enter failed | Creates duplicate prompt | Only resend Enter |
| Not checking pane state first | May send to wrong pane or busy CLI | Always capture-pane first |
| Hardcoding pane index from memory | Pane indices change between sessions | Always discover dynamically via list-panes |
| Not including MY_PANE_ID in prompt | Child cannot report back | Always embed return address |
| Not including report format in prompt | Child reports in unparseable format | Always specify format with pane prefix |
| Using pane index instead of pane ID | Index is window-local and fragile | Use pane ID (e.g., %85) which is globally unique |
| `tail -15` or `tail -20` for state check | Only captures status bar + prompt, misses work area | Use `tail -50` to see output area where actual status is shown |
| Assuming empty prompt `❯` means idle | CLI may be compacting, auto-compacting, or processing above the prompt | Always check the output area above the prompt for status messages |
| Running capture-pane directly for repeated monitoring | Each capture adds ~500 tokens to parent context permanently | Delegate to Task(haiku) subagent, receive 1-line summary only |
| Letting subagent return raw capture-pane output | Defeats the purpose of delegation — full output still enters parent context | Enforce strict return format in subagent prompt (1-line per pane) |
