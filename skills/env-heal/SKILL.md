---
name: env-heal
description: "Scan codebase for env var references, cross-reference with validation schema, auto-fix and test. Use when env vars are missing from schema or .env.example. Triggers: heal env, fix env, env heal."
context: fork
agent: general-purpose
argument-hint: "[--dry-run?]"
compatibility: "Run from within the tathep-platform-api repo"
---

# Self-Healing Env Validation

Scan the entire codebase for environment variable references, cross-reference against the validation schema and `.env.example`, then auto-fix discrepancies and verify with tests.

## Phase 1: Discover All Env Var References

Search the codebase for every env var reference pattern:

```bash
# Pattern 1: process.env.VAR_NAME
grep -rn 'process\.env\.\w\+' --include='*.ts' --include='*.tsx' --include='*.js' | grep -v node_modules | grep -v dist

# Pattern 2: Env.get('VAR_NAME') or Env.get('VAR_NAME', default)
grep -rn "Env\.get(" --include='*.ts' --include='*.js' | grep -v node_modules | grep -v dist

# Pattern 3: env('VAR_NAME') helper calls
grep -rn "env(" --include='*.ts' --include='*.tsx' --include='*.js' | grep -v node_modules | grep -v dist
```

Extract unique variable names from all matches. Build a master list.

## Phase 2: Read Schema and Example Files

1. **Read `env.ts`** (or equivalent schema file) — extract all declared/validated env var keys.
2. **Read `.env.example`** — extract all documented env var keys.

Produce three sets:

- `code_vars`: vars referenced in application code
- `schema_vars`: vars declared in env.ts schema
- `example_vars`: vars listed in .env.example

## Phase 3: Gap Analysis

Compute:

- **In code but not in schema** → needs validation added to env.ts
- **In code but not in example** → needs entry added to .env.example
- **In schema but not in code** → potentially stale, flag for review
- **In example but not in code** → potentially stale, flag for review

## Phase 4: Determine Required vs Optional

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

Output:

```markdown
## Env Healing Report

### Added to env.ts
| Variable | Type | Required | Reasoning |
|----------|------|----------|-----------|
| VAR_NAME | string | optional | Used in app/Config/x.ts with fallback |

### Added to .env.example
| Variable | Default | Source |
|----------|---------|--------|
| VAR_NAME | (empty) | Referenced in app/Services/y.ts |

### Stale (flagged for review)
- `OLD_VAR` — in schema but not referenced in code
- `LEGACY_VAR` — in .env.example but not referenced in code

### Test Results
✅ All tests pass / ❌ X failures (details)
```

## Constraints

- Never add actual secret values — use empty strings or placeholder patterns like `your-key-here`.
- Preserve existing file structure, ordering, and comments.
- If unsure whether a var is required or optional, default to optional.
- Skip `node_modules/`, `dist/`, `build/`, `.next/` directories.
