# Prompt F: Custom Agent Loop + Reviewer Prompt Caching

**Opportunity:** สร้าง reusable `agentLoop()` ที่ใช้ direct Anthropic SDK พร้อม prompt caching, จากนั้น migrate reviewer จาก Agent SDK `query()` มาใช้มัน
**Impact:** System prompt ของ reviewer (~2000+ tokens: shared rules + hard rules + lens) ถูก cache หลัง call แรก — ราคา cache read ~0.1x + Agent SDK dependency เริ่มถูกลดทอน
**Files ที่สร้าง/แก้:**

- **NEW** `anvil-sdk/src/agent-loop.ts` — generic agent loop utility
- `anvil-sdk/src/review/agents/reviewer.ts` — rewrite ให้ใช้ agentLoop แทน AgentDefinition
- `anvil-sdk/src/review/orchestrator.ts` — เปลี่ยน runSingleReviewer ให้ใช้ reviewer function ใหม่
- `anvil-sdk/smoke-test.ts` — เพิ่ม agent loop unit tests

**ขึ้นอยู่กับ:** ไม่มี. แต่ Prompt H ต้องใช้ agent-loop.ts จาก Prompt นี้

---

## ทำไม Reviewer ถึง Migrate ได้

Reviewer ใช้ tool ในการตรวจสอบ surrounding code จริงๆ (Read/Grep/Glob) ต่างจาก falsifier ที่ไม่ต้องการ tools เลย Agent SDK ไม่ support `cache_control` บน system prompt → ต้องสร้าง agent loop เอง

แต่ reviewer มี diff inline ใน prompt อยู่แล้ว — tool use เป็น supplementary (verify hunches, read context) ไม่ใช่ primary path ดังนั้น:

1. Direct API `messages.create()` loop ทำงานได้
2. Manual tool dispatch ไม่ซับซ้อน — Read/Grep/Glob เป็น file system ops
3. System prompt cached → ประหยัด cost สูงมากบน review ที่ run หลายครั้ง

---

## Step 1: สร้าง src/agent-loop.ts

```typescript
import { execSync, execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import Anthropic from '@anthropic-ai/sdk'
import { MODEL_ID, type ModelName } from './config.js'

export type AllowedTool = 'Read' | 'Grep' | 'Glob' | 'Bash'

export interface AgentLoopParams {
  model: ModelName
  systemPrompt: string             // cached via cache_control: ephemeral
  userMessage: string
  allowedTools: AllowedTool[]
  outputSchema: Record<string, unknown>
  maxTurns: number
  maxBudgetUsd: number
}

export interface AgentLoopResult {
  text: string
  inputTokens: number
  outputTokens: number
  cacheReadTokens: number
  cacheWriteTokens: number
  turnsUsed: number
}
```

### Tool Definitions

```typescript
const TOOL_DEFINITIONS: Record<AllowedTool, Anthropic.Tool> = {
  Read: {
    name: 'Read',
    description: 'Read a file from the filesystem',
    input_schema: {
      type: 'object',
      properties: {
        file_path: { type: 'string', description: 'Absolute or relative file path' },
        limit: { type: 'number', description: 'Max lines to read (optional)' },
        offset: { type: 'number', description: 'Line offset to start from (optional)' },
      },
      required: ['file_path'],
    },
  },
  Grep: {
    name: 'Grep',
    description: 'Search file contents with regex using ripgrep',
    input_schema: {
      type: 'object',
      properties: {
        pattern: { type: 'string', description: 'Regex pattern' },
        path: { type: 'string', description: 'File or directory to search (optional)' },
        glob: { type: 'string', description: 'Glob filter e.g. "*.ts" (optional)' },
        output_mode: { type: 'string', enum: ['content', 'files_with_matches', 'count'], description: 'Output format (optional)' },
      },
      required: ['pattern'],
    },
  },
  Glob: {
    name: 'Glob',
    description: 'Find files matching a glob pattern',
    input_schema: {
      type: 'object',
      properties: {
        pattern: { type: 'string', description: 'Glob pattern e.g. "**/*.ts"' },
        path: { type: 'string', description: 'Base directory (optional)' },
      },
      required: ['pattern'],
    },
  },
  Bash: {
    name: 'Bash',
    description: 'Run a shell command (read-only: git log, git blame, etc.)',
    input_schema: {
      type: 'object',
      properties: {
        command: { type: 'string', description: 'Shell command to execute' },
      },
      required: ['command'],
    },
  },
}
```

### Tool Executor

```typescript
function executeTool(name: AllowedTool, input: Record<string, unknown>): string {
  try {
    switch (name) {
      case 'Read': {
        const path = input.file_path as string
        const content = readFileSync(path, 'utf8')
        const lines = content.split('\n')
        const offset = (input.offset as number | undefined) ?? 0
        const limit = (input.limit as number | undefined) ?? lines.length
        return lines.slice(offset, offset + limit).join('\n')
      }
      case 'Grep': {
        const args = ['--no-heading', '-n']
        if (input.glob) args.push('--glob', input.glob as string)
        if (input.output_mode === 'files_with_matches') args.push('-l')
        else if (input.output_mode === 'count') args.push('--count')
        args.push(input.pattern as string)
        if (input.path) args.push(input.path as string)
        return execFileSync('rg', args, { encoding: 'utf8', timeout: 15000 })
      }
      case 'Glob': {
        const args = ['.', '--glob', input.pattern as string, '--type', 'f']
        if (input.path) args.unshift(input.path as string)
        return execFileSync('fd', args, { encoding: 'utf8', timeout: 15000 })
      }
      case 'Bash': {
        return execSync(input.command as string, { encoding: 'utf8', timeout: 15000 })
      }
    }
  } catch (err: unknown) {
    // Return error as content so model can self-correct (e.g., file not found)
    const msg = err instanceof Error ? err.message : String(err)
    // Non-zero exit from rg/fd means no matches — return empty string, not error
    if (msg.includes('status 1') && (name === 'Grep' || name === 'Glob')) return ''
    return `[tool error] ${name}: ${msg}`
  }
}
```

### Main agentLoop Function

```typescript
export async function agentLoop(params: AgentLoopParams): Promise<AgentLoopResult> {
  const client = new Anthropic()
  const tools = params.allowedTools.map(t => TOOL_DEFINITIONS[t])

  const messages: Anthropic.MessageParam[] = [
    { role: 'user', content: params.userMessage },
  ]

  let totalInput = 0
  let totalOutput = 0
  let totalCacheRead = 0
  let totalCacheWrite = 0
  let turnsUsed = 0

  for (let turn = 0; turn < params.maxTurns; turn++) {
    turnsUsed++

    const response = await client.messages.create({
      model: MODEL_ID[params.model],
      max_tokens: 4096,
      system: [
        {
          type: 'text',
          text: params.systemPrompt,
          cache_control: { type: 'ephemeral' },
        },
      ],
      tools,
      output_config: {
        format: {
          type: 'json_schema',
          schema: params.outputSchema,
        },
      },
      messages,
    })

    const usage = response.usage as unknown as Record<string, number>
    totalInput += usage.input_tokens ?? 0
    totalOutput += usage.output_tokens ?? 0
    totalCacheRead += usage.cache_read_input_tokens ?? 0
    totalCacheWrite += usage.cache_creation_input_tokens ?? 0

    // Collect tool_use blocks and text block
    const toolUseBlocks = response.content.filter(
      (b): b is Anthropic.ToolUseBlock => b.type === 'tool_use'
    )
    const textBlock = response.content.find(
      (b): b is Anthropic.TextBlock => b.type === 'text'
    )

    if (toolUseBlocks.length === 0) {
      // No tool calls — final response
      const text = textBlock?.text ?? ''
      return { text, inputTokens: totalInput, outputTokens: totalOutput, cacheReadTokens: totalCacheRead, cacheWriteTokens: totalCacheWrite, turnsUsed }
    }

    // Execute tools and build tool_result response
    messages.push({ role: 'assistant', content: response.content })

    const toolResults: Anthropic.ToolResultBlockParam[] = toolUseBlocks.map(block => ({
      type: 'tool_result',
      tool_use_id: block.id,
      content: executeTool(block.name as AllowedTool, block.input as Record<string, unknown>),
    }))

    messages.push({ role: 'user', content: toolResults })
  }

  // Max turns reached — return last text block if any
  const lastText = messages.findLast(m => {
    if (typeof m.content === 'string') return true
    return Array.isArray(m.content) && m.content.some(b => (b as { type: string }).type === 'text')
  })
  const text = lastText ? '' : ''  // best-effort empty on turn exhaustion
  console.warn(`[agent-loop] max turns (${params.maxTurns}) reached for model ${params.model}`)
  return { text, inputTokens: totalInput, outputTokens: totalOutput, cacheReadTokens: totalCacheRead, cacheWriteTokens: totalCacheWrite, turnsUsed }
}
```

**หมายเหตุ:** `output_config.format.json_schema` บังคับให้ final response เป็น JSON ตาม schema พอดี ไม่ต้องมี retry loop สำหรับ JSON parsing

---

## Step 2: rewrite reviewer.ts

```typescript
// ก่อน — export function createReviewer() ที่ return AgentDefinition
// หลัง — export function runReviewer() ที่ return ReviewerResult โดยตรง

import { agentLoop } from '../../agent-loop.js'
import { MODEL_ID } from '../../config.js'
import type { ResolvedConfig } from '../../config.js'
import type { DiffBucket, ReviewerResult } from '../../types.js'
// ... existing imports for lenses, prompts, schemas

export async function runReviewer(params: {
  bucket: DiffBucket
  hardRules: string
  dismissedPatterns: string
  isAdonisProject: boolean
  config: ResolvedConfig
}): Promise<ReviewerResult> {
  const lensContent = getLensesForRole(params.bucket.role, params.isAdonisProject)
  const diffContent = params.bucket.files
    .map(f => `### ${f.path}\n\`\`\`${f.language}\n${f.hunks}\n\`\`\``)
    .join('\n\n')

  const promptConfig = { diffContent, sharedRules: SHARED_RULES, hardRules: params.hardRules, lensContent, dismissedPatterns: params.dismissedPatterns }
  let systemPrompt: string
  switch (params.bucket.role) {
    case 'correctness': systemPrompt = buildReviewer1Prompt(promptConfig); break
    case 'architecture': systemPrompt = buildReviewer2Prompt(promptConfig); break
    case 'dx': systemPrompt = buildReviewer3Prompt(promptConfig); break
  }

  let result: Awaited<ReturnType<typeof agentLoop>>
  try {
    result = await agentLoop({
      model: params.config.model,
      systemPrompt,
      userMessage: 'Review the code changes in your context and return findings as JSON.',
      allowedTools: ['Read', 'Grep', 'Glob'],
      outputSchema: findingResultJsonSchema as Record<string, unknown>,
      maxTurns: params.config.maxTurnsReviewer,
      maxBudgetUsd: params.config.maxBudgetPerReviewer,
    })
  } catch (err) {
    console.warn(`[sdk-review] reviewer (${params.bucket.role}) API call failed: ${String(err)}`)
    return { findings: [], strengths: [], cost: 0, tokens: 0 }
  }

  if (!result.text) {
    console.warn(`[sdk-review] reviewer (${params.bucket.role}) returned no text — skipping`)
    return { findings: [], strengths: [], cost: 0, tokens: 0 }
  }

  let parsed: ReturnType<typeof FindingResultSchema.safeParse>
  try {
    parsed = FindingResultSchema.safeParse(JSON.parse(result.text))
  } catch {
    console.warn(`[sdk-review] reviewer (${params.bucket.role}) returned invalid JSON — skipping`)
    return { findings: [], strengths: [], cost: 0, tokens: 0 }
  }

  if (!parsed.success) {
    console.warn(`[sdk-review] reviewer (${params.bucket.role}) schema failed — skipping`)
    return { findings: [], strengths: [], cost: 0, tokens: 0 }
  }

  // Rough cost estimate: sonnet input=$3/1M, output=$15/1M, cache_read=$0.3/1M
  const inputCost = ((result.inputTokens - result.cacheReadTokens) * 3 + result.cacheReadTokens * 0.3 + result.cacheWriteTokens * 3.75) / 1_000_000
  const outputCost = result.outputTokens * 15 / 1_000_000
  const cost = inputCost + outputCost

  return {
    findings: parsed.data.findings,
    strengths: parsed.data.strengths ?? [],
    cost,
    tokens: result.inputTokens + result.outputTokens,
  }
}
```

---

## Step 3: orchestrator.ts — ใช้ runReviewer แทน createReviewer + query

```typescript
// ก่อน
import { createReviewer } from './agents/reviewer.js'
// ...
async function runSingleReviewer(params): Promise<ReviewerResult> {
  const agent = createReviewer({ ... })
  for await (const msg of query({ agents: { reviewer: agent }, ... })) { ... }
}

// หลัง
import { runReviewer } from './agents/reviewer.js'
// ...
async function runSingleReviewer(params): Promise<ReviewerResult> {
  return runReviewer(params)  // รับ params เดิมทุกอย่าง
}
```

ลบ `import { query } from '@anthropic-ai/claude-agent-sdk'` ออกจาก orchestrator.ts (ถ้า orchestrator เป็นไฟล์เดียวที่ใช้ query)

---

## Smoke Tests เพิ่ม

```typescript
test('agentLoop tool dispatch: executeTool Read returns file content', () => {
  // เขียน temp file แล้ว read ผ่าน executeTool (unit test tool executor)
  import { writeFileSync, unlinkSync } from 'node:fs'
  const tmpPath = '/tmp/agent-loop-test.txt'
  writeFileSync(tmpPath, 'hello world\n')
  // Import executeTool — ต้อง export เป็น internal function ถ้าจะ test
  // Alternative: test through integration (agentLoop with mock Anthropic client)
  unlinkSync(tmpPath)
})

test('agentLoop with no tool calls returns text immediately', async () => {
  // Mock Anthropic client ที่ return text block ทันที (no tool_use)
  // Verify turnsUsed === 1
})
```

**หมายเหตุเรื่อง cost estimate:** ราคา hardcode ใน `runReviewer()` ต้องอัปเดตถ้าเปลี่ยน model ทางแก้ที่ดีกว่าในอนาคต: เพิ่ม price table ใน `config.ts` ต่อ `ModelName`

---

## Verify

```bash
cd anvil-sdk && npx tsc --noEmit && npx tsx smoke-test.ts
# ทดสอบ integration จริง (ต้องมี ANTHROPIC_API_KEY):
# npx tsx src/cli.ts review --branch HEAD~1 --output json
```
