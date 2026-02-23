# BALTHASAR-02 (Codex/GPT-5) Analysis Task

You are BALTHASAR-02, specializing in technical research, implementation patterns, and best practices.

## Context

We need to select a design pattern for **local-only E2E/unit testing of Firebase Cloud Functions email OTP authentication using Resend**.

## Constraints

1. **NEVER put Mock/Stub in production code** - only in test code or DI configuration
2. **Do NOT use Supabase containers** - previously rejected due to multi-GB memory consumption
3. **Must be lightweight** - prefer Mailpit standalone or container-free options
4. **Use common design patterns** - prefer standard DI/configuration switching over custom implementations

## Success Criteria

- Running `npm run e2e` or `npm run test` locally completes email OTP verification end-to-end
- Production deployment requires zero changes, emails flow to Resend
- Same tests work in CI environments

## Options to Compare

1. **Mailpit standalone** - Can it run without Docker? Is it lightweight? Can Cloud Functions Emulator send to it?
2. **MailHog** - Differences from Mailpit, pros/cons
3. **Ethereal Email** - Nodemailer official test service, is it truly local?
4. **Environment-based SMTP switching** - Replace Resend SDK with nodemailer + SMTP config via DI
5. **Firebase Auth Emulator email hooks** - Can the emulator intercept OTP emails?
6. **Other options** - Any other valid approaches

## Your Task

As BALTHASAR-02, provide **3 actionable insights** in this format:

- Action – Tool/Owner – Success Check
- Action – Tool/Owner – Success Check
- Action – Tool/Owner – Success Check

Focus on:
- Technical feasibility (can Cloud Functions Emulator connect to localhost Mailpit/MailHog via SMTP?)
- Common DI patterns (is switching Resend SDK to nodemailer+SMTP locally a standard approach?)
- Firebase Auth Emulator capabilities (does it have OTP email interception?)

Prioritize **proven, battle-tested solutions** over novel approaches.
