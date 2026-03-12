---
name: env-heal
description: "Scan codebase for env var references, cross-reference with validation schema, auto-fix and test. Use when env vars are missing from schema or .env.example. Triggers: heal env, fix env, env heal, env check, check env, validate env."
context: fork
agent: general-purpose
argument-hint: "[--quick?] [--dry-run?]"
compatibility: "Run from within the tathep-platform-api repo"
---

# Self-Healing Env Validation

Scan the entire codebase for environment variable references, cross-reference against the validation schema and `.env.example`, then auto-fix discrepancies and verify with tests.

## Mode Selection

Check `$ARGUMENTS` for `--quick`:

- **`--quick` mode:** Skip Phase 1 (full codebase scan) and Phase 4 (classify required vs optional). Go directly to Phase 2 → Phase 3 → Phase 5 → Phase 6 → Phase 7. This provides a fast schema-vs-example consistency check without scanning the entire codebase.
- **Full mode (default):** Run all phases (1 through 7).

## Phase 1: Discover All Env Var References

> **Skipped in `--quick` mode.**

Run the scan script to collect all env var references:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/scan-env-refs.sh [project-root]
```

The script searches for `process.env.*`, `Env.get()`, and `env()` patterns across `.ts`, `.tsx`, `.js`, `.jsx` files (excluding `node_modules`, `dist`, `build`, `.next`).

Parse the JSON output (`{"vars": [...], "count": N}`) for the master variable list. If count is 0, stop and report that no env var references were found.

## Phase 2: Read Schema and Example Files

1. **Read `env.ts`** (or equivalent schema file) — extract all declared/validated env var keys.
2. **Read `.env.example`** — extract all documented env var keys.

Produce sets:

- `schema_vars`: vars declared in env.ts schema
- `example_vars`: vars listed in .env.example
- `code_vars`: vars referenced in application code (only in full mode; empty in `--quick` mode)

## Phase 3: Gap Analysis

Compute:

**Full mode:**

- **In code but not in schema** → needs validation added to env.ts
- **In code but not in example** → needs entry added to .env.example
- **In schema but not in code** → potentially stale, flag for review
- **In example but not in code** → potentially stale, flag for review

**`--quick` mode** (schema vs example only):

- **In schema but not in example** → needs entry added to .env.example
- **In example but not in schema** → needs validation added to env.ts

## Phase 4: Determine Required vs Optional

> **Skipped in `--quick` mode.** All vars default to optional.

For each missing variable, check test fixtures and configuration:

```bash
# Check test helpers, factories, .env.test for the var
grep -rn 'VAR_NAME' test/ spec/ __tests__/ .env.test 2>/dev/null
```

- If the var appears in test fixtures with a value → likely **required** with that default
- If the var is used with a fallback/default in code (`?? 'default'`, `|| 'fallback'`, second arg to `Env.get`) → **optional**
- If no fallback and no test fixture → **required**, use empty string placeholder

## Phase 5: Auto-Fix

### Add to env.ts schema

For each var missing from schema, add the appropriate validation rule:

- Name contains `PORT`, `TIMEOUT`, `LIMIT`, `COUNT`, `SIZE` → `Env.schema.number.optional()`
- Name contains `ENABLE`, `DISABLE`, `DEBUG`, `VERBOSE`, `USE_` → `Env.schema.boolean.optional()`
- Name contains `URL`, `HOST`, `ENDPOINT` → `Env.schema.string.optional({ format: 'url' })` (if schema supports format) or `Env.schema.string.optional()`
- Otherwise → `Env.schema.string.optional()`

If Phase 4 determined the var is **required**, use `.required()` instead of `.optional()`.

Preserve existing file ordering and section groupings.

### Add to .env.example

For each var missing from .env.example:

- Add a line `VAR_NAME=` (empty) or `VAR_NAME=<default>` if a sensible default was found
- Place it near related vars (group by prefix: `DB_*`, `REDIS_*`, `AWS_*`, etc.)
- Add a comment if the purpose isn't obvious from the name

## Phase 6: Test & Validate

Run the project test suite:

```bash
node ace test   # AdonisJS
# or
bun run test    # Next.js projects
```

If tests fail:

1. Read the error output
2. Determine if the failure is related to the env changes
3. Adjust defaults or required/optional status accordingly
4. Re-run tests
5. Repeat up to 3 times — if still failing, revert changes and report what went wrong

## Phase 7: Summary Report

Output the report using this exact template. Replace placeholders with actual data. Omit any section that has zero items (e.g., skip "Stale" if nothing is stale).

```markdown
## Env Healing Report

**Mode:** Full / Quick | **Scanned vars:** N | **Gaps found:** N | **Fixed:** N

### Added to env.ts

| Variable | Type | Required/Optional | Reasoning |
|----------|------|-------------------|-----------|
| `VAR_NAME` | string | optional | Used in `app/Config/x.ts` with fallback |

### Added to .env.example

| Variable | Default | Source file |
|----------|---------|-------------|
| `VAR_NAME` | (empty) | `app/Services/y.ts` |

### Stale (flagged for review)

| Variable | Found in | Missing from | Action |
|----------|----------|--------------|--------|
| `OLD_VAR` | env.ts schema | codebase | Remove from schema or confirm usage |
| `LEGACY_VAR` | .env.example | codebase | Remove from example or confirm usage |

### Test Results

| Run | Result | Notes |
|-----|--------|-------|
| 1   | PASS/FAIL | (error summary if failed) |
| 2   | PASS/FAIL | (only if run 1 failed) |
| 3   | PASS/FAIL | (only if run 2 failed) |

**Final status:** All tests pass / Tests still failing — changes reverted

### Files Modified

- `env.ts` — added N variables
- `.env.example` — added N variables
```

## Constraints

- Never add actual secret values — use empty strings or placeholder patterns like `your-key-here`.
- Preserve existing file structure, ordering, and comments.
- If unsure whether a var is required or optional, default to optional.
- Skip `node_modules/`, `dist/`, `build/`, `.next/` directories.
