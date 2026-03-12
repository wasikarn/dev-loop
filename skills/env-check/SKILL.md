---
name: env-check
description: "Validate environment variable consistency between .env.example and env.ts schema. Use when env vars drift out of sync or after adding new config. Triggers: env check, validate env, check env consistency."
context: fork
agent: general-purpose
argument-hint: "[--dry-run?]"
compatibility: "Run from within the tathep-platform-api repo"
---

# Env Check

Validate environment variable consistency for the tathep-platform-api project.

## Steps

1. **Read both source files:**
   - Read `.env.example` from the project root — extract all variable names (lines matching `KEY=` or `KEY=value`, ignoring comments and blank lines).
   - Read `env.ts` from the project root — extract all keys registered in `Env.rules()` or `Env.schema.*` calls.

2. **Compare keys and report differences:**
   - List keys present in `.env.example` but **missing from `env.ts`** — these need schema validation added.
   - List keys present in `env.ts` but **missing from `.env.example`** — these need example entries added.
   - If both files are in sync, confirm that and stop.

3. **Fix missing entries:**
   - For keys missing from `env.ts`: add them using `Env.schema.string.optional()` with sensible defaults (empty string `''` unless the name implies a number or boolean, in which case use `Env.schema.number.optional()` or `Env.schema.boolean.optional()` respectively).
   - For keys missing from `.env.example`: add a commented placeholder line (`KEY=`) in the appropriate section.
   - Preserve existing ordering and section groupings in both files.

4. **Run tests to confirm nothing breaks:**

   ```bash
   cd <project-root> && node ace test
   ```

   - If tests fail, investigate and fix before finishing.

5. **Report a summary:** which keys were added/missing, what defaults were chosen, and test results.
