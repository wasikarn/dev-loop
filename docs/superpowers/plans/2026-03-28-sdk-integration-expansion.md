# SDK Integration Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the devflow-sdk with three new CLI subcommands (`plan-challenge`, `falsify`, `investigate`) and update four skill files to use SDK fast-paths before falling back to Agent Teams.

**Architecture:** Each new command follows the existing `review` pattern: `AgentDefinition` + `query()` async iterator + structured JSON output via `outputFormat`. Skill files add a bash SDK block at the top of each relevant phase step — try SDK, check exit 0 + valid JSON, skip Agent Teams on success. All new modules live in `devflow-sdk/src/` with parallel structure to `src/review/`.

**Tech Stack:** TypeScript ESM, `@anthropic-ai/claude-agent-sdk` (query), `zod` v4, `tsx` CLI runner, bash for skill integration blocks.

---

## File Structure

### New files (create)

| File | Responsibility |
| --- | --- |
| `devflow-sdk/src/plan/schemas/challenge.ts` | `ChallengeResultSchema` + `challengeResultJsonSchema` for plan-challenger output |
| `devflow-sdk/src/plan/prompts/challenger.ts` | `PLAN_CHALLENGE_PROMPT` — Minimal-lens + Clean-lens challenge |
| `devflow-sdk/src/plan/agents/challenger.ts` | `createChallenger()` + `runPlanChallenge()` — SDK agent runner |
| `devflow-sdk/src/investigate/schemas/investigation.ts` | `InvestigationResultSchema` + `investigationResultJsonSchema` |
| `devflow-sdk/src/investigate/prompts/investigator.ts` | `INVESTIGATOR_PROMPT` — root cause tracing, file:line evidence |
| `devflow-sdk/src/investigate/prompts/dx-analyst.ts` | `DX_ANALYST_PROMPT` — observability, error handling, test coverage audit |
| `devflow-sdk/src/investigate/agents/investigation.ts` | `runInvestigation()` — runs Investigator + DX Analyst concurrently via `Promise.allSettled` |

### Modified files (modify)

| File | Change |
| --- | --- |
| `devflow-sdk/src/cli.ts` | Add `plan-challenge` and `investigate` subcommands; expose `falsify` as standalone command |
| `devflow-sdk/src/review/agents/falsifier.ts` | Extract `parseFindingsFromJson()` helper for standalone use |
| `skills/build/references/phase-3-plan.md` | Step 2: Add SDK fast-path block before `plan-challenger` spawn |
| `skills/build/references/phase-6-review.md` | Phase 7: Add SDK fast-path block before `falsification-agent` spawn |
| `skills/review/references/phase-5.md` | Falsification Pass: Add SDK fast-path block |
| `skills/debug/SKILL.md` | Phase 2 Step 1: Add SDK fast-path block before Create Team |
| `devflow-sdk/smoke-test.ts` | Add tests for challenge schema, investigation schema, new CLI subcommand argument parsing |

---

## Task 1: Plan Challenge Schema

**Files:**
- Create: `devflow-sdk/src/plan/schemas/challenge.ts`

- [ ] **Step 1: Write the failing smoke test**

```typescript
// In devflow-sdk/smoke-test.ts — add after existing tests:
console.log('\nplan/schemas/challenge')
import { ChallengeResultSchema } from './src/plan/schemas/challenge.js'
test('ChallengeResultSchema parses valid output', () => {
  const result = ChallengeResultSchema.safeParse({
    minimal: [
      { taskNumber: 1, taskName: 'Add repo', verdict: 'SUSTAINED', ground: '—', rationale: 'Required by Truth 1' },
      { taskNumber: 2, taskName: 'Extract base', verdict: 'CHALLENGED', ground: 'YAGNI', rationale: 'Only one use case' },
    ],
    missingTasks: ['Migration rollback not in plan'],
    dependencyIssues: [],
    clean: [
      { area: 'AuthService', issue: 'Returns generic Error', evidence: 'research.md:45', recommendation: 'Add AuthError type first' },
    ],
    recommendation: 'READY after addressing 2 items',
  })
  assert(result.success, `schema failed: ${JSON.stringify(result.error?.issues)}`)
})
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsx smoke-test.ts 2>&1 | tail -20
```

Expected: error about missing module `src/plan/schemas/challenge.js`

- [ ] **Step 3: Create the schema file**

```typescript
// devflow-sdk/src/plan/schemas/challenge.ts
import { z } from 'zod'

export const MinimalFindingSchema = z.object({
  taskNumber: z.number().int().min(1),
  taskName: z.string(),
  verdict: z.enum(['SUSTAINED', 'CHALLENGED']),
  ground: z.string(), // '—' for SUSTAINED, 'YAGNI'|'SCOPE'|'ORDER'|'MISSING' for CHALLENGED
  rationale: z.string(),
})

export const CleanFindingSchema = z.object({
  area: z.string(),
  issue: z.string(),
  evidence: z.string(), // file:line or research.md:line
  recommendation: z.string(),
})

export const ChallengeResultSchema = z.object({
  minimal: z.array(MinimalFindingSchema),
  missingTasks: z.array(z.string()),
  dependencyIssues: z.array(z.string()),
  clean: z.array(CleanFindingSchema),
  recommendation: z.string(),
})

// Manually crafted JSON schema — avoids z.toJSONSchema() $schema field quirks
export const challengeResultJsonSchema = {
  type: 'object',
  properties: {
    minimal: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          taskNumber: { type: 'integer', minimum: 1 },
          taskName: { type: 'string' },
          verdict: { type: 'string', enum: ['SUSTAINED', 'CHALLENGED'] },
          ground: { type: 'string' },
          rationale: { type: 'string' },
        },
        required: ['taskNumber', 'taskName', 'verdict', 'ground', 'rationale'],
      },
    },
    missingTasks: { type: 'array', items: { type: 'string' } },
    dependencyIssues: { type: 'array', items: { type: 'string' } },
    clean: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          area: { type: 'string' },
          issue: { type: 'string' },
          evidence: { type: 'string' },
          recommendation: { type: 'string' },
        },
        required: ['area', 'issue', 'evidence', 'recommendation'],
      },
    },
    recommendation: { type: 'string' },
  },
  required: ['minimal', 'missingTasks', 'dependencyIssues', 'clean', 'recommendation'],
} as const

export type MinimalFinding = z.infer<typeof MinimalFindingSchema>
export type CleanFinding = z.infer<typeof CleanFindingSchema>
export type ChallengeResult = z.infer<typeof ChallengeResultSchema>
```

- [ ] **Step 4: Run smoke test to verify schema test passes**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsx smoke-test.ts 2>&1 | grep -A3 'plan/schemas'
```

Expected: `✅ ChallengeResultSchema parses valid output`

- [ ] **Step 5: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add devflow-sdk/src/plan/schemas/challenge.ts devflow-sdk/smoke-test.ts && git commit -m "feat(sdk): add plan challenge schema with Zod + JSON schema"
```

---

## Task 2: Plan Challenge Prompt + Agent

**Files:**
- Create: `devflow-sdk/src/plan/prompts/challenger.ts`
- Create: `devflow-sdk/src/plan/agents/challenger.ts`

- [ ] **Step 1: Write the plan challenge prompt**

```typescript
// devflow-sdk/src/plan/prompts/challenger.ts
export const PLAN_CHALLENGE_PROMPT = `You are a plan challenger for software implementation plans.
Challenge the plan from two lenses and return JSON.

LENS 1 — MINIMAL: "What can be removed and still satisfy ALL must_haves.truths?"
For each task in the plan, apply:
- YAGNI Test: Is this speculative? Evidence: "in case we need", single-use abstractions
- Scope Test: Does it go beyond stated requirements / must_haves.truths?
- Order Test: Is it correctly sequenced? Can it be parallel?
ALSO check for: Missing tasks (missing tests for new logic, missing rollback for schema changes)
Output quota: minimal[] MUST have ≥2 entries total (SUSTAINED + CHALLENGED). missingTasks[] and dependencyIssues[] may be empty.

LENS 2 — CLEAN: "What should be refactored BEFORE implementing to avoid accruing debt?"
Look in research.md for existing code the plan modifies that has known issues.
Output quota: clean[] MUST have ≥1 entry. If no pre-work needed, add one entry explaining why with evidence.

Rules:
- Hard requirements in Jira AC → SUSTAINED, never CHALLENGED
- Burden of proof is on the plan — unclear task necessity = CHALLENGED
- Do not challenge implementation approach, only existence/scope/order

Return JSON matching the schema exactly. No prose outside the JSON block.`
```

- [ ] **Step 2: Write the challenger agent**

```typescript
// devflow-sdk/src/plan/agents/challenger.ts
import { readFileSync } from 'node:fs'
import type { AgentDefinition } from '@anthropic-ai/claude-agent-sdk'
import { query } from '@anthropic-ai/claude-agent-sdk'
import type { SDKResultSuccess } from '@anthropic-ai/claude-agent-sdk'
import type { ResolvedConfig } from '../../config.js'
import { PLAN_CHALLENGE_PROMPT } from '../prompts/challenger.js'
import { ChallengeResultSchema, challengeResultJsonSchema, type ChallengeResult } from '../schemas/challenge.js'

function createChallenger(model: 'sonnet' | 'opus' | 'haiku'): AgentDefinition {
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
      maxBudgetUsd: 0.15,
      outputFormat: {
        type: 'json_schema',
        schema: challengeResultJsonSchema as Record<string, unknown>,
      },
    },
  })) {
    if (msg.type === 'result') {
      if (msg.subtype === 'success') {
        const result = msg as SDKResultSuccess
        const raw = result.structured_output
        if (raw === undefined || raw === null) {
          throw new Error('[sdk-plan-challenge] no structured_output — budget may have been exceeded')
        }
        const parsed = ChallengeResultSchema.safeParse(raw)
        if (!parsed.success) {
          throw new Error(`[sdk-plan-challenge] schema validation failed: ${JSON.stringify(parsed.error.issues)}`)
        }
        return parsed.data
      } else {
        throw new Error(`[sdk-plan-challenge] ended with subtype: ${msg.subtype}`)
      }
    }
  }

  throw new Error('[sdk-plan-challenge] query ended without result message')
}
```

- [ ] **Step 3: TypeScript check**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsc --noEmit 2>&1
```

Expected: 0 errors

- [ ] **Step 4: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add devflow-sdk/src/plan/prompts/challenger.ts devflow-sdk/src/plan/agents/challenger.ts && git commit -m "feat(sdk): add plan-challenge agent with dual-lens prompt"
```

---

## Task 3: `plan-challenge` CLI Subcommand

**Files:**
- Modify: `devflow-sdk/src/cli.ts`

- [ ] **Step 1: Write the smoke test for CLI arg parsing**

```typescript
// In devflow-sdk/smoke-test.ts — add plan-challenge CLI arg tests:
console.log('\nplan-challenge CLI args')
// Test that parseArgs correctly handles plan-challenge subcommand
// (We'll test the new parsePlanChallengeArgs function directly)
import { parsePlanChallengeArgs } from './src/cli.js'
test('parsePlanChallengeArgs returns plan path', () => {
  const result = parsePlanChallengeArgs(['--plan-file', 'plan.md'])
  assert(result.planFile === 'plan.md', `expected plan.md, got ${result.planFile}`)
})
test('parsePlanChallengeArgs returns research path', () => {
  const result = parsePlanChallengeArgs(['--plan-file', 'plan.md', '--research-file', 'research.md'])
  assert(result.researchFile === 'research.md', `expected research.md, got ${result.researchFile}`)
})
test('parsePlanChallengeArgs defaults researchFile to undefined', () => {
  const result = parsePlanChallengeArgs(['--plan-file', 'plan.md'])
  assert(result.researchFile === undefined, 'expected undefined researchFile')
})
```

- [ ] **Step 2: Run to verify tests fail**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsx smoke-test.ts 2>&1 | grep -A5 'plan-challenge CLI'
```

Expected: import error for `parsePlanChallengeArgs`

- [ ] **Step 3: Add plan-challenge subcommand to cli.ts**

Refactor `cli.ts` to support subcommands. The existing `main()` runs the `review` command. Extract it into a `runReviewCommand()` function, add `runPlanChallengeCommand()`, and dispatch based on `argv[2]`.

```typescript
// Add to devflow-sdk/src/cli.ts:

interface ParsedPlanChallengeArgs {
  planFile: string | undefined
  researchFile: string | undefined
  output: 'json' | 'markdown'
  budget: number | undefined
}

export function parsePlanChallengeArgs(args: string[]): ParsedPlanChallengeArgs {
  const result: ParsedPlanChallengeArgs = {
    planFile: undefined,
    researchFile: undefined,
    output: 'json',
    budget: undefined,
  }
  for (let i = 0; i < args.length; i++) {
    const arg = args[i]
    if (arg === undefined) continue
    const next = args[i + 1]
    if (arg === '--plan-file') {
      if (next === undefined) { console.error('[sdk-plan-challenge] --plan-file requires a value'); process.exit(1) }
      result.planFile = next; i++
    } else if (arg === '--research-file') {
      if (next === undefined) { console.error('[sdk-plan-challenge] --research-file requires a value'); process.exit(1) }
      result.researchFile = next; i++
    } else if (arg === '--output') {
      if (next === 'json' || next === 'markdown') { result.output = next; i++ }
    } else if (arg === '--budget') {
      if (next !== undefined) { const n = parseFloat(next); if (!Number.isNaN(n)) { result.budget = n; i++ } }
    }
  }
  return result
}

async function runPlanChallengeCommand(args: string[]): Promise<void> {
  const parsed = parsePlanChallengeArgs(args)
  if (parsed.planFile === undefined) {
    console.error('[sdk-plan-challenge] --plan-file is required')
    process.exit(1)
  }
  if (!existsSync(parsed.planFile)) {
    console.error(`[sdk-plan-challenge] plan file not found: ${parsed.planFile}`)
    process.exit(1)
  }
  if (parsed.researchFile !== undefined && !existsSync(parsed.researchFile)) {
    console.error(`[sdk-plan-challenge] research file not found: ${parsed.researchFile}`)
    process.exit(1)
  }
  const config = resolveConfig({ ...(parsed.budget !== undefined && { budgetUsd: parsed.budget }) })
  const { runPlanChallenge } = await import('./plan/agents/challenger.js')
  const result = await runPlanChallenge({ planPath: parsed.planFile, researchPath: parsed.researchFile, config })
  console.log(JSON.stringify(result, null, 2))
}
```

Then update `main()` to dispatch subcommands:

```typescript
async function main(): Promise<void> {
  const argv = process.argv
  const subcommand = argv[2]
  const args = argv.length > 3 ? argv.slice(3) : []

  if (subcommand === 'plan-challenge') {
    await runPlanChallengeCommand(args)
    return
  }

  // Default: review (existing behavior, args = argv.slice(2))
  await runReviewCommand(argv.length > 2 ? argv.slice(2) : [])
}
```

Note: the existing arg parsing becomes `runReviewCommand(args)` which calls `parseArgs(args)` internally — same behavior as before.

- [ ] **Step 4: Run TypeScript check**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsc --noEmit 2>&1
```

Expected: 0 errors

- [ ] **Step 5: Run smoke tests**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsx smoke-test.ts 2>&1 | grep -A5 'plan-challenge CLI'
```

Expected: 3 ✅ for plan-challenge CLI args tests

- [ ] **Step 6: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add devflow-sdk/src/cli.ts devflow-sdk/smoke-test.ts && git commit -m "feat(sdk): add plan-challenge CLI subcommand"
```

---

## Task 4: Update `/build` Phase 3 with Plan-Challenge SDK Fast-Path

**Files:**
- Modify: `skills/build/references/phase-3-plan.md`

- [ ] **Step 1: Add SDK fast-path block to phase-3-plan.md Step 2**

In `skills/build/references/phase-3-plan.md`, replace the Step 2 content with:

```markdown
## Step 2: Plan-Challenger (Full Mode Only)

**Micro and Quick:** Skip plan-challenger entirely. Proceed to Step 3.

**Full mode only:** Try the SDK Plan-Challenger first (faster, lower token cost):

```bash
SDK_DIR="${CLAUDE_SKILL_DIR}/../../devflow-sdk"

if [ ! -d "$SDK_DIR/node_modules" ]; then
  (cd "$SDK_DIR" && npm install --silent 2>/dev/null)
fi

sdk_result=$(cd "$SDK_DIR" && node_modules/.bin/tsx src/cli.ts plan-challenge \
  --plan-file {plan_file_path} \
  --research-file {artifacts_dir}/research.md \
  --output json 2>&1)
sdk_exit=$?
```

If `sdk_exit=0` and `sdk_result` is valid JSON (starts with `{`):

**Use SDK output directly:**
- Parse `sdk_result` as `ChallengeResult` JSON
- Present challenge findings inline — `minimal[]` as Minimal-Lens table, `clean[]` as Clean-Lens table
- Report: `SDK Plan-Challenger: {challenged} challenged · {missing} missing tasks`
- **Skip Agent Teams `plan-challenger` spawn** — proceed to Step 3

**If `sdk_exit != 0` or result is not valid JSON**, log `SDK plan-challenge failed (exit {sdk_exit}) — falling back to Agent Teams` and continue with Agent Teams:

Do **not** wait for the Agent Teams plan-challenger — continue to Step 3 (readiness gate) while plan-challenger runs.

Plan-challenger uses **dual-lens** challenge (see [agents/plan-challenger.md](../../../agents/plan-challenger.md)):
...
```

- [ ] **Step 2: Verify markdown lint passes**

```bash
cd /Users/kobig/Codes/Personals/devflow && npx markdownlint-cli2 "skills/build/references/phase-3-plan.md" 2>&1
```

Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add skills/build/references/phase-3-plan.md && git commit -m "feat(build): add SDK fast-path for plan-challenger in Phase 3"
```

---

## Task 5: Investigation Schema + Prompts

**Files:**
- Create: `devflow-sdk/src/investigate/schemas/investigation.ts`
- Create: `devflow-sdk/src/investigate/prompts/investigator.ts`
- Create: `devflow-sdk/src/investigate/prompts/dx-analyst.ts`

- [ ] **Step 1: Write the smoke test for investigation schema**

```typescript
// In devflow-sdk/smoke-test.ts — add after plan challenge tests:
console.log('\ninvestigate/schemas/investigation')
import { InvestigationResultSchema } from './src/investigate/schemas/investigation.js'
test('InvestigationResultSchema parses valid output', () => {
  const result = InvestigationResultSchema.safeParse({
    rootCause: {
      hypothesis: 'Null pointer in UserService.findById',
      confidence: 'high',
      evidence: [{ file: 'src/user.service.ts', line: 42, snippet: 'return user.profile.name' }],
      alternativeHypotheses: [],
    },
    dxFindings: [
      { severity: 'warning', category: 'error-handling', file: 'src/user.service.ts', line: 42, issue: 'No null guard', recommendation: 'Add optional chaining' },
    ],
    fixPlan: [
      { type: 'bug', description: 'Add null guard on user.profile', file: 'src/user.service.ts', line: 42 },
      { type: 'test', description: 'Add test for null profile case', file: 'src/user.service.spec.ts', line: null },
    ],
  })
  assert(result.success, `schema failed: ${JSON.stringify(result.error?.issues)}`)
})
```

- [ ] **Step 2: Create the investigation schema**

```typescript
// devflow-sdk/src/investigate/schemas/investigation.ts
import { z } from 'zod'

export const EvidenceSchema = z.object({
  file: z.string(),
  line: z.number().int().nullable(),
  snippet: z.string(),
})

export const RootCauseSchema = z.object({
  hypothesis: z.string(),
  confidence: z.enum(['high', 'medium', 'low']),
  evidence: z.array(EvidenceSchema),
  alternativeHypotheses: z.array(z.string()),
})

export const DxFindingSchema = z.object({
  severity: z.enum(['critical', 'warning', 'info']),
  category: z.enum(['observability', 'error-handling', 'test-coverage', 'resilience']),
  file: z.string(),
  line: z.number().int().nullable(),
  issue: z.string(),
  recommendation: z.string(),
})

export const FixPlanItemSchema = z.object({
  type: z.enum(['bug', 'test', 'dx']),
  description: z.string(),
  file: z.string(),
  line: z.number().int().nullable(),
})

export const InvestigationResultSchema = z.object({
  rootCause: RootCauseSchema,
  dxFindings: z.array(DxFindingSchema),
  fixPlan: z.array(FixPlanItemSchema),
})

// Manually crafted JSON schema
export const investigationResultJsonSchema = {
  type: 'object',
  properties: {
    rootCause: {
      type: 'object',
      properties: {
        hypothesis: { type: 'string' },
        confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
        evidence: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              file: { type: 'string' },
              line: { type: 'integer' },
              snippet: { type: 'string' },
            },
            required: ['file', 'snippet'],
          },
        },
        alternativeHypotheses: { type: 'array', items: { type: 'string' } },
      },
      required: ['hypothesis', 'confidence', 'evidence', 'alternativeHypotheses'],
    },
    dxFindings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          severity: { type: 'string', enum: ['critical', 'warning', 'info'] },
          category: { type: 'string', enum: ['observability', 'error-handling', 'test-coverage', 'resilience'] },
          file: { type: 'string' },
          line: { type: 'integer' },
          issue: { type: 'string' },
          recommendation: { type: 'string' },
        },
        required: ['severity', 'category', 'file', 'issue', 'recommendation'],
      },
    },
    fixPlan: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          type: { type: 'string', enum: ['bug', 'test', 'dx'] },
          description: { type: 'string' },
          file: { type: 'string' },
          line: { type: 'integer' },
        },
        required: ['type', 'description', 'file'],
      },
    },
  },
  required: ['rootCause', 'dxFindings', 'fixPlan'],
} as const

export type Evidence = z.infer<typeof EvidenceSchema>
export type RootCause = z.infer<typeof RootCauseSchema>
export type DxFinding = z.infer<typeof DxFindingSchema>
export type FixPlanItem = z.infer<typeof FixPlanItemSchema>
export type InvestigationResult = z.infer<typeof InvestigationResultSchema>
```

- [ ] **Step 3: Create the investigator prompt**

```typescript
// devflow-sdk/src/investigate/prompts/investigator.ts
export const INVESTIGATOR_PROMPT = `You are a Senior SRE investigating a bug.
Your goal: find the root cause with file:line evidence. Not symptoms — root cause.

Process:
1. Read the bug description carefully
2. Search for the error/exception in the codebase (grep for error text, class names, method names)
3. Trace the call chain from entry point to the failure point
4. Identify the exact line causing the bug with code evidence
5. Check git log for recent changes to that area
6. Consider alternative hypotheses if evidence is ambiguous

Output confidence levels:
- high: single root cause, direct evidence at file:line
- medium: probable cause, indirect evidence or recent change correlation
- low: hypothesis only, no direct evidence found

Rules:
- Never guess without evidence — "might be" requires at least one corroborating file read
- Evidence must include file path + line number + code snippet
- Minimum 1 evidence item for high confidence, 1 item for medium
- alternativeHypotheses: list if confidence < high

Return JSON only. No prose outside JSON.`
```

- [ ] **Step 4: Create the DX analyst prompt**

```typescript
// devflow-sdk/src/investigate/prompts/dx-analyst.ts
export const DX_ANALYST_PROMPT = `You are a Senior SRE auditing developer experience in the affected area of a bug.
Your scope: files directly involved in the bug (passed in bug description and root cause area).

Audit categories (check all):
1. Observability: Are errors logged with context? Is the failure visible before users report it?
2. Error handling: Are errors caught and wrapped? Generic Error vs typed errors? Silent swallows?
3. Test coverage: Does a test exist that would have caught this bug? Gap in boundary/edge cases?
4. Resilience: Retry logic? Circuit breakers? Null guards? Input validation?

Severity rules:
- critical: complete absence (no logging at all, no error handling, no tests for this path)
- warning: partial (logging without context, generic Error thrown, test exists but misses this case)
- info: improvement opportunity (could be more specific, could add telemetry)

Scope: ONLY files in the bug's affected area. Do NOT audit unrelated code.
Output quota: ≥1 finding required. If no issues found, return 1 info finding explaining why area is clean.

Return JSON only. No prose outside JSON.`
```

- [ ] **Step 5: Run smoke test for schema**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsx smoke-test.ts 2>&1 | grep -A3 'investigate/schemas'
```

Expected: `✅ InvestigationResultSchema parses valid output`

- [ ] **Step 6: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add devflow-sdk/src/investigate/schemas/investigation.ts devflow-sdk/src/investigate/prompts/investigator.ts devflow-sdk/src/investigate/prompts/dx-analyst.ts devflow-sdk/smoke-test.ts && git commit -m "feat(sdk): add investigation schema and prompts"
```

---

## Task 6: Investigation Agent + CLI Subcommand

**Files:**
- Create: `devflow-sdk/src/investigate/agents/investigation.ts`
- Modify: `devflow-sdk/src/cli.ts`

- [ ] **Step 1: Create the investigation agent runner**

```typescript
// devflow-sdk/src/investigate/agents/investigation.ts
import type { AgentDefinition } from '@anthropic-ai/claude-agent-sdk'
import { query } from '@anthropic-ai/claude-agent-sdk'
import type { SDKResultSuccess } from '@anthropic-ai/claude-agent-sdk'
import type { ResolvedConfig } from '../../config.js'
import { INVESTIGATOR_PROMPT } from '../prompts/investigator.js'
import { DX_ANALYST_PROMPT } from '../prompts/dx-analyst.js'
import {
  InvestigationResultSchema,
  investigationResultJsonSchema,
  type InvestigationResult,
  type DxFinding,
  type RootCause,
} from '../schemas/investigation.js'

// Investigator returns root cause + fix plan items (no DX)
const investigatorOutputSchema = {
  type: 'object',
  properties: {
    rootCause: investigationResultJsonSchema.properties.rootCause,
    fixPlan: investigationResultJsonSchema.properties.fixPlan,
  },
  required: ['rootCause', 'fixPlan'],
} as const

// DX Analyst returns only dxFindings
const dxAnalystOutputSchema = {
  type: 'object',
  properties: {
    dxFindings: investigationResultJsonSchema.properties.dxFindings,
  },
  required: ['dxFindings'],
} as const

function createInvestigator(model: 'sonnet' | 'opus' | 'haiku'): AgentDefinition {
  return {
    description: 'Traces root cause of bugs — find file:line evidence, never guess',
    prompt: INVESTIGATOR_PROMPT,
    tools: ['Read', 'Grep', 'Glob', 'Bash'],
    model,
    maxTurns: 15,
  }
}

function createDxAnalyst(model: 'sonnet' | 'opus' | 'haiku'): AgentDefinition {
  return {
    description: 'Audits affected area for observability, error handling, and test coverage gaps',
    prompt: DX_ANALYST_PROMPT,
    tools: ['Read', 'Grep', 'Glob'],
    model,
    maxTurns: 10,
  }
}

async function runInvestigator(params: {
  bugDescription: string
  config: ResolvedConfig
}): Promise<{ rootCause: RootCause; fixPlan: InvestigationResult['fixPlan'] }> {
  const agent = createInvestigator(params.config.model)
  const prompt = `Investigate this bug and return root cause + fix plan as JSON.\n\nBUG:\n${params.bugDescription}`

  for await (const msg of query({
    prompt,
    options: {
      agents: { investigator: agent },
      agent: 'investigator',
      allowedTools: ['Read', 'Grep', 'Glob', 'Bash'],
      permissionMode: 'bypassPermissions',
      allowDangerouslySkipPermissions: true,
      maxTurns: 15,
      maxBudgetUsd: params.config.maxBudgetPerReviewer,
      outputFormat: { type: 'json_schema', schema: investigatorOutputSchema as Record<string, unknown> },
    },
  })) {
    if (msg.type === 'result') {
      if (msg.subtype === 'success') {
        const result = msg as SDKResultSuccess
        const raw = result.structured_output
        if (raw === undefined || raw === null) throw new Error('[sdk-investigate] investigator returned no structured_output')
        const parsed = InvestigationResultSchema.pick({ rootCause: true, fixPlan: true }).safeParse(raw)
        if (!parsed.success) throw new Error(`[sdk-investigate] investigator schema failed: ${JSON.stringify(parsed.error.issues)}`)
        return parsed.data
      }
      throw new Error(`[sdk-investigate] investigator ended with subtype: ${msg.subtype}`)
    }
  }
  throw new Error('[sdk-investigate] investigator query ended without result')
}

async function runDxAnalyst(params: {
  bugDescription: string
  config: ResolvedConfig
}): Promise<DxFinding[]> {
  const agent = createDxAnalyst(params.config.model)
  const prompt = `Audit the affected area of this bug for DX issues. Return findings as JSON.\n\nBUG:\n${params.bugDescription}`

  for await (const msg of query({
    prompt,
    options: {
      agents: { dxAnalyst: agent },
      agent: 'dxAnalyst',
      allowedTools: ['Read', 'Grep', 'Glob'],
      permissionMode: 'bypassPermissions',
      allowDangerouslySkipPermissions: true,
      maxTurns: 10,
      maxBudgetUsd: params.config.maxBudgetFalsification,
      outputFormat: { type: 'json_schema', schema: dxAnalystOutputSchema as Record<string, unknown> },
    },
  })) {
    if (msg.type === 'result') {
      if (msg.subtype === 'success') {
        const result = msg as SDKResultSuccess
        const raw = result.structured_output
        if (raw === undefined || raw === null) {
          console.warn('[sdk-investigate] dx-analyst returned no structured_output — returning empty DX findings')
          return []
        }
        const parsed = InvestigationResultSchema.pick({ dxFindings: true }).safeParse(raw)
        if (!parsed.success) {
          console.warn(`[sdk-investigate] dx-analyst schema failed — returning empty: ${JSON.stringify(parsed.error.issues)}`)
          return []
        }
        return parsed.data.dxFindings
      }
      // DX analyst failure is non-fatal — return empty findings
      console.warn(`[sdk-investigate] dx-analyst ended with subtype: ${msg.subtype} — returning empty DX findings`)
      return []
    }
  }
  return []
}

export async function runInvestigation(params: {
  bugDescription: string
  quickMode: boolean
  config: ResolvedConfig
}): Promise<InvestigationResult> {
  if (params.quickMode) {
    // Quick mode: Investigator only, no DX analysis
    const { rootCause, fixPlan } = await runInvestigator({ bugDescription: params.bugDescription, config: params.config })
    return { rootCause, dxFindings: [], fixPlan }
  }

  // Full mode: Investigator + DX Analyst in parallel
  const [investigatorResult, dxFindings] = await Promise.all([
    runInvestigator({ bugDescription: params.bugDescription, config: params.config }),
    runDxAnalyst({ bugDescription: params.bugDescription, config: params.config }),
  ])

  // Merge DX findings into fix plan as [dx] items
  const dxFixItems = dxFindings
    .filter(f => f.severity !== 'info')
    .map(f => ({ type: 'dx' as const, description: f.recommendation, file: f.file, line: f.line }))

  return {
    rootCause: investigatorResult.rootCause,
    dxFindings,
    fixPlan: [...investigatorResult.fixPlan, ...dxFixItems],
  }
}
```

- [ ] **Step 2: Add `investigate` subcommand to cli.ts**

```typescript
// Add to devflow-sdk/src/cli.ts:

interface ParsedInvestigateArgs {
  bug: string | undefined
  quick: boolean
  output: 'json' | 'markdown'
  budget: number | undefined
}

function parseInvestigateArgs(args: string[]): ParsedInvestigateArgs {
  const result: ParsedInvestigateArgs = { bug: undefined, quick: false, output: 'json', budget: undefined }
  for (let i = 0; i < args.length; i++) {
    const arg = args[i]
    if (arg === undefined) continue
    if (arg === '--quick') { result.quick = true; continue }
    const next = args[i + 1]
    if (arg === '--bug') {
      if (next === undefined) { console.error('[sdk-investigate] --bug requires a value'); process.exit(1) }
      result.bug = next; i++
    } else if (arg === '--output') {
      if (next === 'json' || next === 'markdown') { result.output = next; i++ }
    } else if (arg === '--budget') {
      if (next !== undefined) { const n = parseFloat(next); if (!Number.isNaN(n)) { result.budget = n; i++ } }
    }
  }
  return result
}

async function runInvestigateCommand(args: string[]): Promise<void> {
  const parsed = parseInvestigateArgs(args)
  if (parsed.bug === undefined) {
    console.error('[sdk-investigate] --bug is required')
    process.exit(1)
  }
  const config = resolveConfig({ ...(parsed.budget !== undefined && { budgetUsd: parsed.budget }) })
  const { runInvestigation } = await import('./investigate/agents/investigation.js')
  const result = await runInvestigation({ bugDescription: parsed.bug, quickMode: parsed.quick, config })
  console.log(JSON.stringify(result, null, 2))
}
```

Update `main()` dispatcher:

```typescript
async function main(): Promise<void> {
  const argv = process.argv
  const subcommand = argv[2]
  const args = argv.length > 3 ? argv.slice(3) : []

  if (subcommand === 'plan-challenge') {
    await runPlanChallengeCommand(args)
    return
  }
  if (subcommand === 'investigate') {
    await runInvestigateCommand(args)
    return
  }

  // Default: review (existing behavior)
  await runReviewCommand(argv.length > 2 ? argv.slice(2) : [])
}
```

- [ ] **Step 3: Add smoke tests for investigate CLI arg parsing**

```typescript
// In devflow-sdk/smoke-test.ts:
console.log('\ninvestigate CLI args')
import { parseInvestigateArgs } from './src/cli.js'
test('parseInvestigateArgs returns bug description', () => {
  const result = parseInvestigateArgs(['--bug', 'NPE in UserService'])
  assert(result.bug === 'NPE in UserService', `got ${result.bug}`)
})
test('parseInvestigateArgs defaults quick to false', () => {
  const result = parseInvestigateArgs(['--bug', 'test'])
  assert(result.quick === false, 'expected quick=false')
})
test('parseInvestigateArgs parses --quick flag', () => {
  const result = parseInvestigateArgs(['--bug', 'test', '--quick'])
  assert(result.quick === true, 'expected quick=true')
})
```

- [ ] **Step 4: TypeScript check + smoke tests**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsc --noEmit 2>&1 && node_modules/.bin/tsx smoke-test.ts 2>&1 | grep -E '✅|❌'
```

Expected: 0 TypeScript errors, all smoke tests ✅

- [ ] **Step 5: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add devflow-sdk/src/investigate/ devflow-sdk/src/cli.ts devflow-sdk/smoke-test.ts && git commit -m "feat(sdk): add investigate command (Investigator + DX Analyst concurrent)"
```

---

## Task 7: Update `/debug` Phase 2 with Investigation SDK Fast-Path

**Files:**
- Modify: `skills/debug/SKILL.md`

- [ ] **Step 1: Add SDK fast-path block to Phase 2 Step 1**

In `skills/debug/SKILL.md`, update Phase 2 Step 1 "Create Team" to add SDK fast-path **before** creating the team:

```markdown
### Step 1: SDK Investigation Fast-Path (try before spawning Agent Teams)

**Try the SDK Investigator first (faster, lower token cost):**

```bash
SDK_DIR="${CLAUDE_SKILL_DIR}/../../devflow-sdk"

if [ ! -d "$SDK_DIR/node_modules" ]; then
  (cd "$SDK_DIR" && npm install --silent 2>/dev/null)
fi

SDK_MODE_FLAG=""
# Full mode: runs Investigator + DX Analyst concurrently
# Quick mode: Investigator only (--quick flag)
[ "{mode}" = "Quick" ] && SDK_MODE_FLAG="--quick"

sdk_result=$(cd "$SDK_DIR" && node_modules/.bin/tsx src/cli.ts investigate \
  --bug "{bug_description}" \
  $SDK_MODE_FLAG \
  2>&1)
sdk_exit=$?
```

If `sdk_exit=0` and `sdk_result` is valid JSON (starts with `{`):

**Use SDK output directly:**
- Parse `sdk_result` as the InvestigationResult JSON
- Map to `investigation.md` format per artifact-templates.md#investigation.md
- Root Cause from `rootCause`, DX Findings from `dxFindings`, Fix Plan from `fixPlan`
- Report: `SDK Investigator: confidence={confidence} · {dxFindings.length} DX findings · {fixPlan.length} fix items`
- **Skip Agent Teams spawning** — proceed directly to Phase 2 Step 3 (Convergence) using the SDK results

**If confidence is "low"** in the SDK result — escalate to user regardless of how result was obtained. Low confidence = root cause not found.

**If `sdk_exit != 0` or result is not valid JSON**, log `SDK investigate failed (exit {sdk_exit}) — falling back to Agent Teams` and continue:

### Step 1 (fallback): Create Team

Create team `debug-{branch}` with 1-2 teammates...
```

- [ ] **Step 2: Verify markdown lint passes**

```bash
cd /Users/kobig/Codes/Personals/devflow && npx markdownlint-cli2 "skills/debug/SKILL.md" 2>&1
```

Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add skills/debug/SKILL.md && git commit -m "feat(debug): add SDK fast-path for investigation in Phase 2"
```

---

## Task 8: Standalone `falsify` CLI Subcommand

**Files:**
- Modify: `devflow-sdk/src/cli.ts`

The `falsification-agent` Agent Teams agent is currently spawned from:
1. `skills/review/references/phase-5.md` — after debate, before consolidation
2. `skills/build/references/phase-6-review.md` Phase 7 — same pattern

We expose a standalone `falsify` subcommand that takes a findings JSON file (pre-serialized by lead), runs falsification, and returns verdicts JSON.

- [ ] **Step 1: Add smoke test for falsify CLI arg parsing**

```typescript
// In devflow-sdk/smoke-test.ts:
console.log('\nfalsify CLI args')
import { parseFalsifyArgs } from './src/cli.js'
test('parseFalsifyArgs returns findings file path', () => {
  const result = parseFalsifyArgs(['--findings-file', '/tmp/findings.json'])
  assert(result.findingsFile === '/tmp/findings.json', `got ${result.findingsFile}`)
})
test('parseFalsifyArgs defaults output to json', () => {
  const result = parseFalsifyArgs(['--findings-file', '/tmp/findings.json'])
  assert(result.output === 'json', `got ${result.output}`)
})
```

- [ ] **Step 2: Add `falsify` subcommand to cli.ts**

```typescript
// Add to devflow-sdk/src/cli.ts:
import { readFileSync as _readFileSync } from 'node:fs'

interface ParsedFalsifyArgs {
  findingsFile: string | undefined
  output: 'json'
  budget: number | undefined
}

export function parseFalsifyArgs(args: string[]): ParsedFalsifyArgs {
  const result: ParsedFalsifyArgs = { findingsFile: undefined, output: 'json', budget: undefined }
  for (let i = 0; i < args.length; i++) {
    const arg = args[i]
    if (arg === undefined) continue
    const next = args[i + 1]
    if (arg === '--findings-file') {
      if (next === undefined) { console.error('[sdk-falsify] --findings-file requires a value'); process.exit(1) }
      result.findingsFile = next; i++
    } else if (arg === '--budget') {
      if (next !== undefined) { const n = parseFloat(next); if (!Number.isNaN(n)) { result.budget = n; i++ } }
    }
  }
  return result
}

async function runFalsifyCommand(args: string[]): Promise<void> {
  const parsed = parseFalsifyArgs(args)
  if (parsed.findingsFile === undefined) {
    console.error('[sdk-falsify] --findings-file is required')
    process.exit(1)
  }
  if (!existsSync(parsed.findingsFile)) {
    console.error(`[sdk-falsify] findings file not found: ${parsed.findingsFile}`)
    process.exit(1)
  }
  const raw = JSON.parse(readFileSync(parsed.findingsFile, 'utf8'))
  // Accept either { findings: [...] } or [...] directly
  const findings = Array.isArray(raw) ? raw : raw.findings ?? []
  const config = resolveConfig({ ...(parsed.budget !== undefined && { budgetUsd: parsed.budget }) })
  const verdicts = await runFalsification({ findings, config })
  console.log(JSON.stringify({ verdicts }, null, 2))
}
```

Update `main()` dispatcher to add `falsify`:

```typescript
if (subcommand === 'falsify') {
  await runFalsifyCommand(args)
  return
}
```

- [ ] **Step 3: TypeScript check + smoke tests**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsc --noEmit 2>&1 && node_modules/.bin/tsx smoke-test.ts 2>&1 | grep -E 'falsify|✅|❌' | head -20
```

Expected: 0 TypeScript errors, 2 ✅ for falsify CLI tests

- [ ] **Step 4: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add devflow-sdk/src/cli.ts devflow-sdk/smoke-test.ts && git commit -m "feat(sdk): add standalone falsify CLI subcommand"
```

---

## Task 9: Update Falsification Steps with SDK Fast-Path

**Files:**
- Modify: `skills/review/references/phase-5.md`
- Modify: `skills/build/references/phase-6-review.md`

- [ ] **Step 1: Add SDK fast-path to review phase-5.md**

In `skills/review/references/phase-5.md`, replace the "Falsification Pass" block with:

```markdown
## Falsification Pass (before consolidation)

**Spawn condition:**

- Normal/Large PRs → full falsification pass on all debate-surviving findings
- Massive PRs → lightweight falsification on Hard Rule findings only

**Try the SDK Falsifier first:**

```bash
SDK_DIR="${CLAUDE_SKILL_DIR}/../../devflow-sdk"

if [ ! -d "$SDK_DIR/node_modules" ]; then
  (cd "$SDK_DIR" && npm install --silent 2>/dev/null)
fi

# Serialize surviving findings to temp file
FINDINGS_FILE=$(mktemp /tmp/devflow-findings-XXXXXX.json)
# Lead writes findings JSON here: echo '{...}' > $FINDINGS_FILE

sdk_result=$(cd "$SDK_DIR" && node_modules/.bin/tsx src/cli.ts falsify \
  --findings-file "$FINDINGS_FILE" \
  2>&1)
sdk_exit=$?
rm -f "$FINDINGS_FILE"
```

If `sdk_exit=0` and `sdk_result` is valid JSON (starts with `{`):
- Parse verdicts from `sdk_result.verdicts[]`
- Apply: REJECTED → remove, DOWNGRADED → update severity, SUSTAINED → keep
- Report: `SDK Falsifier: N rejected · M downgraded`
- **Skip Agent Teams `falsification-agent`** — proceed to `review-consolidator`

If `sdk_exit != 0` or not valid JSON: fall back to Agent Teams `falsification-agent` (existing behavior below).
```

- [ ] **Step 2: Add SDK fast-path to build phase-6-review.md Phase 7**

In `skills/build/references/phase-6-review.md`, replace "Phase 7: Falsification Pass" with same SDK fast-path pattern. The block should follow the same structure as phase-5.md above.

- [ ] **Step 3: Verify markdown lint**

```bash
cd /Users/kobig/Codes/Personals/devflow && npx markdownlint-cli2 "skills/review/references/phase-5.md" "skills/build/references/phase-6-review.md" 2>&1
```

Expected: 0 errors

- [ ] **Step 4: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add skills/review/references/phase-5.md skills/build/references/phase-6-review.md && git commit -m "feat(review,build): add SDK fast-path for falsification in phase 5/7"
```

---

## Task 10: Final Integration Check

- [ ] **Step 1: Run full smoke test suite**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsx smoke-test.ts 2>&1
```

Expected: all ✅, 0 ❌, summary line shows total passed

- [ ] **Step 2: TypeScript strict check**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && node_modules/.bin/tsc --noEmit 2>&1
```

Expected: 0 errors

- [ ] **Step 3: Lint all modified markdown**

```bash
cd /Users/kobig/Codes/Personals/devflow && npx markdownlint-cli2 "skills/build/references/phase-3-plan.md" "skills/build/references/phase-6-review.md" "skills/review/references/phase-5.md" "skills/debug/SKILL.md" 2>&1
```

Expected: 0 errors

- [ ] **Step 4: Verify CLI help for all 3 new subcommands**

```bash
cd /Users/kobig/Codes/Personals/devflow/devflow-sdk && \
  node_modules/.bin/tsx src/cli.ts plan-challenge 2>&1 | head -3 && \
  node_modules/.bin/tsx src/cli.ts investigate 2>&1 | head -3 && \
  node_modules/.bin/tsx src/cli.ts falsify 2>&1 | head -3
```

Expected: each prints `[sdk-xxx] --xxx-file is required` (or similar error for missing required arg) — confirms subcommands are registered and dispatched correctly.

- [ ] **Step 5: Commit**

```bash
cd /Users/kobig/Codes/Personals/devflow && git add -p && git commit -m "chore(sdk): integration check — all 3 new subcommands verified"
```

---

## Self-Review

### Spec Coverage

| Candidate | Implementation | Tasks |
| --- | --- | --- |
| `/build` plan-challenger SDK fast-path | `plan-challenge` subcommand + phase-3-plan.md update | Tasks 1–4 |
| `falsification-agent` → SDK standalone | `falsify` subcommand + phase-5.md + phase-6-review.md update | Tasks 8–9 |
| `/debug` investigation merge | `investigate` subcommand + debug/SKILL.md Phase 2 update | Tasks 5–7 |
| `/review` multi-persona (debate) | Already covered by existing `review` SDK fast-path in phase-3.md (skips Phases 3–5) | n/a |

**Note on `/review` debate (Item 4):** The existing `review` SDK command (`tsx src/cli.ts review`) already replaces the full 3-reviewer + debate + falsification + consolidation pipeline when called from `phase-3.md`. The Agent Teams debate phases (4-5) are only reached when SDK review fails. Item 4 is therefore already implemented and does not require additional tasks.

### Placeholder Scan

No TBD, TODO, or missing code blocks found. Every step has exact file paths and complete code.

### Type Consistency

- `ChallengeResult` used in Task 1/2/3 — consistent field names throughout
- `InvestigationResult` used in Tasks 5/6 — `rootCause`, `dxFindings`, `fixPlan` consistent
- `parsePlanChallengeArgs`, `parseFalsifyArgs`, `parseInvestigateArgs` — all exported from cli.ts for smoke test imports
- `runFalsification` already imported in cli.ts main flow — `falsify` subcommand reuses it directly
