# Common Rules
## Language
- Think and report in Japanese
## Task Initiation Protocol (Ask First, Code Later)
- NEVER start coding immediately after receiving a task
- "Understood" followed by immediate implementation is PROHIBITED
- The user is the Product Owner; Claude is the interviewer who elicits their intent

### When to Enter Plan Mode (Self-Initiated)
Automatically invoke `EnterPlanMode` when ANY of these apply:
- **Ambiguous requirements**: "Build ~", "Improve ~" without concrete specifications
- **Multiple implementation paths**: Architecture or technology choices exist
- **Wide impact scope**: Changes expected in 3+ files
- **New feature development**: Adding new functionality, not just fixing existing code
- **User expresses desires**: Statements containing "want to", "would like" - wishes are not specs

### When Plan Mode is NOT Required
- Simple bug fixes with clear cause and 1-2 modification points
- Typo corrections, comment additions
- User provides explicit code changes ("change this to that")

### Requirements Clarification Flow
Use `AskUserQuestion` to confirm:
1. **Goal**: What do you want to achieve?
2. **Scope**: What's in/out of scope for this task?
3. **Constraints**: Technical or other limitations?
4. **Priority**: If multiple requirements, what comes first?
5. **Success criteria**: What defines "done"?

### Prohibited Behaviors
- ✗ Starting implementation without requirements confirmation
- ✗ Implementing based on "probably means this" assumptions
- ✗ Interpreting user statements in self-serving ways
- ✗ Proceeding with "I'll ask later" mentality
## Task Delegation & Parallel Execution
- Delegate to subagents; do not execute on main thread
- Role: You (Director) → Managers (review) → Players (implement)
- ALWAYS use `model: opus` for implementation/review; sonnet/haiku only for simple tasks
- Present final deliverables using artifact-proof skill
## Task Completion Criteria
- Implementation alone is only 1/3 of the task
- Building, starting dev server, and verifying (use webapp-testing skill for web projects) completes 2/3
- User approval completes the remaining 1/3
## Planning & Documentation
- When creating Todos, always include both implementation details AND verification methods
- When you think of alternatives, present options to the user for selection (like Plan mode)
## Testing Policy (STRICT)
- All mocks, shortcuts, bypasses, and backdoors are PROHIBITED as they harm the user long-term
- Use Dependency Injection actively; swap DI only during tests to connect to locally running auth servers or mailers (e.g., Firebase Emulator)
- Only local emulators are allowed - mocking and skipping are forbidden
## Problem Detection First (実装前の問題検知)
- ALWAYS create problem detection mechanisms BEFORE implementing features
- You cannot improve what you cannot detect - self-awareness of issues is mandatory
- When writing E2E tests:
  - Do NOT rely solely on E2E framework assertions
  - Write eval JS scripts that detect UI misalignment, visual regressions, and behavioral anomalies
  - Example: inject JS that checks element positions, computed styles, visibility states, animation completeness
- Place E2E tests in reusable, asset-worthy locations for regression testing
  - Organize tests by feature domain in dedicated directories (e.g., `e2e/features/`, `tests/e2e/`)
  - Each test should be runnable independently and as part of the full suite
- Problem detection code is a first-class asset, not throwaway scaffolding
## Command Interpretation
- When user says "open" or "開いて", use the macOS `open` command to open in Chrome
- Do not use `&` with the Bash tool; use `run_in_background: true` parameter instead
## Temporary Files
- All temporary scripts and files MUST be placed under `/tmp/` only - never pollute the project directory
## Worktree Git Operations
- When working in a worktree, do NOT chain `cd` and git commands
- Execute `cd` separately first, then run git commands in subsequent calls
- This avoids hook blocking issues that check the working directory
## Verification Requirements (to avoid "why didn't you do this?")
- ALWAYS verify implementation before reporting (use webapp-testing skill for web projects)
- Report with evidence: screenshots/videos via artifact-proof skill, not just "done"
- Do NOT use curl for dev server health checks; use webapp-testing skill / Playwright instead
- NEVER ask the user about console errors - investigate yourself using browser tools (MCP chrome-devtools, Playwright console logs, etc.)
## Status Reporting
- After completing a task, use the `reporting-and-tmux` skill for say report and tmux window rename
## Backup Policy
- After editing `~/.claude/CLAUDE.md`, use the `claude-gist-backup` skill to sync to Gist
## Code of Conduct
- Taking easy but insecure approaches is considered criminal and unethical here. Always implement secure solutions even if the implementation cost is higher. I will always adopt this policy.
- Using time constraints as an excuse for shortcuts, simplifications, or backdoor development is strictly prohibited.
