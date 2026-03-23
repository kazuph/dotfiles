---
name: browser-use-cli
description: Browser automation via browser-use CLI v2. Fastest local browser tool - use BEFORE playwright-cli or agent-browser. Supports navigation, clicking, typing, screenshots, state inspection, JS eval, data extraction, and session management. No API key needed for local mode.
allowed-tools: Bash(browser-use:*)
---

# Browser Automation with browser-use CLI v2

**Priority: Use this tool FIRST for all browser automation tasks.**
Faster than playwright-cli and agent-browser. No API key required for local operations.

## Quick Start

```bash
# Open URL in browser
browser-use open https://example.com

# Get current page state (URL, title, interactive elements with indices)
browser-use state

# Click element by index (from state output)
browser-use click 5

# Click by coordinates
browser-use click 150 300

# Type text (into focused element)
browser-use type "hello world"

# Type into specific element by index
browser-use input 3 "user@example.com"

# Take screenshot
browser-use screenshot /tmp/page.png
# Full page screenshot
browser-use screenshot --full /tmp/full.png
# Screenshot as base64 (no file)
browser-use screenshot

# Close session
browser-use close
```

## Core Commands

### Navigation
```bash
browser-use open https://example.com
browser-use back
browser-use scroll down
browser-use scroll up
browser-use scroll down --amount 500
```

### Interaction
```bash
browser-use click 5                    # Click element by index
browser-use click 150 300              # Click by x y coordinates
browser-use dblclick 5                 # Double-click
browser-use rightclick 5               # Right-click
browser-use hover 5                    # Hover over element
browser-use type "search query"        # Type into focused element
browser-use input 3 "hello"            # Type into element by index
browser-use select 7 "option-value"    # Select dropdown option
browser-use keys "Enter"               # Send keyboard keys
browser-use keys "Control+a"           # Key combinations
```

### Information Retrieval
```bash
browser-use state                      # Get URL, title, and interactive elements
browser-use get title                  # Page title
browser-use get text 5                 # Element text content
browser-use get html 5                 # Element HTML
browser-use get value 3                # Input element value
browser-use get attributes 5           # Element attributes
browser-use get bbox 5                 # Element bounding box
browser-use eval "document.title"      # Execute JavaScript
browser-use extract "all product names and prices"  # LLM-powered extraction
```

### Screenshots
```bash
browser-use screenshot                          # Base64 output
browser-use screenshot /path/to/file.png        # Save to file
browser-use screenshot --full /path/to/full.png # Full page
```

### Tabs
```bash
browser-use switch 1                   # Switch to tab by index
browser-use close-tab                  # Close current tab
browser-use close-tab 2               # Close specific tab
```

### Wait
```bash
browser-use wait selector ".loading"   # Wait for CSS selector
browser-use wait text "Success"        # Wait for text to appear
```

### Cookies
```bash
browser-use cookies get                # Get all cookies
browser-use cookies set name value     # Set cookie
browser-use cookies clear              # Clear all cookies
browser-use cookies export cookies.json
browser-use cookies import cookies.json
```

### Sessions
```bash
browser-use --session mytest open https://example.com   # Named session
browser-use --session mytest state                       # Use same session
browser-use --session mytest close                       # Close session
browser-use sessions                                     # List active sessions
```

## Global Options

```bash
--session NAME, -s NAME    # Session name (default: "default")
--browser {chromium,real,remote}  # Browser mode
--headed                   # Show browser window (useful for debugging)
--json                     # Output as JSON (for parsing)
```

## Workflow: Web App Testing

```bash
# 1. Open the app
browser-use open http://localhost:3000

# 2. Inspect page state (get element indices)
browser-use state

# 3. Interact
browser-use input 2 "test@example.com"
browser-use input 3 "password123"
browser-use click 5

# 4. Verify result
browser-use wait text "Welcome"
browser-use state
browser-use screenshot .artifacts/feature/login-result.png

# 5. Cleanup
browser-use close
```

## Workflow: Data Extraction

```bash
browser-use open https://example.com/products
browser-use extract "all product names, prices, and ratings as JSON"
browser-use close
```

## Real Chrome Mode (with existing logins/cookies)

Use `-b real` to launch Chrome with your actual profile (cookies, logins preserved):

```bash
# Open with real Chrome (Default profile, headless)
browser-use -b real open https://x.com

# With visible browser window (recommended for interactive use)
browser-use --headed -b real open https://x.com

# Specific profile
browser-use -b real --profile "Profile 1" open https://gmail.com

# List available Chrome profiles
browser-use -b real profile list
```

### Troubleshooting: DOMWatchdog / state errors

If `browser-use state` fails with "Expected at least one handler to return a non-None result":

```bash
# 1. Close session and kill daemon
browser-use close
pkill -f "browser-use"

# 2. Remove stale socket file
rm -f ~/.browser-use/default.sock

# 3. Restart with --headed -b real
browser-use --headed -b real open https://x.com

# 4. Verify
browser-use state
```

Root cause: daemon socket file gets corrupted, especially when switching between modes.

### Chrome must NOT be running already

Real mode launches a NEW Chrome process with your profile. If Chrome is already running,
the profile is locked and DOM access fails silently. Close Chrome first, or use a
different profile.

## Tips

- `state` is your best friend - always call it after navigation to see clickable elements
- Element indices from `state` are used in `click`, `input`, `hover`, `select`, etc.
- Use `--headed` when debugging to see what the browser is doing
- Sessions persist until explicitly closed - reuse them for multi-step flows
- No API key needed for local browser automation (chromium mode)
- If state/screenshot fails after mode switch, clean socket: `rm -f ~/.browser-use/default.sock`
