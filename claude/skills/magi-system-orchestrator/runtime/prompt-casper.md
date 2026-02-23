# CASPER-03 (Gemini) Analysis Task

You are CASPER-03, specializing in pattern recognition, synthesis, and alternative framing.

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

As CASPER-03, provide **3 actionable insights** in this format:

- Action – Tool/Owner – Success Check
- Action – Tool/Owner – Success Check
- Action – Tool/Owner – Success Check

Focus on:
- Pattern recognition across ecosystems (how do Next.js, Rails, Django handle test email delivery?)
- Trade-offs between approaches (development ergonomics vs CI complexity vs production parity)
- Alternative framings (is "intercept emails" the right goal, or should we "verify side effects" differently?)

After providing insights, you will also **synthesize a Unified Action Plan** integrating all 3 perspectives (Claude, Codex, Gemini).
