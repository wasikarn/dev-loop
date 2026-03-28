# Prompt G: Structural Fixes — crossDomain, Verdict Safety, Arg Parser

**Opportunity:** แก้ 3 structural issues ที่พบหลัง Prompt A-D: ghost field, indexing fragility, copy-paste parsers
**Impact:** ลบ dead code (~10 lines), ทำ verdict matching ปลอดภัยกว่า (key-based แทน index), ลด cli.ts ~200 lines
**Files ที่แก้:**

- `anvil-sdk/src/review/schemas/finding.ts` — ลบ `crossDomain`
- `anvil-sdk/src/review/schemas/verdict.ts` — เพิ่ม `findingKey`
- `anvil-sdk/src/review/agents/falsifier.ts` — เพิ่ม key ใน findings summary + prompt
- `anvil-sdk/src/review/prompts/falsifier.ts` — เพิ่ม `findingKey` ใน output spec
- `anvil-sdk/src/review/prompts/shared-rules.ts` — ลบ `crossDomain` field จาก output spec
- `anvil-sdk/src/review/consolidator.ts` — `applyVerdicts()` ใช้ key-based matching
- `anvil-sdk/src/review/output.ts` — ลบ `crossDomain` rendering
- `anvil-sdk/src/cli.ts` — extract `parseFlags()`, dedup 5 parsers
- `anvil-sdk/smoke-test.ts` — เพิ่ม tests สำหรับ verdict key safety + parser

**ขึ้นอยู่กับ:** ควร execute หลัง Prompt E (ลด conflicts ใน cli.ts)

---

## Fix 1: crossDomain — Ghost Field

`crossDomain` ถูก render ใน `output.ts:formatFinding()` แต่ reviewer prompt บอกให้ใส่ข้อมูลนี้ใน `issue` text (`[CROSS-DOMAIN: domain]`) แทน ในทางปฏิบัติ model ไม่ populate separate field นี้ — มันฝังใน issue string ล้วน

**การตัดสินใจ:** ลบ field ออกจาก schema/output เพื่อลด noise ใน API response คง `[CROSS-DOMAIN: X]` instruction ใน `shared-rules.ts` ไว้เพราะข้อมูลนั้นยังมีค่า — แค่เปลี่ยนให้ model ฝังใน `issue` string เท่านั้น

### finding.ts

```typescript
// ก่อน
export const FindingSchema = z.object({
  severity: z.enum(['critical', 'warning', 'info']),
  rule: z.string(),
  file: z.string(),
  line: z.number().int().nullable(),
  confidence: z.number().int().min(0).max(100),
  issue: z.string(),
  fix: z.string(),
  isHardRule: z.boolean(),
  crossDomain: z.string().optional(),  // ← ลบ
})

// หลัง — ลบ crossDomain บรรทัดเดียว
```

ลบออกจาก `findingResultJsonSchema` ด้วย:

```typescript
// ก่อน (ใน items.properties)
crossDomain: { type: 'string' },

// หลัง — ลบบรรทัดนั้นออก
```

### output.ts

```typescript
// ก่อน
function formatFinding(f: ConsolidatedFinding): string {
  const lines: string[] = [...]
  if (f.patternNote) { lines.push(`**Pattern:** ${f.patternNote}`) }
  if (f.crossDomain) { lines.push(`> Cross-domain: ${f.crossDomain}`) }  // ← ลบ
  return lines.join('\n')
}

// หลัง — ลบ crossDomain block
```

### shared-rules.ts

```typescript
// ก่อน (ใน OUTPUT section)
"findings" — array of issues:
[{
  ...
  "crossDomain": "<domain>" (optional)  // ← ลบบรรทัดนี้
}]

// คง instruction ไว้:
// "If you find an issue outside your primary domain:
// - Mark as: [CROSS-DOMAIN: {domain}] in the finding
// - Set severity to: Warning (never Critical)"
```

---

## Fix 2: Verdict Key Safety

### ปัญหาปัจจุบัน

`applyVerdicts()` ใช้ `v.findingIndex` เป็น array position ใน flattened mustFalsify array:

```typescript
// consolidator.ts
function applyVerdicts(findings: Finding[], verdicts: Verdict[]): Finding[] {
  const verdictByIndex = new Map<number, Verdict>()
  for (const v of verdicts) {
    verdictByIndex.set(v.findingIndex, v)  // ← index-based
  }
  ...
}
```

ถ้า flatMap order ใน `cli.ts` ต่างจาก order ที่ falsifier รับไป → verdicts apply ผิด finding โดยไม่ error

### แก้ไข: เพิ่ม `findingKey` ใน verdict output

#### verdict.ts

```typescript
export const VerdictSchema = z.object({
  findingIndex: z.number().int().min(0),  // keep for backward compat
  findingKey: z.string().optional(),      // ← เพิ่ม: "file:line:rule"
  originalSummary: z.string(),
  verdict: z.enum(['SUSTAINED', 'DOWNGRADED', 'REJECTED']),
  newSeverity: z.enum(['critical', 'warning', 'info']).optional(),
  rationale: z.string(),
})
```

เพิ่มใน `verdictResultJsonSchema`:

```typescript
// ใน verdicts[*].properties
findingKey: { type: 'string' },    // ← เพิ่ม (optional — ไม่ใส่ใน required)
```

#### falsifier.ts — เพิ่ม key ใน findings summary

```typescript
// ก่อน
const findingsSummary = params.findings
  .map((f, i) => `[${i}] ${f.severity} | ${f.rule} | ${f.file}:${f.line ?? '?'} — ${f.issue}`)
  .join('\n')

// หลัง — เพิ่ม key ต่อท้ายแต่ละ line
const findingsSummary = params.findings
  .map((f, i) => {
    const key = `${f.file}:${f.line ?? 'null'}:${f.rule}`
    return `[${i}] ${f.severity} | ${f.rule} | ${f.file}:${f.line ?? '?'} — ${f.issue} [key:${key}]`
  })
  .join('\n')
```

#### prompts/falsifier.ts — เพิ่ม `findingKey` ใน output spec

```typescript
// ใน JSON object ที่ prompt บอกให้ return — เพิ่ม field นี้:
// "findingKey": "<key from [key:...] in input>",  (copy exactly as provided)
```

เพิ่มหลัง `"findingIndex"` ใน JSON example:

```json
"findingKey": "src/user.ts:42:no-null-check",
```

#### consolidator.ts — key-based matching with index fallback

```typescript
function applyVerdicts(findings: Finding[], verdicts: Verdict[]): Finding[] {
  // Build lookup by key (primary) and by index (fallback)
  const verdictByKey = new Map<string, Verdict>()
  const verdictByIndex = new Map<number, Verdict>()
  for (const v of verdicts) {
    if (v.findingKey !== undefined) verdictByKey.set(v.findingKey, v)
    verdictByIndex.set(v.findingIndex, v)
  }

  const result: Finding[] = []
  for (let i = 0; i < findings.length; i++) {
    const finding = findings[i]
    if (finding === undefined) continue

    // Key-based lookup preferred; index fallback if key not present
    const key = `${finding.file}:${finding.line ?? 'null'}:${finding.rule}`
    const verdict = verdictByKey.get(key) ?? verdictByIndex.get(i)

    if (verdict === undefined || verdict.verdict === 'SUSTAINED') {
      result.push(finding)
    } else if (verdict.verdict === 'DOWNGRADED') {
      result.push({ ...finding, severity: verdict.newSeverity ?? finding.severity })
    }
    // REJECTED: skip
  }
  return result
}
```

---

## Fix 3: Arg Parser Deduplication

### ปัญหาปัจจุบัน

cli.ts มี 5 parsers ที่ copy-paste โครงสร้างเดียวกัน:

```typescript
// โครงสร้างนี้ซ้ำ 5 ครั้ง:
for (let i = 0; i < args.length; i++) {
  const arg = args[i]
  if (arg === undefined) continue
  const next = args[i + 1]
  if (arg === '--<flag>') {
    if (next === undefined) { console.error('...'); process.exit(1) }
    result.<field> = next; i++
  }
}
```

ยิ่งกว่านั้น behavior ของ `--budget` ต่างกัน: `parseArgs` exit(1), `parsePlanChallengeArgs` silently skip, `parseFixIntentVerifyArgs` console.warn

### แก้ไข: Generic parseFlags()

เพิ่มก่อน parser functions:

```typescript
type FlagType = 'string' | 'positiveInt' | 'positiveFloat' | 'boolean' | 'enum'

interface FlagSpec {
  flag: string                    // e.g., '--pr'
  field: string                   // key ใน result object
  type: FlagType
  enum?: string[]                 // ถ้า type === 'enum'
  required?: boolean              // default false
  errorPrefix: string             // e.g., '[sdk-review]'
  onError?: 'exit' | 'warn'      // default 'exit' ถ้า required, 'warn' ถ้าไม่ required
}

function parseFlags<T extends Record<string, unknown>>(
  args: string[],
  specs: FlagSpec[],
  defaults: T
): T {
  const result = { ...defaults }
  const specByFlag = new Map(specs.map(s => [s.flag, s]))

  for (let i = 0; i < args.length; i++) {
    const arg = args[i]
    if (arg === undefined) continue
    const spec = specByFlag.get(arg)
    if (spec === undefined) continue

    if (spec.type === 'boolean') {
      ;(result as Record<string, unknown>)[spec.field] = true
      continue
    }

    const next = args[i + 1]
    if (next === undefined || next.startsWith('--')) {
      const msg = `${spec.errorPrefix} ${spec.flag} requires a value`
      if (spec.required || spec.onError === 'exit') {
        console.error(msg); process.exit(1)
      } else {
        console.warn(msg + ' — using default')
      }
      continue
    }

    let parsed: unknown
    if (spec.type === 'string' || (spec.type === 'enum' && spec.enum?.includes(next))) {
      parsed = next
    } else if (spec.type === 'enum') {
      const msg = `${spec.errorPrefix} ${spec.flag} must be ${spec.enum?.join('|')}, got: ${next}`
      if (spec.required || spec.onError === 'exit') { console.error(msg); process.exit(1) }
      else { console.warn(msg + ' — using default'); continue }
    } else if (spec.type === 'positiveInt') {
      const n = parseInt(next, 10)
      if (Number.isNaN(n) || n <= 0) {
        const msg = `${spec.errorPrefix} ${spec.flag} must be a positive integer, got: ${next}`
        if (spec.required || spec.onError === 'exit') { console.error(msg); process.exit(1) }
        else { console.warn(msg + ' — using default'); continue }
      }
      parsed = n
    } else if (spec.type === 'positiveFloat') {
      const n = parseFloat(next)
      if (Number.isNaN(n) || n <= 0) {
        const msg = `${spec.errorPrefix} ${spec.flag} must be a positive number, got: ${next}`
        console.warn(msg + ' — using default'); continue
      }
      parsed = n
    }

    ;(result as Record<string, unknown>)[spec.field] = parsed
    i++
  }
  return result
}
```

### ตัวอย่างการ rewrite parseFixIntentVerifyArgs

```typescript
// ก่อน — ~40 lines
export function parseFixIntentVerifyArgs(args: string[]): ParsedFixIntentVerifyArgs {
  const result: ParsedFixIntentVerifyArgs = { pr: undefined, triageFile: undefined, budget: undefined }
  for (let i = 0; i < args.length; i++) { ... long manual loop ... }
  return result
}

// หลัง — ~10 lines
export function parseFixIntentVerifyArgs(args: string[]): ParsedFixIntentVerifyArgs {
  return parseFlags(args, [
    { flag: '--pr', field: 'pr', type: 'positiveInt', required: true, errorPrefix: '[sdk-fix-intent-verify]' },
    { flag: '--triage-file', field: 'triageFile', type: 'string', required: true, errorPrefix: '[sdk-fix-intent-verify]' },
    { flag: '--budget', field: 'budget', type: 'positiveFloat', errorPrefix: '[sdk-fix-intent-verify]' },
  ], { pr: undefined, triageFile: undefined, budget: undefined })
}
```

Rewrite ทั้ง 5 parsers ด้วย pattern เดียวกัน ตรวจสอบว่า behavior ยังเหมือนเดิมทุก flag

---

## Smoke Tests เพิ่ม

```typescript
test('applyVerdicts uses findingKey when present — order-independent', () => {
  const findings: Finding[] = [
    { severity: 'warning', rule: 'R1', file: 'a.ts', line: 10, confidence: 80, issue: 'x', fix: 'y', isHardRule: false },
    { severity: 'critical', rule: 'R2', file: 'b.ts', line: 20, confidence: 90, issue: 'z', fix: 'w', isHardRule: false },
  ]
  // Verdict with findingKey pointing to R2, but findingIndex=0 (wrong index intentionally)
  const verdicts: Verdict[] = [{
    findingIndex: 0,
    findingKey: 'b.ts:20:R2',
    originalSummary: 'z',
    verdict: 'REJECTED',
    rationale: 'test'
  }]
  const result = applyVerdicts(findings, verdicts)
  assert(result.length === 1, `key-based should reject b.ts:20:R2 regardless of index`)
  assert(result[0]?.rule === 'R1', `surviving finding should be R1`)
})

test('crossDomain not in Finding type', () => {
  // TypeScript-level: creating a Finding with crossDomain should fail type check
  // Runtime-level: FindingSchema.parse should succeed without crossDomain
  const f = { severity: 'warning', rule: 'R', file: 'a.ts', line: 1, confidence: 80, issue: 'x', fix: 'y', isHardRule: false }
  const parsed = FindingSchema.safeParse(f)
  assert(parsed.success, 'Finding without crossDomain should parse fine')
})
```

---

## Verify

```bash
cd anvil-sdk && npx tsc --noEmit && npx tsx smoke-test.ts
```
