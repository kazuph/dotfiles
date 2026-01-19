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

When creating Todos, always include both implementation details AND verification methods.
When you think of alternatives, present options to the user for selection.

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

## Implementation Feedback Loop (MANDATORY)

**NEVER say "Implementation complete" without running this loop.**

```mermaid
flowchart TD
    subgraph MAIN["🎯 Main Session (User Interaction)"]
        A[User Request] --> Q1[List Questions/Ambiguities]
        Q1 --> Q2{Unclear Points?}
        Q2 -->|Yes| Q3[AskUserQuestion / EnterPlanMode]
        Q3 --> Q4[User Clarification]
        Q4 --> Q1
        Q2 -->|No: requirements clear| DELEGATE
        DELEGATE[Delegate to Sub-Agent] --> WAIT
    end

    subgraph SUB["🤖 Sub-Agent (Token-Efficient Execution)"]
        WAIT[Receive Task] --> B[Implement]
        B --> C{Test & Verify}
        C -->|webapp-testing| D1[Test Result 1]
        C -->|Chrome DevTools MCP| D2[Test Result 2]
        C -->|Playwright E2E| D3[Test Result 3]
        D1 & D2 & D3 --> D[Aggregate Issues]
        D --> E{Loss < Threshold?}
        E -->|No: bugs found| B
        E -->|Yes: quality OK| F[Collect Evidence]
        F --> RETURN[Return Results to Main]
    end

    subgraph MAIN2["🎯 Main Session (Final Report)"]
        RETURN --> G[artifact-proof skill]
        G --> H[Report with Proof to User]
    end

    style A fill:#e1f5fe
    style Q2 fill:#fff9c4
    style E fill:#fff3e0
    style H fill:#c8e6c9
    style DELEGATE fill:#bbdefb
    style RETURN fill:#bbdefb
```

### Hearing Loop: Drill-Down Before Implementation
**Loop until all ambiguities are resolved. Never proceed with unclear requirements.**

1. **List Questions**: Upon receiving a request, enumerate all unclear/ambiguous points
2. **Ask User**: Use `AskUserQuestion` or `EnterPlanMode` to clarify
3. **Receive Clarification**: Get additional information from user
4. **Re-evaluate**: If new questions arise, loop back; otherwise proceed to implementation

**Drill-Down Perspectives**:
- Don't stop at surface-level questions ("What to build?" → also ask "Why is this needed?")
- Verbalize implicit assumptions (confirm what user takes for granted)
- Identify edge cases upfront ("What happens when X occurs?")

### Sub-Agent Delegation Strategy
**Why Sub-Agents**: Save main session tokens, enable parallel execution, isolate tasks

| Phase | Executor | Reason |
|-------|----------|--------|
| Hearing Loop | Main | Direct user interaction required, context preservation critical |
| Implement | Sub-Agent | Independent coding task, can parallelize multi-file edits |
| Test & Verify | Sub-Agent (Parallel) | Run webapp-testing / DevTools / E2E simultaneously |
| Bug Fix | Sub-Agent | Isolated fix task, doesn't pollute main context |
| Collect Evidence | Sub-Agent | Screenshot/video collection is independent |
| Final Report | Main | Direct delivery to user with full context |

### Loss Function: User Request vs Deliverable
- **Loss** = Gap between what user asked for and what was actually delivered
- **Threshold** = Zero critical bugs + Zero broken user flows + UI matches spec
- **Minimum iterations**: At least 2-3 verification cycles before reporting

### Verification Tools (use at least one per cycle)
1. **webapp-testing skill** - Interactive browser testing via Playwright
2. **Chrome DevTools MCP** - Console logs, network, DOM inspection
3. **Playwright E2E tests** - Automated regression detection

### Loop Exit Criteria
- [ ] Build succeeds without errors
- [ ] No type errors, no lint errors
- [ ] All user-specified features work as requested
- [ ] No console errors in browser
- [ ] Visual output matches expectations
- [ ] Evidence collected (screenshots/videos)

**Reporting "done" without evidence = task NOT completed**

## Testing Policy (STRICT - ZERO TOLERANCE)

**The user NEVER requests and NEVER approves the following. If discovered, they will report immediately.**

### Absolutely Prohibited (No Exceptions)
- ❌ **Demos / Demo Mode**: Fake implementations that only work for presentations
- ❌ **Hardcoding**: Values that should be dynamic but are hardcoded for convenience
- ❌ **Mocks / Stubs**: Fake objects that simulate real behavior (except DI swap for local emulators)
- ❌ **Bypasses**: Skipping authentication, validation, or security checks
- ❌ **Shortcuts**: Quick-and-dirty solutions that compromise quality
- ❌ **Fabrication**: Fake data, fake responses, fake success states

### What IS Allowed
- ✅ Dependency Injection with real local emulators (Firebase Emulator, local SMTP, etc.)
- ✅ Test fixtures with realistic data
- ✅ Environment-specific configuration (not behavior changes)

## Problem Detection First (Google Engineer Mindset)

**Your job is to FIND bugs, not to hope they don't exist.**

### Philosophy
- "I will find ALL bugs with my code alone" - this is your mindset
- E2E tests exist to DETECT problems, not to confirm "it works"
- If your test passes but the feature is broken, YOUR TEST IS BROKEN
- Problem detection code is a first-class asset, not throwaway scaffolding

### Before Implementing Features
- ALWAYS create problem detection mechanisms FIRST
- You cannot improve what you cannot detect
- Self-awareness of issues is mandatory

### E2E Test Requirements
Write tests that actively hunt for bugs:
- Do NOT rely solely on framework assertions (they're too naive)
- Inject JS to detect: element positions, computed styles, visibility states, animation completeness
- Check for edge cases that users will hit but demos won't show
- Test error states, loading states, empty states - not just happy paths

### Test Organization
- Place tests in reusable, asset-worthy locations: `e2e/features/`, `tests/e2e/`
- Each test should be runnable independently AND as part of the full suite
- Tests are assets for future regression detection - write them like production code

### Red Flags (your test is too weak if...)
- It only checks "element exists"
- It doesn't verify actual content/values
- It can't detect visual regressions
- It passes when the feature is obviously broken

## Command Interpretation
- When user says "open", use the macOS `open` command to open in Chrome
- Do not use `&` with the Bash tool; use `run_in_background: true` parameter instead

## Temporary Files
- All temporary scripts and files MUST be placed under `/tmp/` only - never pollute the project directory

## Worktree Git Operations
- When working in a worktree, do NOT chain `cd` and git commands
- Execute `cd` separately first, then run git commands in subsequent calls
- This avoids hook blocking issues that check the working directory

## Status Reporting
- After completing a task, use the `reporting-and-tmux` skill for say report and tmux window rename

## Backup Policy
- After editing `~/.claude/CLAUDE.md`, use the `claude-gist-backup` skill to sync to Gist

## Code of Conduct

**The user's stance: Zero tolerance for shortcuts. Will report violations immediately.**

- Taking easy but insecure approaches is criminal. Always implement secure solutions.
- Using time constraints as an excuse for shortcuts is strictly prohibited.
- If you ever feel tempted to suggest a mock, bypass, or "temporary" solution - DON'T.
- The user would rather wait longer for a proper implementation than accept a fake one.
- Any attempt to sneak in prohibited patterns will destroy trust permanently.
