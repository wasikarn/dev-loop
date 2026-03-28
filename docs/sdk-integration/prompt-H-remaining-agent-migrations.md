# Prompt H: Remaining Agent Migrations — Challenger, Investigator, Verifier

**Opportunity:** Migrate challenger, investigator (+ dx-analyst), verifier จาก Agent SDK `query()` ไปใช้ `agentLoop()` จาก Prompt F
**Impact:** ลบ `@anthropic-ai/claude-agent-sdk` dependency ออกได้ทั้งหมด + ทุก agent ได้ prompt caching บน system prompt
**Files ที่แก้:**

- `anvil-sdk/src/plan/agents/challenger.ts`
- `anvil-sdk/src/investigate/agents/investigation.ts`
- `anvil-sdk/src/fix-intent-verify/agents/verifier.ts`
- `anvil-sdk/package.json` — ลบ `@anthropic-ai/claude-agent-sdk`
- `anvil-sdk/smoke-test.ts` — verify ไม่มี Agent SDK imports เหลือ

**ขึ้นอยู่กับ:** **Prompt F ต้อง execute ก่อน** — ใช้ `agentLoop()` จาก `src/agent-loop.ts`

---

## Migration Pattern (เหมือนกันทุก agent)

```text
ก่อน:
  import { query } from '@anthropic-ai/claude-agent-sdk'
  import type { AgentDefinition, SDKResultSuccess } from '@anthropic-ai/claude-agent-sdk'
  function createXxx(model): AgentDefinition { return { prompt, tools, model, maxTurns } }
  async function runXxx(params): Promise<Result> {
    const agent = createXxx(params.config.model)
    for await (const msg of query({ agents: { xxx: agent }, agent: 'xxx', ..., outputFormat: { json_schema } })) {
      if (msg.type === 'result' && msg.subtype === 'success') { parse msg.structured_output }
    }
  }

หลัง:
  import { agentLoop } from '../../agent-loop.js'
  async function runXxx(params): Promise<Result> {
    const result = await agentLoop({ model, systemPrompt: PROMPT, userMessage, allowedTools, outputSchema, maxTurns, maxBudgetUsd })
    parse JSON.parse(result.text) ผ่าน ZodSchema
  }
```

---

## Step 1: challenger.ts

**ไฟล์:** `anvil-sdk/src/plan/agents/challenger.ts`

```typescript
// ก่อน
import { readFileSync } from 'node:fs'
import type { AgentDefinition, SDKResultSuccess } from '@anthropic-ai/claude-agent-sdk'
import { query } from '@anthropic-ai/claude-agent-sdk'
import type { ModelName, ResolvedConfig } from '../../config.js'
import { PLAN_CHALLENGE_PROMPT } from '../prompts/challenger.js'
import { ChallengeResultSchema, challengeResultJsonSchema, type ChallengeResult } from '../schemas/challenge.js'

function createChallenger(model: ModelName): AgentDefinition {
  return {
    description: 'Challenges implementation plans — goal is to remove scope creep and surface pre-work',
    prompt: PLAN_CHALLENGE_PROMPT,
    tools: ['Read', 'Grep', 'Glob'],
    model,
    maxTurns: 5,
  }
}

export async function runPlanChallenge(params: {
  planPath: string
  researchPath: string | undefined
  config: ResolvedConfig
}): Promise<ChallengeResult> {
  const planContent = readFileSync(params.planPath, 'utf8')
  const researchContent = params.researchPath !== undefined
    ? readFileSync(params.researchPath, 'utf8')
    : '(no research.md provided)'
  const agent = createChallenger(params.config.model)
  const prompt = `Challenge this implementation plan.\n\nPLAN:\n${planContent}\n\nRESEARCH:\n${researchContent}\n\nReturn verdicts as JSON.`

  for await (const msg of query({
    prompt,
    options: {
      agents: { challenger: agent },
      agent: 'challenger',
      allowedTools: ['Read', 'Grep', 'Glob'],
      permissionMode: 'bypassPermissions',
      allowDangerouslySkipPermissions: true,
      maxTurns: 5,
      maxBudgetUsd: params.config.maxBudgetFalsification,
      outputFormat: { type: 'json_schema', schema: challengeResultJsonSchema as Record<string, unknown> },
    },
  })) {
    if (msg.type === 'result') {
      if (msg.subtype === 'success') {
        const result = msg as SDKResultSuccess
        const raw = result.structured_output
        if (raw === undefined || raw === null) throw new Error('[sdk-plan-challenge] no structured_output')
        const parsed = ChallengeResultSchema.safeParse(raw)
        if (!parsed.success) throw new Error(`[sdk-plan-challenge] schema failed: ${JSON.stringify(parsed.error.issues)}`)
        return parsed.data
      }
      throw new Error(`[sdk-plan-challenge] ended with subtype: ${msg.subtype}`)
    }
  }
  throw new Error('[sdk-plan-challenge] query ended without result message')
}

// หลัง — ลด 40+ lines → 25 lines
import { readFileSync } from 'node:fs'
import { agentLoop } from '../../agent-loop.js'
import type { ResolvedConfig } from '../../config.js'
import { PLAN_CHALLENGE_PROMPT } from '../prompts/challenger.js'
import { ChallengeResultSchema, challengeResultJsonSchema, type ChallengeResult } from '../schemas/challenge.js'

export async function runPlanChallenge(params: {
  planPath: string
  researchPath: string | undefined
  config: ResolvedConfig
}): Promise<ChallengeResult> {
  const planContent = readFileSync(params.planPath, 'utf8')
  const researchContent = params.researchPath !== undefined
    ? readFileSync(params.researchPath, 'utf8')
    : '(no research.md provided)'

  const result = await agentLoop({
    model: params.config.model,
    systemPrompt: PLAN_CHALLENGE_PROMPT,
    userMessage: `Challenge this implementation plan.\n\nPLAN:\n${planContent}\n\nRESEARCH:\n${researchContent}\n\nReturn verdicts as JSON.`,
    allowedTools: ['Read', 'Grep', 'Glob'],
    outputSchema: challengeResultJsonSchema as Record<string, unknown>,
    maxTurns: 5,
    maxBudgetUsd: params.config.maxBudgetFalsification,
  })

  let parsed: ReturnType<typeof ChallengeResultSchema.safeParse>
  try {
    parsed = ChallengeResultSchema.safeParse(JSON.parse(result.text))
  } catch {
    throw new Error('[sdk-plan-challenge] invalid JSON in response')
  }
  if (!parsed.success) throw new Error(`[sdk-plan-challenge] schema failed: ${JSON.stringify(parsed.error.issues)}`)
  return parsed.data
}
```

---

## Step 2: investigation.ts — Investigator + DX Analyst

**ไฟล์:** `anvil-sdk/src/investigate/agents/investigation.ts`

มี 2 agents ที่ต้อง migrate: `runInvestigator()` และ `runDxAnalyst()` — แต่ละตัวเป็น independent `agentLoop()` call

```typescript
// ก่อน imports
import type { AgentDefinition, SDKResultSuccess } from '@anthropic-ai/claude-agent-sdk'
import { query } from '@anthropic-ai/claude-agent-sdk'

// หลัง imports
import { agentLoop } from '../../agent-loop.js'
// ลบ query, AgentDefinition, SDKResultSuccess, ModelName imports
```

### runInvestigator migration

```typescript
// ก่อน — function createInvestigator() + for await query loop
// หลัง

async function runInvestigator(params: {
  bugDescription: string
  config: ResolvedConfig
}): Promise<{ rootCause: RootCause; fixPlan: InvestigationResult['fixPlan'] }> {
  const result = await agentLoop({
    model: params.config.model,
    systemPrompt: INVESTIGATOR_PROMPT,
    userMessage: `Investigate this bug and return root cause + fix plan as JSON.\n\nBUG:\n${params.bugDescription}`,
    allowedTools: ['Read', 'Grep', 'Glob', 'Bash'],  // Bash for git log/blame
    outputSchema: investigatorOutputSchema as Record<string, unknown>,
    maxTurns: 15,
    maxBudgetUsd: params.config.maxBudgetPerReviewer,
  })

  let parsed: ReturnType<typeof InvestigationResultSchema.pick>
  try {
    parsed = InvestigationResultSchema.pick({ rootCause: true, fixPlan: true }).safeParse(JSON.parse(result.text))
  } catch {
    throw new Error('[sdk-investigate] investigator returned invalid JSON')
  }
  if (!parsed.success) throw new Error(`[sdk-investigate] investigator schema failed: ${JSON.stringify(parsed.error.issues)}`)
  return parsed.data
}
```

### runDxAnalyst migration

```typescript
// หลัง — non-fatal: ถ้า error ให้ return [] แทน throw

async function runDxAnalyst(params: {
  bugDescription: string
  config: ResolvedConfig
}): Promise<DxFinding[]> {
  let result: Awaited<ReturnType<typeof agentLoop>>
  try {
    result = await agentLoop({
      model: params.config.model,
      systemPrompt: DX_ANALYST_PROMPT,
      userMessage: `Audit the affected area of this bug for DX issues. Return findings as JSON.\n\nBUG:\n${params.bugDescription}`,
      allowedTools: ['Read', 'Grep', 'Glob'],
      outputSchema: dxAnalystOutputSchema as Record<string, unknown>,
      maxTurns: 10,
      maxBudgetUsd: params.config.maxBudgetFalsification,
    })
  } catch (err) {
    console.warn(`[sdk-investigate] dx-analyst API call failed — returning empty: ${String(err)}`)
    return []
  }

  let parsed: ReturnType<typeof InvestigationResultSchema.pick>
  try {
    parsed = InvestigationResultSchema.pick({ dxFindings: true }).safeParse(JSON.parse(result.text))
  } catch {
    console.warn('[sdk-investigate] dx-analyst invalid JSON — returning empty')
    return []
  }
  if (!parsed.success) {
    console.warn(`[sdk-investigate] dx-analyst schema failed — returning empty`)
    return []
  }
  return parsed.data.dxFindings
}
```

`runInvestigation()` (ฟังก์ชัน public) ไม่ต้องเปลี่ยน — ยังใช้ `Promise.all` เหมือนเดิม

---

## Step 3: verifier.ts

**ไฟล์:** `anvil-sdk/src/fix-intent-verify/agents/verifier.ts`

verifier.ts มี graceful degradation พิเศษสำหรับ `error_max_budget_usd` — ต้อง handle ผ่าน try/catch แทน subtype check

```typescript
// ก่อน imports
import type { AgentDefinition } from '@anthropic-ai/claude-agent-sdk'
import { query } from '@anthropic-ai/claude-agent-sdk'
import type { ModelName, ResolvedConfig } from '../../config.js'

// หลัง imports
import { agentLoop } from '../../agent-loop.js'
import type { ResolvedConfig } from '../../config.js'
```

```typescript
// ลบ createIntentVerifier() function ออก

export async function runIntentVerification(params: {
  pr: number
  triageContent: string
  config: ResolvedConfig
}): Promise<VerifierResult> {
  let result: Awaited<ReturnType<typeof agentLoop>>
  try {
    result = await agentLoop({
      model: params.config.model,
      systemPrompt: VERIFIER_PROMPT,
      userMessage: `Verify fix intent for PR #${params.pr}. Triage:\n${params.triageContent}`,
      allowedTools: ['Read', 'Bash'],
      outputSchema: verifierResultJsonSchema as Record<string, unknown>,
      maxTurns: 8,
      maxBudgetUsd: params.config.maxBudgetVerification,
    })
  } catch (err) {
    // Budget exceeded and similar non-fatal errors — caller (respond lead) proceeds without verification
    const msg = String(err)
    if (msg.includes('budget') || msg.includes('rate_limit') || msg.includes('overload')) {
      console.warn(`[fix-intent-verify] non-fatal error — returning empty verdicts: ${msg}`)
      return { verdicts: [], summary: { addressed: 0, partial: 0, misaligned: 0 } }
    }
    throw err
  }

  let parsed: ReturnType<typeof VerifierResultSchema.safeParse>
  try {
    parsed = VerifierResultSchema.safeParse(JSON.parse(result.text))
  } catch {
    throw new Error('[fix-intent-verify] invalid JSON in response')
  }
  if (!parsed.success) throw new Error(`[fix-intent-verify] schema failed: ${JSON.stringify(parsed.error.issues)}`)
  return parsed.data
}
```

---

## Step 4: ลบ @anthropic-ai/claude-agent-sdk

หลัง migrate ครบทุก agent ตรวจว่าไม่มี import เหลือ:

```bash
grep -r "claude-agent-sdk" anvil-sdk/src/
# ต้องไม่มีผลลัพธ์
```

ลบจาก `package.json`:

```json
// ก่อน
"dependencies": {
  "@anthropic-ai/claude-agent-sdk": "...",
  "@anthropic-ai/sdk": "^0.80.0",
  "zod": "^4.0.0"
}

// หลัง
"dependencies": {
  "@anthropic-ai/sdk": "^0.80.0",
  "zod": "^4.0.0"
}
```

```bash
cd anvil-sdk && npm install  # อัปเดต package-lock.json
```

---

## Prompt Caching ที่ได้จาก Migration นี้

| Agent | System Prompt | Cache benefit |
| --- | --- | --- |
| Challenger | `PLAN_CHALLENGE_PROMPT` (~300 tokens) | มีค่าเมื่อ iterate plan หลายรอบในวันเดียว |
| Investigator | `INVESTIGATOR_PROMPT` (~400 tokens) | มีค่าเมื่อ debug หลาย bug ในวันเดียว |
| DX Analyst | `DX_ANALYST_PROMPT` (~200 tokens) | มีค่าเมื่อ run คู่กับ investigator หลายครั้ง |
| Verifier | `VERIFIER_PROMPT` (~500 tokens) | มีค่าเมื่อ re-verify หลังแก้ PR หลายรอบ |

---

## Smoke Tests เพิ่ม

```typescript
test('no @anthropic-ai/claude-agent-sdk imports remain', async () => {
  // Read all .ts files under src/ and verify no imports
  import { execSync } from 'node:child_process'
  const result = execSync('grep -r "claude-agent-sdk" anvil-sdk/src/ --include="*.ts" -l', { encoding: 'utf8' }).trim()
  assert(result === '', `Agent SDK imports found in: ${result}`)
})

// Schema validation tests — verify unchanged schemas still parse correctly
test('ChallengeResultSchema still validates after migration', () => {
  const valid = { issues: [], yagniFlags: [], preworkItems: [], overallVerdict: 'APPROVED' as const }
  const parsed = ChallengeResultSchema.safeParse(valid)
  assert(parsed.success, `ChallengeResultSchema should still parse: ${JSON.stringify(parsed)}`)
})
```

---

## Verify

```bash
cd anvil-sdk
grep -r "claude-agent-sdk" src/ --include="*.ts"   # ต้องว่างเปล่า
npx tsc --noEmit
npx tsx smoke-test.ts
npm ls @anthropic-ai/claude-agent-sdk               # ต้องไม่มี
```
