---
name: xurl
description: "X (Twitter) API read-only CLI. Bookmarks retrieval, tweet search, engagement analytics (likes/RT aggregation), mentions, user lookup. Use when: reading X bookmarks, searching tweets, aggregating likes/retweets, checking mentions, looking up users. Triggers: bookmark, bookmarks, X search, Twitter search, likes count, RT count, engagement, tweet analytics."
allowed-tools: Bash(xurl:*), Bash(go build:*), Bash(go install:*), WebFetch, WebSearch
---

# X API with xurl (Read-Only)

xurl is a **read-only fork** of the official X CLI tool ([kazuph/xurl-readonly](https://github.com/kazuph/xurl-readonly)). Write operations (post, like, repost, etc.) are intentionally blocked at the OAuth scope level for security.

## Installation (if not installed)

```bash
# Build from source (read-only fork)
cd /Users/kazuph/src/github.com/kazuph/xurl-readonly
go build -o xurl-readonly .
cp xurl-readonly /opt/homebrew/bin/xurl

# Verify
xurl version
```

If the binary is missing or outdated, rebuild from the fork above. Do NOT use the upstream `xdevplatform/xurl` — it requests write scopes.

## Authentication

- Config: `~/.xurl` (YAML)
- App: `kazuph-cli` (Pay Per Use plan on console.x.com)
- Auth: OAuth 2.0 with read-only scopes
- Token auto-refreshes via `offline.access` scope
- User ID: `69535135` (kazuph)

If token expires and refresh fails, tell the user to run: `xurl auth oauth2`

## Available Scopes (Read-Only)

tweet.read, users.read, bookmark.read, follows.read, list.read, block.read, mute.read, like.read, space.read, offline.access

**Write scopes are NOT included.** This is intentional — if the token leaks, no damage can be done.

---

## Use Case 1: Bookmark Triage (GitHub Issues Style)

Bookmarks are used as a read-later / triage queue. The workflow:

### Step 1: Fetch bookmarks
```bash
# Latest bookmarks
xurl bookmarks

# More results
xurl /2/users/69535135/bookmarks?max_results=100
```

### Step 2: Deep-dive into bookmarked content
For each bookmark, check if it references a repo, article, or idea:
- Extract URLs from tweet `entities.urls[].expanded_url`
- Use `WebFetch` to read the linked content (GitHub repos, blog posts, etc.)
- Summarize findings like a GitHub issue comment

### Step 3: Agentic Knowledge Production (Obsidian Integration)

**1 bookmark = 1 Obsidian note.** This is NOT transcription — it's **agentic knowledge production.**
The agent reads, researches, synthesizes, and writes a note in its own words.

#### Philosophy: NOT a degraded bookmark

This is **agentic knowledge production**, not transcription.
A note that just summarizes the tweet is WORTHLESS — the user can read the tweet themselves.
The value is: AI read every link, cloned repos, read source code, and synthesized real insights.

**The note must be something the user CANNOT get by just reading the tweet.**

#### Full Agentic Pipeline (per bookmark)

**Phase 1: Gather ALL raw material**
```bash
# 1a. Full tweet text
xurl read TWEET_ID

# 1b. Thread detection + full thread
xurl search -n 30 "from:AUTHOR_ID conversation_id:CONVERSATION_ID"

# 1c. Replies & quotes for reputation
xurl search -n 20 "conversation_id:CONVERSATION_ID"
```

**Phase 2: DEEP investigation of every link**
This is where the real value is created:
- **GitHub repo** → `git clone` → read README, main source files, understand architecture, key design decisions. Read at least 3-5 important source files. Report: what it does, how it works, tech stack, code quality, limitations
- **Blog/article** → `WebFetch` full text → read carefully → extract the ARGUMENT, not just facts. What's the author's thesis? What evidence? What counter-arguments exist?
- **Paper** → `WebFetch` → methodology, results, significance, limitations
- **Product/tool** → `WebFetch` → what problem it solves, how it works technically, pricing, alternatives
- **Video/demo** → Note URL, but search for any text descriptions, blog posts, or docs about the same content

**Phase 3: Community reaction analysis**
- Read actual reply content, not just counts
- What are experts saying? What are criticisms?
- Is there consensus or debate?

**Phase 4: Write the Obsidian note**

Structure: **Top = original tweet (raw) → Middle = deep investigation → Bottom = synthesis & analysis**

The reader should be able to:
1. See the original tweet immediately (no link-chasing needed)
2. Read progressively deeper investigation
3. End with genuine insights that only exist because AI did the research

#### Note Template

```markdown
---
tweet_id: "TWEET_ID"
source: https://x.com/AUTHOR/status/TWEET_ID
author: "@username (Display Name)"
date: YYYY-MM-DD
tags: [topic1, topic2]
type: tool/idea/technique/library/opinion
---

## Original Tweet

> @username (YYYY-MM-DD)
> Full original tweet text here, verbatim, including URLs.
> If thread, include ALL tweets in order.

**Engagement**: N♥ / N RT / N BM / N impressions

---

## Linked Content Investigation

### [Title of linked content](URL)

(Deep investigation of the linked content. For repos: architecture analysis
from actually reading source code. For articles: the full argument structure.
This section should be LONG and substantive — it's the core value of the note.)

---

## Community Reaction

(What are people actually saying in replies? Quote specific interesting replies.
What's the consensus? Any expert opinions or criticisms?)

---

## Synthesis & Analysis

(Agent's own analysis connecting everything together.
What's the significance? How does this relate to other things the user cares about?
What are the implications? What should the user DO with this information?)
```

#### Processed Bookmark Tracking

```bash
# Check if already processed (tweet_id in frontmatter)
ob search query="TWEET_ID" matches
# If found → skip
```

#### Batch Triage Flow
```
xurl bookmarks (up to 100)
  ↓ for each tweet
ob search query="TWEET_ID" matches → skip if exists
  ↓ if new
Phase 1: gather raw (tweet + thread + replies)
  ↓
Phase 2: deep-dive every URL (clone repos, read articles, etc.)
  ↓
Phase 3: community reaction
  ↓
Phase 4: write substantive Obsidian note via ob create
```

#### ABSOLUTE RULES
- **Original tweet text goes in the note VERBATIM** — no paraphrasing, no omission
- **Mermaid diagram right after the original tweet** — visually summarize what the tweet describes
  - **BANNED types**: sequence diagram, mindmap
  - **Choose the best type per content**: flowchart, flowchart TD/LR, graph, state diagram, ER diagram, gantt, pie, etc.
  - Japanese labels, include concrete numbers/names
  - **Layout tip**: フェーズ間は縦（TB）、フェーズ内のステップは横（`direction LR`）。subgraphで各フェーズを囲み、中身をLRにするのが最も見やすい。全ステップが縦1列に並ぶ図は避ける
- **Every URL must be fully investigated** — not just mentioned
- **GitHub repos must be cloned and code must be read** — README alone is not enough
- **Notes must have real reading value** — if it's shorter than the tweet, it's worthless
- **Structure is top-to-bottom depth** — tweet → diagram → investigation → synthesis
- **No "Open Questions" cop-out** — answer them yourself or explicitly flag for user action
- **Tag with existing vault tags** — `ob search` for related topics first

---

## Use Case 2: Engagement Analytics (Likes / RT Aggregation)

### Daily engagement summary
```bash
# Get your recent tweets with metrics
xurl search -n 100 "from:kazuph"
```

Each tweet includes `public_metrics`:
```json
{
  "retweet_count": 5,
  "reply_count": 2,
  "like_count": 42,
  "quote_count": 1,
  "bookmark_count": 3,
  "impression_count": 1200
}
```

### Who liked/retweeted a specific tweet
```bash
# Users who liked tweet ID 123456
xurl /2/tweets/123456/liking_users

# Users who retweeted tweet ID 123456
xurl /2/tweets/123456/retweeted_by
```

### Aggregation approach
1. Fetch `xurl search -n 100 "from:kazuph"` (last 7 days)
2. Filter by `created_at` for today / this week
3. Sum `like_count`, `retweet_count`, `reply_count`, `impression_count`
4. Present as daily/weekly report

---

## Command Reference

### Bookmarks
```bash
xurl bookmarks
xurl /2/users/69535135/bookmarks?max_results=100
```

### Search (Recent 7 days)
```bash
xurl search "keyword"
xurl search -n 50 "keyword"
xurl search "from:kazuph"
xurl search "@kazuph"
xurl search "to:kazuph"
xurl search "Claude Code lang:ja"

# IMPORTANT: queries starting with - need quoting
xurl search "-from:kazuph to:kazuph"
```

### User Info
```bash
xurl whoami
xurl user kazuph
```

### Engagement Data
```bash
xurl /2/tweets/TWEET_ID/liking_users
xurl /2/tweets/TWEET_ID/retweeted_by
xurl likes            # Your liked posts
xurl mentions         # Recent mentions
```

### Other Read Operations
```bash
xurl followers
xurl following
xurl timeline
xurl read <tweet_id>
```

### Raw API Access
```bash
xurl /2/users/me
xurl /2/tweets/search/recent?query=keyword&max_results=10
```

## Write Operations — BLOCKED (403 Forbidden)

By design, all write operations return 403:
post, reply, quote, repost, like, unlike, follow, unfollow, bookmark, unbookmark, block, unblock, mute, unmute, dm, delete

## Binary & Source

- Read-only fork: `/Users/kazuph/src/github.com/kazuph/xurl-readonly`
- Installed at: `/opt/homebrew/bin/xurl`
- Upstream (DO NOT USE): `xdevplatform/xurl` (requests write scopes)

## Pay Per Use Notes

- API calls cost credits (check balance at console.x.com)
- Reads are cheap (~$0.001 per request)
- Search and bookmark reads are the primary use case
