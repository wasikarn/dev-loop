# devflow-engine + TypeScript Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename devflow-sdk → devflow-engine, extend shared types, and implement three deterministic TypeScript modules (risk-scorer, mode-resolver, lens-assigner) that replace prose-based routing logic in skill markdown files.

**Architecture:** All new modules live in `devflow-engine/src/` and share types via the existing `src/types.ts`. The primary skill integration point is a new `resolve` CLI subcommand that returns `{ mode, specialistTriggers, lensCount, score, reasons }` as JSON. Skills call `resolve` and no longer need prose routing logic.

**Tech Stack:** TypeScript strict · NodeNext modules · vitest · tsx · Node.js built-ins only for new modules

---

## File Map

| File | Action | Purpose |
| --- | --- | --- |
| `devflow-engine/` | Rename from `devflow-sdk/` | Directory rename |
| `devflow-engine/src/types.ts` | Modify | Add branded types, factory functions, engine-specific types |
| `devflow-engine/src/engine-types.test.ts` | Create | Test factory function boundaries |
| `devflow-engine/src/risk-scorer.ts` | Create | Composite 0–100 PR risk score |
| `devflow-engine/src/risk-scorer.test.ts` | Create | Scoring formula + threshold tests |
| `devflow-engine/src/mode-resolver.ts` | Create | Flag + signal → full review decision |
| `devflow-engine/src/mode-resolver.test.ts` | Create | Precedence, specialist triggers, lens count |
| `devflow-engine/src/lens-assigner.ts` | Create | File count → lens injection table |
| `devflow-engine/src/lens-assigner.test.ts` | Create | Boundary + assignment tests |
| `devflow-engine/src/cli.ts` | Modify | Add `score` and `resolve` subcommands |
| `skills/review/references/phase-3.md` | Modify | Replace prose auto-escalation with engine `resolve` call |
| `skills/review/references/phase-5.md` | Modify | `SDK_DIR` → `ENGINE_DIR` |
| `skills/debug/references/phase-2-investigate.md` | Modify | `SDK_DIR` → `ENGINE_DIR` |
| `skills/build/references/phase-7-falsification.md` | Modify | `SDK_DIR` → `ENGINE_DIR` |
| `skills/build/references/phase-3-plan.md` | Modify | `SDK_DIR` → `ENGINE_DIR` |
| `skills/build/references/phase-6-review.md` | Modify | `SDK_DIR` → `ENGINE_DIR` |
| `CLAUDE.md` | Modify | `devflow-sdk` → `devflow-engine` references |
| `.claude/rules/devflow-sdk-rules.md` | Modify | Path glob update |

---

## Task 1: Rename devflow-sdk → devflow-engine (atomic commit)

**Files:**
- Rename: `devflow-sdk/` → `devflow-engine/`
- Modify: `devflow-engine/package.json`
- Modify: `CLAUDE.md`
- Modify: `.claude/rules/devflow-sdk-rules.md`
- Modify: `skills/review/references/phase-3.md`, `phase-5.md`
- Modify: `skills/debug/references/phase-2-investigate.md`
- Modify: `skills/build/references/phase-7-falsification.md`, `phase-3-plan.md`, `phase-6-review.md`

- [ ] **Step 1: Rename the directory**

```bash
git mv devflow-sdk devflow-engine
```

- [ ] **Step 2: Update package.json name field**

In `devflow-engine/package.json`, change:
```json
"name": "devflow-sdk",
```
to:
```json
"name": "devflow-engine",
```

- [ ] **Step 3: Update all skill bash blocks — SDK_DIR and error prefixes**

```bash
# All 6 skill files: SDK_DIR → ENGINE_DIR, devflow-sdk → devflow-engine, sdk- → engine-
for f in \
  skills/review/references/phase-3.md \
  skills/review/references/phase-5.md \
  skills/debug/references/phase-2-investigate.md \
  skills/build/references/phase-7-falsification.md \
  skills/build/references/phase-3-plan.md \
  skills/build/references/phase-6-review.md; do
  sed -i '' \
    -e 's/SDK_DIR/ENGINE_DIR/g' \
    -e 's/devflow-sdk/devflow-engine/g' \
    -e 's/\[sdk-/[engine-/g' \
    "$f"
done
```

- [ ] **Step 4: Update CLAUDE.md references**

```bash
sed -i '' 's/devflow-sdk/devflow-engine/g' CLAUDE.md
```

- [ ] **Step 5: Update devflow-sdk-rules.md path glob**

In `.claude/rules/devflow-sdk-rules.md`, change:
```yaml
paths:
  - "devflow-sdk/**"
```
to:
```yaml
paths:
  - "devflow-engine/**"
```

Also update the description line: `TypeScript SDK at \`devflow-sdk/\`` → `TypeScript engine at \`devflow-engine/\``

- [ ] **Step 6: Verify CLI still works after rename**

```bash
cd devflow-engine && npm test
```

Expected: all existing tests pass. Fix any import path issues if found.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor: rename devflow-sdk → devflow-engine"
```

---

## Task 2: Extend src/types.ts with engine types and factory functions

**Files:**
- Modify: `devflow-engine/src/types.ts`
- Create: `devflow-engine/src/engine-types.test.ts`

- [ ] **Step 1: Write failing tests for factory functions**

Create `devflow-engine/src/engine-types.test.ts`:

```typescript
import { describe, expect, it } from 'vitest'
import { toScore, toFilePath, toBonus } from './types.js'

describe('toScore', () => {
  it('accepts valid range', () => {
    expect(toScore(0)).toBe(0)
    expect(toScore(50)).toBe(50)
    expect(toScore(100)).toBe(100)
  })

  it('throws below 0', () => {
    expect(() => toScore(-1)).toThrow(RangeError)
  })

  it('throws above 100', () => {
    expect(() => toScore(101)).toThrow(RangeError)
  })
})

describe('toFilePath', () => {
  it('accepts valid path', () => {
    expect(toFilePath('src/foo.ts')).toBe('src/foo.ts')
  })

  it('throws on empty string', () => {
    expect(() => toFilePath('')).toThrow()
  })

  it('throws on whitespace-only string', () => {
    expect(() => toFilePath('   ')).toThrow()
  })
})

describe('toBonus', () => {
  it('clamps above +10', () => {
    expect(toBonus(15)).toBe(10)
  })

  it('clamps below -10', () => {
    expect(toBonus(-20)).toBe(-10)
  })

  it('passes through valid values', () => {
    expect(toBonus(10)).toBe(10)
    expect(toBonus(-10)).toBe(-10)
    expect(toBonus(0)).toBe(0)
  })
})
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
cd devflow-engine && npm test -- engine-types
```

Expected: FAIL with "toScore is not exported" or similar.

- [ ] **Step 3: Add engine types to src/types.ts**

Append to the end of `devflow-engine/src/types.ts` (after existing exports):

```typescript
// ─── Engine: branded primitives ──────────────────────────────────────────────

export type Score = number & { readonly _brand: 'Score' }
export type FilePath = string & { readonly _brand: 'FilePath' }
export type Bonus = number & { readonly _brand: 'Bonus' }

export function toScore(n: number): Score {
  if (n < 0 || n > 100) throw new RangeError(`Score out of range [0,100]: ${n}`)
  return n as Score
}
export function toFilePath(s: string): FilePath {
  if (s.trim().length === 0) throw new Error('FilePath must not be empty or whitespace')
  return s as FilePath
}
export function toBonus(n: number): Bonus {
  return Math.max(-10, Math.min(10, n)) as Bonus
}

// ─── Engine: domain types ─────────────────────────────────────────────────────

export type ReviewMode = 'micro' | 'quick' | 'full'
export type LensCount = 'full' | 'reduced' | 'skip'

export type Lens =
  | 'security' | 'performance' | 'frontend' | 'database'
  | 'typescript' | 'error-handling' | 'api-design' | 'observability'

export type SpecialistType =
  | 'test-quality-reviewer'
  | 'api-contract-auditor'
  | 'migration-reviewer'
  | 'silent-failure-hunter'
  | 'type-design-analyzer'

export type SpecialistPriority = 1 | 2 | 3 | 4 | 5

export type SpecialistTrigger = {
  readonly type: SpecialistType
  readonly priority: SpecialistPriority
}

/** All signals needed to compute a risk score and review decision */
export type PRSignals = {
  readonly loc: number
  readonly changedFiles: readonly FilePath[]
  readonly hasJiraKey: boolean
  readonly dismissedPatterns: readonly string[]
  readonly diffContent: string
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
cd devflow-engine && npm test -- engine-types
```

Expected: all 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add devflow-engine/src/types.ts devflow-engine/src/engine-types.test.ts
git commit -m "feat(engine): add branded types and factory functions to types.ts"
```

---

## Task 3: Implement risk-scorer.ts (TDD)

**Files:**
- Create: `devflow-engine/src/risk-scorer.ts`
- Create: `devflow-engine/src/risk-scorer.test.ts`

- [ ] **Step 1: Write failing tests**

Create `devflow-engine/src/risk-scorer.test.ts`:

```typescript
import { describe, expect, it } from 'vitest'
import { computeScore } from './risk-scorer.js'
import { toFilePath } from './types.js'

function signals(overrides: {
  loc?: number
  files?: string[]
  hasJiraKey?: boolean
  dismissed?: string[]
  diff?: string
} = {}): Parameters<typeof computeScore>[0] {
  return {
    loc: overrides.loc ?? 0,
    changedFiles: (overrides.files ?? []).map(toFilePath),
    hasJiraKey: overrides.hasJiraKey ?? false,
    dismissedPatterns: overrides.dismissed ?? [],
    diffContent: overrides.diff ?? '',
  }
}

describe('loc scoring', () => {
  it('loc=0 → locScore=0', () => {
    const r = computeScore(signals({ loc: 0 }))
    expect(r.breakdown.loc).toBe(0)
  })

  it('loc=399 → locScore=39 (floored)', () => {
    const r = computeScore(signals({ loc: 399 }))
    expect(r.breakdown.loc).toBe(39)
  })

  it('loc=400 → locScore=40 (cap exact)', () => {
    const r = computeScore(signals({ loc: 400 }))
    expect(r.breakdown.loc).toBe(40)
  })

  it('loc=401 → locScore=40 (cap holds)', () => {
    const r = computeScore(signals({ loc: 401 }))
    expect(r.breakdown.loc).toBe(40)
  })

  it('loc=1600 → locScore=40 (large LOC still capped)', () => {
    const r = computeScore(signals({ loc: 1600 }))
    expect(r.breakdown.loc).toBe(40)
  })
})

describe('fileType scoring', () => {
  it('auth file → 35', () => {
    const r = computeScore(signals({ files: ['src/auth/login.ts'] }))
    expect(r.breakdown.fileType).toBe(35)
  })

  it('migrations file → 35', () => {
    const r = computeScore(signals({ files: ['db/migrations/001_create_users.ts'] }))
    expect(r.breakdown.fileType).toBe(35)
  })

  it('CI/CD yml file → 25', () => {
    const r = computeScore(signals({ files: ['.github/workflows/deploy.yml'] }))
    expect(r.breakdown.fileType).toBe(25)
  })

  it('controller file → 15', () => {
    const r = computeScore(signals({ files: ['src/controllers/user.controller.ts'] }))
    expect(r.breakdown.fileType).toBe(15)
  })

  it('test file → 5', () => {
    const r = computeScore(signals({ files: ['src/user.test.ts'] }))
    expect(r.breakdown.fileType).toBe(5)
  })

  it('auth + test file in same PR → 35 (highest wins, not sum)', () => {
    const r = computeScore(signals({ files: ['src/auth/login.ts', 'src/auth/login.test.ts'] }))
    expect(r.breakdown.fileType).toBe(35)
  })

  it('no matching file → 0', () => {
    const r = computeScore(signals({ files: ['src/utils/format.ts'] }))
    expect(r.breakdown.fileType).toBe(0)
  })
})

describe('semantic scoring', () => {
  it('secret pattern in diff → 30', () => {
    const r = computeScore(signals({ diff: '+const password = process.env.DB_PASS' }))
    expect(r.breakdown.semantic).toBe(30)
  })

  it('SQL migration in diff → 20', () => {
    const r = computeScore(signals({ diff: '+CREATE TABLE users (id int)' }))
    expect(r.breakdown.semantic).toBe(20)
  })

  it('auth token pattern in diff → 15', () => {
    const r = computeScore(signals({ diff: '+const token = req.headers.authorization.replace("Bearer ", "")' }))
    expect(r.breakdown.semantic).toBe(15)
  })

  it('SQL + secrets in same diff → 30 (highest wins, not additive)', () => {
    const r = computeScore(signals({ diff: '+CREATE TABLE users\n+const api_key = "abc"' }))
    expect(r.breakdown.semantic).toBe(30)
  })

  it('no semantic match → 0', () => {
    const r = computeScore(signals({ diff: '+const greeting = "hello world"' }))
    expect(r.breakdown.semantic).toBe(0)
  })
})

describe('contextBonus', () => {
  it('Jira key present → +10', () => {
    const r = computeScore(signals({ hasJiraKey: true }))
    expect(r.breakdown.contextBonus).toBe(10)
  })

  it('1 dismissed match → -10', () => {
    const r = computeScore(signals({
      diff: '+const foo = bar',
      dismissed: ['const foo = bar'],
    }))
    expect(r.breakdown.contextBonus).toBe(-10)
  })

  it('2 dismissed matches → -10 (floor holds, not -20)', () => {
    const r = computeScore(signals({
      diff: '+const foo = bar\n+const baz = qux',
      dismissed: ['const foo = bar', 'const baz = qux'],
    }))
    expect(r.breakdown.contextBonus).toBe(-10)
  })

  it('Jira + 1 dismissed match → 0 (+10 - 10)', () => {
    const r = computeScore(signals({
      hasJiraKey: true,
      diff: '+const foo = bar',
      dismissed: ['const foo = bar'],
    }))
    expect(r.breakdown.contextBonus).toBe(0)
  })
})

describe('mode thresholds', () => {
  it('score=29 → micro', () => {
    // 0 LOC + no files + no semantic + no bonus ≈ 0; force score via auth file + loc
    const r = computeScore(signals({ loc: 290 }))  // loc=290 → locScore=29
    expect(r.mode).toBe('micro')
  })

  it('score=30 → quick', () => {
    const r = computeScore(signals({ loc: 300 }))  // loc=300 → locScore=30
    expect(r.mode).toBe('quick')
  })

  it('score=54 → quick', () => {
    // loc=400(40) + CI/CD yml(25) - jira bonus... wait: 40+25=65 → full
    // Use: loc=200(20) + controller(15) + SQL(20) - 1 dismissed(-10) = 45 → quick
    const r = computeScore(signals({
      loc: 200,
      files: ['src/controllers/user.ts'],
      diff: '+ALTER TABLE users ADD COLUMN email text\n+const foo = bar',
      dismissed: ['const foo = bar'],
    }))
    expect(r.total).toBeGreaterThanOrEqual(30)
    expect(r.total).toBeLessThanOrEqual(54)
    expect(r.mode).toBe('quick')
  })

  it('score=55 → full', () => {
    // loc=400(40) + auth file(35) → 75 capped at 100 → full
    const r = computeScore(signals({ loc: 400, files: ['src/auth/jwt.ts'] }))
    expect(r.mode).toBe('full')
  })
})

describe('total ceiling', () => {
  it('max signals → total ≤ 100', () => {
    const r = computeScore(signals({
      loc: 1600,
      files: ['src/auth/login.ts'],
      diff: '+const api_key = process.env.SECRET_KEY',
      hasJiraKey: true,
    }))
    expect(r.total).toBeLessThanOrEqual(100)
  })
})

describe('float boundary', () => {
  it('loc=399 produces integer locScore (no float leakage)', () => {
    const r = computeScore(signals({ loc: 399 }))
    expect(Number.isInteger(r.breakdown.loc)).toBe(true)
  })
})
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
cd devflow-engine && npm test -- risk-scorer
```

Expected: FAIL — "Cannot find module './risk-scorer.js'"

- [ ] **Step 3: Implement risk-scorer.ts**

Create `devflow-engine/src/risk-scorer.ts`:

```typescript
import type { PRSignals, ReviewMode, Score, Bonus } from './types.js'
import { toScore, toBonus } from './types.js'

// ─── Internal types ───────────────────────────────────────────────────────────

export type ScoreBreakdown = {
  readonly loc: number
  readonly fileType: number
  readonly semantic: number
  readonly contextBonus: number
}

export type RiskResult = {
  readonly total: number
  readonly breakdown: ScoreBreakdown
  readonly mode: ReviewMode
  readonly reasons: readonly string[]
}

// ─── Component scorers ────────────────────────────────────────────────────────

function computeLocScore(loc: number): Score {
  return toScore(Math.min(40, Math.floor((loc / 400) * 40)))
}

const FILE_TYPE_PATTERNS: Array<{ pattern: RegExp; score: number; reason: string }> = [
  { pattern: /\/(auth|migrations)\//i, score: 35, reason: 'auth/migrations file' },
  { pattern: /^\.github\/.+\.yml$/, score: 25, reason: 'CI/CD config' },
  { pattern: /\.(controller|router|handler|route)\.[jt]sx?$|\/(controllers?|routes?|handlers?)\//, score: 15, reason: 'controller/route handler' },
  { pattern: /\.(test|spec)\.[jt]sx?$/, score: 5, reason: 'test file' },
]

function computeFileTypeScore(files: readonly string[]): { score: Score; reason: string } {
  let max = 0
  let reason = ''
  for (const file of files) {
    for (const { pattern, score, reason: r } of FILE_TYPE_PATTERNS) {
      if (pattern.test(file) && score > max) {
        max = score
        reason = r
      }
    }
  }
  return { score: toScore(max), reason }
}

const SEMANTIC_PATTERNS: Array<{ pattern: RegExp; score: number; reason: string }> = [
  { pattern: /\b(password|api_key|secret|private_key)\b/i, score: 30, reason: 'secret pattern in diff' },
  { pattern: /\b(CREATE TABLE|ALTER TABLE|DROP TABLE)\b/i, score: 20, reason: 'SQL DDL in diff' },
  { pattern: /\b(jwt|bearer|access_token|refresh_token)\b/i, score: 15, reason: 'auth token pattern in diff' },
]

function computeSemanticScore(diffContent: string): { score: Score; reason: string } {
  let max = 0
  let reason = ''
  for (const { pattern, score, reason: r } of SEMANTIC_PATTERNS) {
    if (pattern.test(diffContent) && score > max) {
      max = score
      reason = r
    }
  }
  return { score: toScore(max), reason }
}

function computeContextBonus(
  hasJiraKey: boolean,
  dismissedPatterns: readonly string[],
  diffContent: string,
): Bonus {
  let bonus = 0
  if (hasJiraKey) bonus += 10
  const matchCount = dismissedPatterns.filter(p => diffContent.includes(p)).length
  if (matchCount > 0) bonus -= 10  // floor at -10 regardless of match count
  return toBonus(bonus)
}

function scoreToMode(score: number): ReviewMode {
  if (score >= 55) return 'full'
  if (score >= 30) return 'quick'
  return 'micro'
}

// ─── Public API ───────────────────────────────────────────────────────────────

export function computeScore(signals: PRSignals): RiskResult {
  const locScore = computeLocScore(signals.loc)
  const { score: fileTypeScore, reason: fileTypeReason } = computeFileTypeScore(
    signals.changedFiles.map(String),
  )
  const { score: semanticScore, reason: semanticReason } = computeSemanticScore(signals.diffContent)
  const contextBonus = computeContextBonus(
    signals.hasJiraKey,
    signals.dismissedPatterns,
    signals.diffContent,
  )

  const rawTotal = locScore + fileTypeScore + semanticScore + contextBonus
  const total = Math.min(100, Math.max(0, rawTotal))
  const mode = scoreToMode(total)

  const reasons: string[] = []
  if (locScore > 0) reasons.push(`LOC ${signals.loc} → score ${locScore}`)
  if (fileTypeScore > 0) reasons.push(fileTypeReason)
  if (semanticScore > 0) reasons.push(semanticReason)
  if (contextBonus !== 0) reasons.push(`context bonus: ${contextBonus > 0 ? '+' : ''}${contextBonus}`)

  return {
    total,
    breakdown: { loc: locScore, fileType: fileTypeScore, semantic: semanticScore, contextBonus },
    mode,
    reasons,
  }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
cd devflow-engine && npm test -- risk-scorer
```

Expected: all tests PASS. If a threshold test fails due to the combined-score arithmetic, adjust the test's input to actually land in the target range — do not adjust the thresholds.

- [ ] **Step 5: Commit**

```bash
git add devflow-engine/src/risk-scorer.ts devflow-engine/src/risk-scorer.test.ts
git commit -m "feat(engine): add risk-scorer with composite 0-100 scoring"
```

---

## Task 4: Add `score` CLI subcommand

**Files:**
- Modify: `devflow-engine/src/cli.ts`

- [ ] **Step 1: Add score subcommand to cli.ts**

Add the following block to `devflow-engine/src/cli.ts` before the `// ─── main dispatcher ───` section:

```typescript
// ─── score subcommand ─────────────────────────────────────────────────────────

interface ParsedScoreArgs {
  pr: number | undefined
  dismissed: string | undefined
  jira: boolean
}

function parseScoreArgs(args: string[]): ParsedScoreArgs {
  return parseFlags(args, [
    { flag: '--pr', field: 'pr', type: 'positiveInt', required: true, errorPrefix: '[engine-score]', onError: 'exit' },
    { flag: '--dismissed', field: 'dismissed', type: 'string', errorPrefix: '[engine-score]' },
    { flag: '--jira', field: 'jira', type: 'boolean', errorPrefix: '[engine-score]' },
  ], {
    pr: undefined as number | undefined,
    dismissed: undefined as string | undefined,
    jira: false as boolean,
  })
}

async function runScoreCommand(args: string[]): Promise<void> {
  const parsed = parseScoreArgs(args)
  if (parsed.pr === undefined) {
    console.error('[engine-score] --pr is required')
    process.exit(1)
  }

  const files = readPrDiff(parsed.pr)
  const loc = files.reduce((sum, f) => sum + f.diffLineCount, 0)
  const changedFiles = files.map(f => toFilePath(f.path))
  const diffContent = files.map(f => f.hunks).join('\n')
  const dismissedPatterns = loadDismissedPatterns(parsed.dismissed)
    .split('\n')
    .map(l => l.trim())
    .filter(l => l.length > 0 && !l.startsWith('#'))

  const { computeScore } = await import('./risk-scorer.js')
  const result = computeScore({
    loc,
    changedFiles,
    hasJiraKey: parsed.jira,
    dismissedPatterns,
    diffContent,
  })

  const output = {
    score: result.total,
    mode: result.mode,
    reasons: result.reasons,
    breakdown: result.breakdown,
  }
  console.log(JSON.stringify(output, null, 2))
}
```

Also add `import { toFilePath } from './types.js'` to the imports at the top of cli.ts (alongside existing imports), and add the dispatcher case before `// Default: review`:

```typescript
  if (subcommand === 'score') {
    await runScoreCommand(args)
    return
  }
```

- [ ] **Step 2: Verify score subcommand runs**

```bash
cd devflow-engine && node_modules/.bin/tsx src/cli.ts score --help 2>&1 || true
```

Expected: exits with error "unknown flag: --help" or similar (not a crash).

- [ ] **Step 3: Run full test suite**

```bash
cd devflow-engine && npm test
```

Expected: all tests PASS (no regressions).

- [ ] **Step 4: Commit**

```bash
git add devflow-engine/src/cli.ts
git commit -m "feat(engine): add score CLI subcommand"
```

---

## Task 5: Implement lens-assigner.ts (TDD)

**Files:**
- Create: `devflow-engine/src/lens-assigner.ts`
- Create: `devflow-engine/src/lens-assigner.test.ts`

- [ ] **Step 1: Write failing tests**

Create `devflow-engine/src/lens-assigner.test.ts`:

```typescript
import { describe, expect, it } from 'vitest'
import { assignLenses } from './lens-assigner.js'

describe('assignLenses', () => {
  it('fileCount=0 → skipped with reason', () => {
    const r = assignLenses(0)
    expect(r.kind).toBe('skipped')
    if (r.kind === 'skipped') {
      expect(r.reason).toContain('No changed files')
    }
  })

  it('fileCount=29 → full', () => {
    const r = assignLenses(29)
    expect(r.kind).toBe('full')
  })

  it('fileCount=30 → reduced', () => {
    const r = assignLenses(30)
    expect(r.kind).toBe('reduced')
  })

  it('fileCount=50 → reduced', () => {
    const r = assignLenses(50)
    expect(r.kind).toBe('reduced')
  })

  it('fileCount=51 → skipped', () => {
    const r = assignLenses(51)
    expect(r.kind).toBe('skipped')
    if (r.kind === 'skipped') {
      expect(r.reason).toContain('51')
    }
  })

  it('reduced mode → each teammate has exactly 1 lens', () => {
    const r = assignLenses(30)
    expect(r.kind).toBe('reduced')
    if (r.kind === 'reduced') {
      for (const assignment of r.assignments) {
        expect(assignment.lenses).toHaveLength(1)
      }
    }
  })

  it('full mode → correctness teammate has multiple lenses', () => {
    const r = assignLenses(1)
    expect(r.kind).toBe('full')
    if (r.kind === 'full') {
      const correctness = r.assignments.find(a => a.teammate === 'correctness')
      expect(correctness).toBeDefined()
      expect((correctness?.lenses.length ?? 0)).toBeGreaterThan(1)
    }
  })

  it('skip reason includes file count', () => {
    const r = assignLenses(75)
    expect(r.kind).toBe('skipped')
    if (r.kind === 'skipped') {
      expect(r.reason).toContain('75')
    }
  })
})
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
cd devflow-engine && npm test -- lens-assigner
```

Expected: FAIL — "Cannot find module './lens-assigner.js'"

- [ ] **Step 3: Implement lens-assigner.ts**

Create `devflow-engine/src/lens-assigner.ts`:

```typescript
import type { LensCount, Lens, LensAssignmentResult } from './types.js'

export type LensAssignment = {
  readonly teammate: 'correctness' | 'architecture' | 'dx'
  readonly lenses: readonly Lens[]
}

const FULL_ASSIGNMENTS: readonly LensAssignment[] = [
  { teammate: 'correctness', lenses: ['security', 'error-handling'] },
  { teammate: 'architecture', lenses: ['performance', 'database'] },
  { teammate: 'dx', lenses: ['typescript', 'observability'] },
]

const REDUCED_ASSIGNMENTS: readonly LensAssignment[] = [
  { teammate: 'correctness', lenses: ['security'] },
  { teammate: 'architecture', lenses: ['performance'] },
  { teammate: 'dx', lenses: ['typescript'] },
]

export function getLensCount(fileCount: number): LensCount {
  if (fileCount === 0 || fileCount > 50) return 'skip'
  if (fileCount >= 30) return 'reduced'
  return 'full'
}

export function assignLenses(fileCount: number): LensAssignmentResult {
  if (fileCount === 0) {
    return { kind: 'skipped', reason: 'No changed files' }
  }
  if (fileCount > 50) {
    return {
      kind: 'skipped',
      reason: `Large diff (${fileCount} files) — lenses skipped, Hard Rules only`,
    }
  }
  if (fileCount >= 30) {
    return { kind: 'reduced', assignments: REDUCED_ASSIGNMENTS }
  }
  return { kind: 'full', assignments: FULL_ASSIGNMENTS }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
cd devflow-engine && npm test -- lens-assigner
```

Expected: all 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add devflow-engine/src/lens-assigner.ts devflow-engine/src/lens-assigner.test.ts
git commit -m "feat(engine): add lens-assigner"
```

---

## Task 6: Implement mode-resolver.ts (TDD)

**Files:**
- Create: `devflow-engine/src/mode-resolver.ts`
- Create: `devflow-engine/src/mode-resolver.test.ts`

- [ ] **Step 1: Write failing tests**

Create `devflow-engine/src/mode-resolver.test.ts`:

```typescript
import { describe, expect, it } from 'vitest'
import { resolveMode } from './mode-resolver.js'
import { toFilePath } from './types.js'
import type { PRSignals } from './types.js'

function signals(overrides: Partial<{
  loc: number; files: string[]; hasJiraKey: boolean; dismissed: string[]; diff: string
}> = {}): PRSignals {
  return {
    loc: overrides.loc ?? 0,
    changedFiles: (overrides.files ?? []).map(toFilePath),
    hasJiraKey: overrides.hasJiraKey ?? false,
    dismissedPatterns: overrides.dismissed ?? [],
    diffContent: overrides.diff ?? '',
  }
}

describe('explicit flag precedence', () => {
  it('--micro flag → mode=micro, source=explicit-flag', () => {
    const r = resolveMode({ micro: true, quick: false, full: false, focused: null }, signals())
    expect(r.mode).toBe('micro')
    expect(r.source).toBe('explicit-flag')
  })

  it('--quick flag → mode=quick, source=explicit-flag', () => {
    const r = resolveMode({ micro: false, quick: true, full: false, focused: null }, signals())
    expect(r.mode).toBe('quick')
    expect(r.source).toBe('explicit-flag')
  })

  it('--full flag → mode=full, source=explicit-flag', () => {
    const r = resolveMode({ micro: false, quick: false, full: true, focused: null }, signals())
    expect(r.mode).toBe('full')
    expect(r.source).toBe('explicit-flag')
  })

  it('--micro + --full simultaneously → full wins (most conservative)', () => {
    const r = resolveMode({ micro: true, quick: false, full: true, focused: null }, signals())
    expect(r.mode).toBe('full')
    expect(r.source).toBe('explicit-flag')
  })

  it('--micro overrides a high-risk score', () => {
    const r = resolveMode(
      { micro: true, quick: false, full: false, focused: null },
      signals({ loc: 1600, files: ['src/auth/login.ts'] }),  // would score full
    )
    expect(r.mode).toBe('micro')
  })
})

describe('risk-score routing (no flags)', () => {
  const noFlags = { micro: false, quick: false, full: false, focused: null }

  it('low-risk signals → micro, source=risk-score', () => {
    const r = resolveMode(noFlags, signals({ loc: 50 }))
    expect(r.mode).toBe('micro')
    expect(r.source).toBe('risk-score')
  })

  it('medium-risk signals → quick, source=risk-score', () => {
    const r = resolveMode(noFlags, signals({ loc: 300 }))  // locScore=30 → quick
    expect(r.mode).toBe('quick')
    expect(r.source).toBe('risk-score')
  })

  it('high-risk signals → full, source=risk-score', () => {
    const r = resolveMode(noFlags, signals({ loc: 400, files: ['src/auth/login.ts'] }))
    expect(r.mode).toBe('full')
    expect(r.source).toBe('risk-score')
  })
})

describe('specialist triggers', () => {
  const noFlags = { micro: false, quick: false, full: false, focused: null }

  it('test file changed → P1 test-quality-reviewer', () => {
    const r = resolveMode(noFlags, signals({ files: ['src/user.test.ts'] }))
    expect(r.specialistTriggers.some(t => t.type === 'test-quality-reviewer')).toBe(true)
  })

  it('controller + test file → P1 blocks P2 (only test-quality-reviewer)', () => {
    const r = resolveMode(noFlags, signals({ files: ['src/user.test.ts', 'src/user.controller.ts'] }))
    const types = r.specialistTriggers.map(t => t.type)
    expect(types).toContain('test-quality-reviewer')
    expect(types).not.toContain('api-contract-auditor')
  })

  it('P4: try/catch in diff → silent-failure-hunter added independently', () => {
    const r = resolveMode(noFlags, signals({ diff: '+  try { await foo() } catch (e) { }' }))
    expect(r.specialistTriggers.some(t => t.type === 'silent-failure-hunter')).toBe(true)
  })

  it('P4 and P1 can coexist (P4 is independent)', () => {
    const r = resolveMode(noFlags, signals({
      files: ['src/user.test.ts'],
      diff: '+  try { await save() } catch (e) { }',
    }))
    const types = r.specialistTriggers.map(t => t.type)
    expect(types).toContain('test-quality-reviewer')
    expect(types).toContain('silent-failure-hunter')
  })
})

describe('lens count', () => {
  const noFlags = { micro: false, quick: false, full: false, focused: null }

  it('small PR → full lenses', () => {
    const r = resolveMode(noFlags, signals({ files: Array(5).fill('src/foo.ts') }))
    expect(r.lensCount).toBe('full')
  })

  it('medium PR (30–50 files) → reduced lenses', () => {
    const r = resolveMode(noFlags, signals({ files: Array(35).fill('src/foo.ts') }))
    expect(r.lensCount).toBe('reduced')
  })

  it('large PR (>50 files) → skip lenses', () => {
    const r = resolveMode(noFlags, signals({ files: Array(55).fill('src/foo.ts') }))
    expect(r.lensCount).toBe('skip')
  })
})
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
cd devflow-engine && npm test -- mode-resolver
```

Expected: FAIL — "Cannot find module './mode-resolver.js'"

- [ ] **Step 3: Implement mode-resolver.ts**

Create `devflow-engine/src/mode-resolver.ts`:

```typescript
import type { PRSignals, ReviewMode, LensCount, SpecialistTrigger, SpecialistType } from './types.js'
import { computeScore } from './risk-scorer.js'
import { getLensCount } from './lens-assigner.js'

export type CLIFlags = {
  readonly micro: boolean
  readonly quick: boolean
  readonly full: boolean
  readonly focused: string | null
}

export type ModeResolution = {
  readonly mode: ReviewMode | 'focused'
  readonly source: 'explicit-flag' | 'risk-score'
  readonly specialistTriggers: readonly SpecialistTrigger[]
  readonly lensCount: LensCount
  readonly score: number
  readonly reasons: readonly string[]
}

// ─── Specialist detection ─────────────────────────────────────────────────────

const FOCUSED_AREA_MAP: Record<string, SpecialistType> = {
  errors: 'silent-failure-hunter',
  types: 'type-design-analyzer',
  tests: 'test-quality-reviewer',
  api: 'api-contract-auditor',
  migrations: 'migration-reviewer',
}

function detectSpecialists(files: readonly string[], diffContent: string): readonly SpecialistTrigger[] {
  const triggers: SpecialistTrigger[] = []

  // P1–P3: first match wins (primary specialist)
  let primaryAdded = false
  if (!primaryAdded && files.some(f => /\.(test|spec)\.[jt]sx?$/.test(f))) {
    triggers.push({ type: 'test-quality-reviewer', priority: 1 })
    primaryAdded = true
  }
  if (!primaryAdded && files.some(f => /\.(controller|router|handler|route)\.[jt]sx?$|\/(controllers?|routes?|handlers?)\//.test(f))) {
    triggers.push({ type: 'api-contract-auditor', priority: 2 })
    primaryAdded = true
  }
  if (!primaryAdded && files.some(f => /\.migration\.[jt]sx?$|\/migrations\//.test(f))) {
    triggers.push({ type: 'migration-reviewer', priority: 3 })
    primaryAdded = true
  }

  // P4–P5: independent
  if (/\btry\s*\{|\.catch\s*\(|[\w\])\?\.|\?\?/.test(diffContent)) {
    triggers.push({ type: 'silent-failure-hunter', priority: 4 })
  }
  if (files.some(f => /\.(interface|types?)\.[jt]sx?$/.test(f))) {
    triggers.push({ type: 'type-design-analyzer', priority: 5 })
  }

  return triggers
}

// ─── Public API ───────────────────────────────────────────────────────────────

export function resolveMode(flags: CLIFlags, signals: PRSignals): ModeResolution {
  const fileStrs = signals.changedFiles.map(String)
  const lensCount = getLensCount(fileStrs.length)
  const specialistTriggers = detectSpecialists(fileStrs, signals.diffContent)

  // Focused mode: bypass main reviewers, single specialist
  if (flags.focused !== null) {
    const specialistType = FOCUSED_AREA_MAP[flags.focused]
    return {
      mode: 'focused',
      source: 'explicit-flag',
      specialistTriggers: specialistType !== undefined
        ? [{ type: specialistType, priority: 1 as const }]
        : [],
      lensCount,
      score: 0,
      reasons: [`--focused ${flags.focused}`],
    }
  }

  // --full + --micro conflict → full wins (most conservative)
  if (flags.full) {
    return { mode: 'full', source: 'explicit-flag', specialistTriggers, lensCount, score: 0, reasons: ['--full flag'] }
  }
  if (flags.quick) {
    return { mode: 'quick', source: 'explicit-flag', specialistTriggers, lensCount, score: 0, reasons: ['--quick flag'] }
  }
  if (flags.micro) {
    return { mode: 'micro', source: 'explicit-flag', specialistTriggers, lensCount, score: 0, reasons: ['--micro flag'] }
  }

  // No explicit flag → use risk score
  const risk = computeScore(signals)
  return {
    mode: risk.mode,
    source: 'risk-score',
    specialistTriggers,
    lensCount,
    score: risk.total,
    reasons: risk.reasons,
  }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
cd devflow-engine && npm test -- mode-resolver
```

Expected: all tests PASS.

- [ ] **Step 5: Run full test suite (no regressions)**

```bash
cd devflow-engine && npm test
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add devflow-engine/src/mode-resolver.ts devflow-engine/src/mode-resolver.test.ts
git commit -m "feat(engine): add mode-resolver"
```

---

## Task 7: Add `resolve` CLI subcommand

**Files:**
- Modify: `devflow-engine/src/cli.ts`

- [ ] **Step 1: Add resolve subcommand to cli.ts**

Add the following block before the `// ─── main dispatcher ───` section:

```typescript
// ─── resolve subcommand ───────────────────────────────────────────────────────

interface ParsedResolveArgs {
  pr: number | undefined
  dismissed: string | undefined
  jira: boolean
  micro: boolean
  quick: boolean
  full: boolean
  focused: string | undefined
}

function parseResolveArgs(args: string[]): ParsedResolveArgs {
  return parseFlags(args, [
    { flag: '--pr', field: 'pr', type: 'positiveInt', required: true, errorPrefix: '[engine-resolve]', onError: 'exit' },
    { flag: '--dismissed', field: 'dismissed', type: 'string', errorPrefix: '[engine-resolve]' },
    { flag: '--jira', field: 'jira', type: 'boolean', errorPrefix: '[engine-resolve]' },
    { flag: '--micro', field: 'micro', type: 'boolean', errorPrefix: '[engine-resolve]' },
    { flag: '--quick', field: 'quick', type: 'boolean', errorPrefix: '[engine-resolve]' },
    { flag: '--full', field: 'full', type: 'boolean', errorPrefix: '[engine-resolve]' },
    { flag: '--focused', field: 'focused', type: 'string', errorPrefix: '[engine-resolve]' },
  ], {
    pr: undefined as number | undefined,
    dismissed: undefined as string | undefined,
    jira: false as boolean,
    micro: false as boolean,
    quick: false as boolean,
    full: false as boolean,
    focused: undefined as string | undefined,
  })
}

async function runResolveCommand(args: string[]): Promise<void> {
  const parsed = parseResolveArgs(args)
  if (parsed.pr === undefined) {
    console.error('[engine-resolve] --pr is required')
    process.exit(1)
  }

  const files = readPrDiff(parsed.pr)
  const loc = files.reduce((sum, f) => sum + f.diffLineCount, 0)
  const changedFiles = files.map(f => toFilePath(f.path))
  const diffContent = files.map(f => f.hunks).join('\n')
  const dismissedPatterns = loadDismissedPatterns(parsed.dismissed)
    .split('\n')
    .map(l => l.trim())
    .filter(l => l.length > 0 && !l.startsWith('#'))

  const signals: import('./types.js').PRSignals = {
    loc,
    changedFiles,
    hasJiraKey: parsed.jira,
    dismissedPatterns,
    diffContent,
  }

  const { resolveMode } = await import('./mode-resolver.js')
  const result = resolveMode(
    {
      micro: parsed.micro,
      quick: parsed.quick,
      full: parsed.full,
      focused: parsed.focused ?? null,
    },
    signals,
  )

  console.log(JSON.stringify(result, null, 2))
}
```

Add to the main dispatcher (before `// Default: review`):

```typescript
  if (subcommand === 'resolve') {
    await runResolveCommand(args)
    return
  }
```

- [ ] **Step 2: Run full test suite**

```bash
cd devflow-engine && npm test
```

Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add devflow-engine/src/cli.ts
git commit -m "feat(engine): add resolve CLI subcommand"
```

---

## Task 8: Update skills/review/references/phase-3.md to use engine resolve

**Files:**
- Modify: `skills/review/references/phase-3.md`

- [ ] **Step 1: Read the current SDK bash block in phase-3.md**

```bash
grep -n "ENGINE_DIR\|devflow-engine\|sdk_result\|sdk_exit" skills/review/references/phase-3.md | head -20
```

Note the exact line numbers of the block to replace (after Task 1 rename, it will already say `ENGINE_DIR` and `devflow-engine`).

- [ ] **Step 2: Replace the SDK-only bash block with the resolve integration block**

Find the section that starts with:
```
if [ -d "$ENGINE_DIR" ] && [ -d "$ENGINE_DIR/node_modules" ]; then
```

Replace the entire bash block (from `ENGINE_DIR=` through `fi`) and the prose auto-escalation block above it with the bash block from the spec (Section 6):

```bash
ENGINE_DIR="${CLAUDE_SKILL_DIR}/../../devflow-engine"

if [ -d "$ENGINE_DIR" ] && [ -d "$ENGINE_DIR/node_modules" ]; then
  # Build resolve args
  RESOLVE_ARGS="--pr $0 --output json"
  DISMISSED_FILE="$(bash "${CLAUDE_SKILL_DIR}/../../scripts/artifact-dir.sh" review)/review-dismissed.md"
  if [ -f "$DISMISSED_FILE" ]; then
    RESOLVE_ARGS="$RESOLVE_ARGS --dismissed $DISMISSED_FILE"
  fi
  # Check for Jira key in arguments
  echo "$ARGUMENTS" | grep -qE '[A-Z]+-[0-9]+' && RESOLVE_ARGS="$RESOLVE_ARGS --jira"
  # Pass explicit mode flags from user args
  echo "$ARGUMENTS" | grep -q '\-\-micro' && RESOLVE_ARGS="$RESOLVE_ARGS --micro"
  echo "$ARGUMENTS" | grep -q '\-\-quick' && RESOLVE_ARGS="$RESOLVE_ARGS --quick"
  echo "$ARGUMENTS" | grep -q '\-\-full'  && RESOLVE_ARGS="$RESOLVE_ARGS --full"
  focused_area=$(echo "$ARGUMENTS" | grep -oP '(?<=--focused )\S+' || true)
  [ -n "$focused_area" ] && RESOLVE_ARGS="$RESOLVE_ARGS --focused $focused_area"

  resolve_result=$(cd "$ENGINE_DIR" && node_modules/.bin/tsx src/cli.ts resolve $RESOLVE_ARGS 2>&1)
  resolve_exit=$?

  _extract_mode() {
    if command -v jq >/dev/null 2>&1; then
      echo "$1" | jq -r '.mode' 2>/dev/null
    else
      echo "$1" | node -e "process.stdout.write(JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).mode)" 2>/dev/null
    fi
  }

  if [ "$resolve_exit" -eq 0 ]; then
    resolved_mode=$(_extract_mode "$resolve_result")
    echo "Review Engine: mode=$resolved_mode score=$(echo "$resolve_result" | jq -r '.score // "?"' 2>/dev/null)"
  else
    echo "devflow-engine resolve failed (exit $resolve_exit) — falling back to rule-based escalation"
    resolve_exit=1
  fi
else
  echo "devflow-engine not available — falling back to rule-based escalation"
  resolve_exit=1
fi

# Fallback: if engine unavailable or failed, use rule-based prose escalation (existing logic below)
```

- [ ] **Step 3: Update the prose auto-escalation section**

The prose auto-escalation section that follows should remain as a fallback. Add a guard at the top:

```
**If `$resolve_exit` = 0:** Use `$resolved_mode` directly as the review mode — skip the rule-based escalation below.

**If `$resolve_exit` ≠ 0:** Apply rule-based escalation:
```

Then leave the existing Force `--full` / Use `--quick` / Force SDK-only prose blocks intact as fallback.

- [ ] **Step 4: Run QA lint check**

```bash
npx markdownlint-cli2 "skills/review/references/phase-3.md"
```

Expected: no errors. Fix any markdown lint issues.

- [ ] **Step 5: Commit**

```bash
git add skills/review/references/phase-3.md
git commit -m "feat(review): integrate devflow-engine resolve into phase-3 auto-escalation"
```

---

## Task 9: Run full QA

**Files:** Read-only

- [ ] **Step 1: Run devflow-engine test suite**

```bash
cd devflow-engine && npm test
```

Expected: all tests PASS. Fix any failures before proceeding.

- [ ] **Step 2: Run full repo QA gates**

```bash
bash scripts/qa-check.sh
```

Expected: all 13 gates pass. If markdownlint fails on any skill file, fix the markdown and recommit.

- [ ] **Step 3: Verify engine CLI smoke test**

```bash
cd devflow-engine && node_modules/.bin/tsx src/cli.ts 2>&1 | head -5
```

Expected: usage hint or "unknown subcommand" — not a crash.

- [ ] **Step 4: Final commit if any QA fixes were needed**

```bash
git add -A
git commit -m "fix: QA gate fixes post devflow-engine migration"
```

If no fixes needed, skip this step.
