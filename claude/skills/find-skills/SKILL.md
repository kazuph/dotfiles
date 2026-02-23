---
name: find-skills
description: Helps users discover and install agent skills from TRUSTED sources only. Use when the user asks "how do I do X", "find a skill for X", or wants to extend capabilities. Always verify the source before installing.
version: 1.0.0
---

# Find Skills (Hardened)

This skill helps you discover and install skills from the open agent skills ecosystem, with **strict source verification**.

## Trusted Sources (Allowlist)

Only install skills from these verified organizations:

| Source | Owner | Trust Level |
|---|---|---|
| `expo/skills` | Expo team (official) | Verified |
| `vercel-labs/skills` | Vercel team (official) | Verified |
| `moonbitlang/*` | MoonBit team (official) | Verified |

**Any source NOT in this list requires explicit user approval before installing.**

## When to Use This Skill

Use this skill when the user:

- Asks "how do I do X" where X might be a common task with an existing skill
- Says "find a skill for X" or "is there a skill for X"
- Wants to search for tools, templates, or workflows

## Workflow

### Step 1: Search for Skills

```bash
npx skills find [query]
```

### Step 2: Verify Source

Before presenting results to the user, check:

1. **Is the source in the Trusted Sources allowlist?**
   - YES: Present with "[Trusted]" label
   - NO: Present with "[Unverified - requires approval]" warning

2. **Check the GitHub repo** for the skill:
   - Stars count, last update date
   - Whether the org is a known company/project

### Step 3: Present to User (NEVER auto-install)

Always show:
1. Skill name and description
2. Source organization and trust level
3. Link to review on skills.sh or GitHub
4. Install command (for user to run manually or approve)

Example for trusted source:
```
[Trusted] expo/skills@expo-deployment
Deploying Expo apps to stores and web hosting.
Install: npx skills add expo/skills@expo-deployment -g
```

Example for untrusted source:
```
[Unverified] someuser/random-skills@cool-tool
This skill is from an unverified source. Review the code before installing:
https://github.com/someuser/random-skills
```

### Step 4: Install ONLY with User Confirmation

```bash
# NEVER use -y flag. Always require user confirmation.
npx skills add <owner/repo@skill> -g
```

**Prohibited:**
- `npx skills add ... -y` (auto-install without confirmation)
- Installing from non-allowlisted sources without explicit user approval
- Installing skills that modify system files or run arbitrary scripts

## Adding to Trusted Sources

To add a new trusted source, the user must explicitly update this SKILL.md's allowlist.

## Publishing Your Own Skills

Yes, you can publish your own skills! Here's how:

1. Create a skill: `npx skills init my-skill`
2. Edit the generated `SKILL.md` with your instructions
3. Push to a GitHub repository
4. Others can install with: `npx skills add <your-username>/<repo>`
5. Submit to https://skills.sh/ for discovery

Browse existing skills at: https://skills.sh/
