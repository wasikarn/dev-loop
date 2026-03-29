# Prompt E: Dead Config Cleanup + Effort Levels

**Opportunity:** ลบ 4 dead fields จาก config, ทำให้ `triage()` อ่านค่าจาก config แทน hardcode, implement `effort` เป็น lever จริงๆ
**Impact:** Config กลายเป็น source of truth — ไม่มี field ที่บอกค่าหนึ่งแต่ code ทำอีกอย่าง + `--effort low` ทำให้ review ถูกลง ~50%
**Files ที่แก้:**

- `devflow-sdk/src/config.ts` — ลบ dead fields, เพิ่ม effort presets, rename thresholds
- `devflow-sdk/src/review/triage.ts` — รับ thresholds จาก caller แทน hardcode
- `devflow-sdk/src/cli.ts` — เพิ่ม `--effort` flag ใน review parser, wire เข้า `resolveConfig()`
- `devflow-sdk/smoke-test.ts` — เพิ่ม tests สำหรับ effort presets และ config-driven triage

---

## Dead Fields Analysis

| Field | สถานะ | ควรทำ |
| --- | --- | --- |
| `confidenceThreshold: 80` | ถูกแทนที่ด้วย `ROLE_CONFIDENCE` ใน consolidator.ts — ไม่มีที่ไหน read แล้ว | **ลบออก** |
| `maxTurnsFalsification: 5` | falsifier migrate เป็น `messages.create()` แล้ว — ไม่มี loop | **ลบออก** |
| `autoPassConfidence: 90` | hardcode `90` ใน triage.ts โดยตรง ไม่อ่านจาก config | **Rename → autoPassThreshold, wire เข้า triage** |
| `autoDropMaxConfidence: 79` | hardcode `79` ใน triage.ts โดยตรง ไม่อ่านจาก config | **Rename → autoDropThreshold, wire เข้า triage** |
| `effort: 'high'` | stored แต่ไม่มี code ไหน check ค่านี้เลย | **Implement เป็น effort presets** |

---

## Step 1: config.ts — ลบ dead fields, เพิ่ม effort presets

```typescript
// ก่อน
export const DEFAULT_CONFIG = {
  effort: 'high' as const,
  maxBudgetPerReviewer: 0.30,
  maxBudgetFalsification: 0.15,
  maxBudgetVerification: 0.10,
  maxTurnsReviewer: 20,
  maxTurnsFalsification: 5,    // ← DEAD: ลบ
  model: 'sonnet' as ModelName,
  confidenceThreshold: 80,     // ← DEAD: ลบ
  autoPassConfidence: 90,      // ← rename เป็น autoPassThreshold
  autoDropMaxConfidence: 79,   // ← rename เป็น autoDropThreshold
  patternCapCount: 3,
  signalThreshold: 0.6,
}

// หลัง
export const DEFAULT_CONFIG = {
  effort: 'high' as const,
  maxBudgetPerReviewer: 0.30,
  maxBudgetFalsification: 0.15,
  maxBudgetVerification: 0.10,
  maxTurnsReviewer: 20,
  model: 'sonnet' as ModelName,
  autoPassThreshold: 90,
  autoDropThreshold: 79,
  patternCapCount: 3,
  signalThreshold: 0.6,
}
```

เพิ่ม effort preset map หลัง `DEFAULT_CONFIG`:

```typescript
// Effort controls model selection + turn budgets + spend limits
// User overrides (--budget, explicit model flags) always take precedence over preset
const EFFORT_PRESETS: Record<EffortLevel, {
  model: ModelName
  maxTurnsReviewer: number
  maxBudgetPerReviewer: number
  maxBudgetFalsification: number
}> = {
  low:    { model: 'haiku',  maxTurnsReviewer: 8,  maxBudgetPerReviewer: 0.10, maxBudgetFalsification: 0.05 },
  medium: { model: 'sonnet', maxTurnsReviewer: 15, maxBudgetPerReviewer: 0.20, maxBudgetFalsification: 0.10 },
  high:   { model: 'sonnet', maxTurnsReviewer: 20, maxBudgetPerReviewer: 0.30, maxBudgetFalsification: 0.15 },
}
```

อัปเดต `ResolvedConfig` interface:

```typescript
export interface ResolvedConfig {
  effort: EffortLevel
  maxBudgetPerReviewer: number
  maxBudgetFalsification: number
  maxBudgetVerification: number
  maxTurnsReviewer: number
  // maxTurnsFalsification REMOVED — falsifier is a single messages.create() call
  model: ModelName
  // confidenceThreshold REMOVED — replaced by per-role ROLE_CONFIDENCE in consolidator.ts
  autoPassThreshold: number   // was: autoPassConfidence
  autoDropThreshold: number   // was: autoDropMaxConfidence
  patternCapCount: number
  signalThreshold: number
  hardRulesPath?: string
  noFalsification?: boolean
}
```

อัปเดต `resolveConfig()` ให้ apply effort preset ก่อน user overrides:

```typescript
export function resolveConfig(userConfig?: ReviewConfig): ResolvedConfig {
  const effort = userConfig?.effort ?? DEFAULT_CONFIG.effort
  const preset = EFFORT_PRESETS[effort]

  return {
    ...DEFAULT_CONFIG,
    ...preset,                          // effort preset — model, turns, budgets
    effort,
    ...(userConfig?.budgetUsd && {     // user budget override takes precedence
      maxBudgetPerReviewer: (userConfig.budgetUsd * 0.8) / 3,
      maxBudgetFalsification: userConfig.budgetUsd * 0.2,
      maxBudgetVerification: userConfig.budgetUsd,
    }),
    ...(userConfig?.hardRulesPath && { hardRulesPath: userConfig.hardRulesPath }),
    ...(userConfig?.noFalsification !== undefined && { noFalsification: userConfig.noFalsification }),
  }
}
```

เพิ่ม `effort?: EffortLevel` ใน `ReviewConfig` interface:

```typescript
export interface ReviewConfig {
  effort?: EffortLevel
  budgetUsd?: number
  hardRulesPath?: string
  noFalsification?: boolean
}
```

---

## Step 2: triage.ts — รับ thresholds จาก caller

```typescript
// ก่อน
export function triage(findings: Finding[]): TriagedFindings {
  return {
    autoPass: findings.filter(f => f.isHardRule && f.confidence >= 90),
    autoDrop: findings.filter(f => !f.isHardRule && f.severity === 'info' && f.confidence <= 79),
    mustFalsify: findings.filter(
      f => !(f.isHardRule && f.confidence >= 90) && !(!f.isHardRule && f.severity === 'info' && f.confidence <= 79)
    ),
  }
}

// หลัง
export function triage(findings: Finding[], params?: {
  autoPassThreshold?: number   // default 90
  autoDropThreshold?: number   // default 79
}): TriagedFindings {
  const autoPassAt = params?.autoPassThreshold ?? 90
  const autoDropAt = params?.autoDropThreshold ?? 79
  return {
    autoPass: findings.filter(f => f.isHardRule && f.confidence >= autoPassAt),
    autoDrop: findings.filter(f => !f.isHardRule && f.severity === 'info' && f.confidence <= autoDropAt),
    mustFalsify: findings.filter(
      f => !(f.isHardRule && f.confidence >= autoPassAt) && !(!f.isHardRule && f.severity === 'info' && f.confidence <= autoDropAt)
    ),
  }
}
```

---

## Step 3: cli.ts — wire thresholds + เพิ่ม `--effort` flag

### 3a. ParsedReviewArgs เพิ่ม effort field

```typescript
interface ParsedReviewArgs {
  pr: number | undefined
  branch: string | undefined
  baseBranch: string | undefined
  output: 'json' | 'markdown'
  falsification: boolean
  hardRulesPath: string | undefined
  budget: number | undefined
  dismissedPatternsPath: string | undefined
  effort: EffortLevel | undefined   // ← เพิ่ม
}
```

### 3b. parseArgs() — เพิ่ม `--effort` flag

เพิ่ม branch ใน for loop ของ `parseArgs()`:

```typescript
} else if (arg === '--effort') {
  if (next === undefined) {
    console.error('[sdk-review] --effort requires a value: low|medium|high')
    process.exit(1)
  }
  if (next !== 'low' && next !== 'medium' && next !== 'high') {
    console.error(`[sdk-review] --effort must be low|medium|high, got: ${next}`)
    process.exit(1)
  }
  result.effort = next
  i++
}
```

### 3c. runReviewCommand() — ส่ง effort + thresholds เข้า resolveConfig + triage

```typescript
// ก่อน
const config = resolveConfig({
  ...(parsed.budget !== undefined && { budgetUsd: parsed.budget }),
  ...(parsed.hardRulesPath !== undefined && { hardRulesPath: parsed.hardRulesPath }),
  noFalsification: !parsed.falsification,
})

// หลัง
const config = resolveConfig({
  ...(parsed.effort !== undefined && { effort: parsed.effort }),
  ...(parsed.budget !== undefined && { budgetUsd: parsed.budget }),
  ...(parsed.hardRulesPath !== undefined && { hardRulesPath: parsed.hardRulesPath }),
  noFalsification: !parsed.falsification,
})
```

```typescript
// ก่อน
const { autoPass, autoDrop: _autoDrop, mustFalsify } = triage(perReviewer.flatMap(r => r.findings))

// หลัง
const { autoPass, autoDrop: _autoDrop, mustFalsify } = triage(
  perReviewer.flatMap(r => r.findings),
  { autoPassThreshold: config.autoPassThreshold, autoDropThreshold: config.autoDropThreshold }
)
```

---

## Smoke Tests เพิ่ม

```typescript
test('resolveConfig effort=low → haiku model + 8 turns + low budget', () => {
  const cfg = resolveConfig({ effort: 'low' })
  assert(cfg.model === 'haiku', `expected haiku, got ${cfg.model}`)
  assert(cfg.maxTurnsReviewer === 8, `expected 8, got ${cfg.maxTurnsReviewer}`)
  assert(cfg.maxBudgetPerReviewer === 0.10, `expected 0.10, got ${cfg.maxBudgetPerReviewer}`)
})

test('resolveConfig effort=low + budgetUsd=2.0 → budget overrides preset', () => {
  const cfg = resolveConfig({ effort: 'low', budgetUsd: 2.0 })
  assert(cfg.model === 'haiku', `effort model should stick: ${cfg.model}`)
  assert(cfg.maxBudgetPerReviewer > 0.10, `user budget should override: ${cfg.maxBudgetPerReviewer}`)
})

test('triage uses custom autoPassThreshold', () => {
  const finding: Finding = { severity: 'critical', rule: 'HR-1', file: 'a.ts', line: 1, confidence: 88, issue: 'x', fix: 'y', isHardRule: true }
  const { autoPass, mustFalsify } = triage([finding], { autoPassThreshold: 85 })
  assert(autoPass.length === 1, `conf=88 >= threshold=85 should autoPass`)
  const { autoPass: ap2 } = triage([finding], { autoPassThreshold: 90 })
  assert(ap2.length === 0, `conf=88 < threshold=90 should not autoPass`)
})

test('resolveConfig has no confidenceThreshold or maxTurnsFalsification field', () => {
  const cfg = resolveConfig()
  assert(!('confidenceThreshold' in cfg), 'confidenceThreshold should be removed')
  assert(!('maxTurnsFalsification' in cfg), 'maxTurnsFalsification should be removed')
})
```

---

## Verify

```bash
cd devflow-sdk && npx tsc --noEmit && npx tsx smoke-test.ts
```

ต้องไม่มี TypeScript error และ smoke tests ผ่านทั้งหมด
