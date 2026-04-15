---
name: agent-browser
description: Browser automation with engine choice. Use for navigation, interaction, extraction, and AI-led behavior checks. `--engine lightpanda` is an optional fast first pass for DOM/network verification, not a replacement for real-browser visual verification or final E2E.
---

# Browser Automation with agent-browser

## Positioning

`agent-browser` has multiple engines. Treat Lightpanda as one option, not the default answer.

- Use `--engine lightpanda` when an AI should quickly probe behavior first:
  - page reachability
  - DOM structure
  - interactive elements
  - console/errors
  - network requests
  - simple multi-session or batch checks
- Do **not** use Lightpanda for:
  - final E2E judgment
  - visual verification
  - trustworthy screenshots as evidence
  - layout regressions
  - media generation/download completion checks
  - flows where the user needs "it definitely worked" proof

If the task needs rendered output, screenshots, downloads, or user-facing proof, switch to a real browser engine or another real-browser tool such as `playwright-cli`.

## Engine selection

### Real browser / Chrome family

Use this when fidelity matters.

```bash
# Set environment variable before running commands
export AGENT_BROWSER_EXECUTABLE_PATH="/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"
```

Or specify per-command:
```bash
agent-browser --executable-path "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary" open <url>
```

> **Note**: If you change `--executable-path`, run `agent-browser close` first to restart the daemon with the new browser.

### Lightpanda

Use this only for a quick first pass driven by the AI.

```bash
agent-browser --engine lightpanda open <url>
agent-browser --engine lightpanda snapshot -i -c
agent-browser --engine lightpanda console
agent-browser --engine lightpanda errors
agent-browser --engine lightpanda network requests
```

Important:

- A Lightpanda screenshot may be a placeholder rather than a rendered page.
- Success in Lightpanda means "the AI could inspect DOM/state/network", not "the user-visible workflow is verified".

## Quick start

```bash
agent-browser open <url>        # Navigate to page
agent-browser snapshot -i       # Get interactive elements with refs
agent-browser click @e1         # Click element by ref
agent-browser fill @e2 "text"   # Fill input by ref
agent-browser close             # Close browser
```

## Core workflow

1. Navigate: `agent-browser open <url>`
2. Snapshot: `agent-browser snapshot -i` (returns elements with refs like `@e1`, `@e2`)
3. Interact using refs from the snapshot
4. Re-snapshot after navigation or significant DOM changes

## Recommended first-pass workflow with Lightpanda

Use this only when the goal is "let the AI try the flow once and inspect what happens".

1. Start with `agent-browser --engine lightpanda open <url>`
2. Inspect `snapshot -i -c`
3. Check `get title`, `get url`, `console`, `errors`, and `network requests`
4. Try the minimum interaction needed to see whether the flow advances
5. Stop early and switch tools if the page needs rendered proof

Use this workflow for:

- quick smoke checks on internal apps
- confirming that a route loads
- checking that a button exists and triggers requests
- comparing local vs preview in separate sessions
- AI-led exploratory probing before deeper verification

Do not keep pushing Lightpanda once the task becomes visual or proof-oriented.

## When using Lightpanda through agent-browser

Prefer this decision rule:

1. Try Lightpanda first only if you want a fast AI-only behavior check
2. Stay in Lightpanda only while DOM, text, and network are enough to answer the question
3. Switch immediately if any of these happen:
   - screenshot output looks like a placeholder
   - the page depends on rich rendering or embedded app shells
   - the UI shows repeated `Error` without a clear DOM-level explanation
   - the task requires download confirmation
   - the task requires generated media confirmation
   - the task requires evidence to show another human

If a wrapper page blocks useful inspection, open the direct app URL instead of staying on the shell page.

## Commands

### Navigation
```bash
agent-browser open <url>      # Navigate to URL
agent-browser back            # Go back
agent-browser forward         # Go forward  
agent-browser reload          # Reload page
agent-browser close           # Close browser
```

### Snapshot (page analysis)
```bash
agent-browser snapshot        # Full accessibility tree
agent-browser snapshot -i     # Interactive elements only (recommended)
agent-browser snapshot -c     # Compact output
agent-browser snapshot -d 3   # Limit depth to 3
```

### Interactions (use @refs from snapshot)
```bash
agent-browser click @e1           # Click
agent-browser dblclick @e1        # Double-click
agent-browser fill @e2 "text"     # Clear and type
agent-browser type @e2 "text"     # Type without clearing
agent-browser press Enter         # Press key
agent-browser press Control+a     # Key combination
agent-browser hover @e1           # Hover
agent-browser check @e1           # Check checkbox
agent-browser uncheck @e1         # Uncheck checkbox
agent-browser select @e1 "value"  # Select dropdown
agent-browser scroll down 500     # Scroll page
agent-browser scrollintoview @e1  # Scroll element into view
```

### Get information
```bash
agent-browser get text @e1        # Get element text
agent-browser get value @e1       # Get input value
agent-browser get title           # Get page title
agent-browser get url             # Get current URL
```

### Screenshots
```bash
agent-browser screenshot          # Screenshot to stdout
agent-browser screenshot path.png # Save to file
agent-browser screenshot --full   # Full page
```

For Lightpanda, treat screenshots as diagnostic output only. Do not use them as visual proof.

### Wait
```bash
agent-browser wait @e1                     # Wait for element
agent-browser wait 2000                    # Wait milliseconds
agent-browser wait --text "Success"        # Wait for text
agent-browser wait --load networkidle      # Wait for network idle
```

### Semantic locators (alternative to refs)
```bash
agent-browser find role button click --name "Submit"
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
```

## Example: Form submission

```bash
agent-browser open https://example.com/form
agent-browser snapshot -i
# Output shows: textbox "Email" [ref=e1], textbox "Password" [ref=e2], button "Submit" [ref=e3]

agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser snapshot -i  # Check result
```

## Example: Authentication with saved state

```bash
# Login once
agent-browser open https://app.example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "username"
agent-browser fill @e2 "password"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser state save auth.json

# Later sessions: load saved state
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
```

## Sessions (parallel browsers)

```bash
agent-browser --session test1 open site-a.com
agent-browser --session test2 open site-b.com
agent-browser session list
```

With Lightpanda, sessions are especially useful for fast local-vs-preview comparisons:

```bash
agent-browser --engine lightpanda --session local open http://localhost:3000
agent-browser --engine lightpanda --session preview open https://preview.example.com
agent-browser --engine lightpanda --session local snapshot -i -c
agent-browser --engine lightpanda --session preview snapshot -i -c
```

## JSON output (for parsing)

Add `--json` for machine-readable output:
```bash
agent-browser snapshot -i --json
agent-browser get text @e1 --json
```

## Debugging

```bash
agent-browser open example.com --headed  # Show browser window
agent-browser console                    # View console messages
agent-browser errors                     # View page errors
```

For Lightpanda-first investigation, also check:

```bash
agent-browser --engine lightpanda network requests
agent-browser --engine lightpanda network response <id>
agent-browser --engine lightpanda dashboard
```
