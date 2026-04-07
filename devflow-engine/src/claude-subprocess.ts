/**
 * Thin wrapper around `claude -p` (non-interactive mode).
 * Runs Claude via the CLI using subscription OAuth — no ANTHROPIC_API_KEY required.
 *
 * Usage:
 *   const result = await runClaudeSubprocess({
 *     systemPrompt: SOME_PROMPT,
 *     userMessage: 'Do X and return JSON.',
 *     allowedTools: ['Read', 'Grep', 'Glob'],
 *     outputSchema: someJsonSchema,
 *     maxTurns: 5,
 *     maxBudgetUsd: 0.15,
 *     model: 'claude-haiku-4-5-20251001',
 *   })
 *   const data = SomeSchema.safeParse(result.structuredOutput)
 */
import { execFile } from 'node:child_process'
import { randomUUID } from 'node:crypto'
import { writeFile, unlink } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

export interface SubprocessParams {
  systemPrompt: string
  userMessage: string
  allowedTools?: string[]
  outputSchema?: Record<string, unknown>
  maxTurns?: number
  maxBudgetUsd?: number
  /** Full model ID (e.g. 'claude-sonnet-4-6') or alias ('sonnet', 'opus'). Passed as --model to claude -p. */
  model?: string
}

export interface SubprocessResult {
  /** Final text response (when no --json-schema, or as fallback) */
  text: string
  /** Parsed structured output — present when --json-schema was used */
  structuredOutput: unknown
  /** Total cost in USD from total_cost_usd field */
  costUsd: number
  /** Total tokens processed: input + cache_creation + cache_read + output */
  tokens: number
  /** True when claude reports budget_exceeded — caller may skip re-run rather than retry */
  budgetExceeded?: boolean
}

interface ClaudeJsonOutput {
  type?: string
  subtype?: string
  result?: string
  structured_output?: unknown
  is_error?: boolean
  total_cost_usd?: number
  usage?: {
    input_tokens?: number
    output_tokens?: number
    cache_creation_input_tokens?: number
    cache_read_input_tokens?: number
  }
}

/** Subtypes that indicate a transient API condition — safe to retry with backoff. */
const RETRYABLE_SUBTYPES = new Set([
  'rate_limit_exceeded',
  'server_error',
  'internal_error',
  'overloaded_error',
])

const MAX_RETRIES = 3

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

function buildTokenCount(usage: ClaudeJsonOutput['usage']): number {
  return (usage?.input_tokens ?? 0)
    + (usage?.cache_creation_input_tokens ?? 0)
    + (usage?.cache_read_input_tokens ?? 0)
    + (usage?.output_tokens ?? 0)
}

async function runClaudeSubprocessOnce(params: SubprocessParams, tmpPath: string): Promise<SubprocessResult> {
  const args: string[] = [
    '-p', params.userMessage,
    '--output-format', 'json',
    '--system-prompt-file', tmpPath,
    '--dangerously-skip-permissions',
    '--no-session-persistence',
  ]

  if (params.allowedTools && params.allowedTools.length > 0) {
    args.push('--allowedTools', params.allowedTools.join(','))
  }
  if (params.outputSchema !== undefined) {
    args.push('--json-schema', JSON.stringify(params.outputSchema))
  }
  if (params.maxTurns !== undefined) {
    args.push('--max-turns', String(params.maxTurns))
  }
  if (params.maxBudgetUsd !== undefined) {
    args.push('--max-budget-usd', String(params.maxBudgetUsd))
  }
  if (params.model !== undefined) {
    args.push('--model', params.model)
  }

  const { stdout, stderr } = await new Promise<{ stdout: string; stderr: string }>((resolve, reject) => {
    execFile('claude', args, { encoding: 'utf8', timeout: 300_000 }, (err, out, errOut) => {
      if (out) {
        // stdout takes priority — claude outputs JSON even on non-zero exit
        resolve({ stdout: out, stderr: errOut })
      } else if (err) {
        reject(new Error(`[claude-subprocess] no output: ${err.message}${errOut ? `\nstderr: ${errOut.slice(0, 500)}` : ''}`))
      } else {
        resolve({ stdout: '', stderr: errOut })
      }
    })
  })

  let output: ClaudeJsonOutput
  try {
    output = JSON.parse(stdout) as ClaudeJsonOutput
  } catch {
    const hint = stderr ? ` stderr: ${stderr.slice(0, 200)}` : ''
    throw new Error(`[claude-subprocess] invalid JSON: ${stdout.slice(0, 200)}${hint}`)
  }

  if (output.is_error === true) {
    const sub = output.subtype ?? 'unknown'
    // Budget exhausted — not an error to propagate; return signal so caller can skip re-run
    if (sub === 'budget_exceeded') {
      return {
        text: output.result ?? '',
        structuredOutput: output.structured_output,
        costUsd: output.total_cost_usd ?? 0,
        tokens: buildTokenCount(output.usage),
        budgetExceeded: true,
      }
    }
    const stderrHint = stderr ? ` stderr: ${stderr.slice(0, 200)}` : ''
    throw new Error(`[claude-subprocess] ${sub}${stderrHint}`)
  }

  return {
    text: output.result ?? '',
    structuredOutput: output.structured_output,
    costUsd: output.total_cost_usd ?? 0,
    tokens: buildTokenCount(output.usage),
  }
}

export async function runClaudeSubprocess(params: SubprocessParams): Promise<SubprocessResult> {
  const tmpPath = join(tmpdir(), `devflow-sys-${randomUUID()}.txt`)

  try {
    await writeFile(tmpPath, params.systemPrompt, 'utf8')

    let lastError: Error | undefined
    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
      if (attempt > 0) {
        // Read at call time so tests can override via DEVFLOW_RETRY_DELAY_MS=0
        const baseMs = Number(process.env['DEVFLOW_RETRY_DELAY_MS'] ?? '1000')
        const delay = baseMs * Math.pow(2, attempt - 1) // 1s, 2s (or 0 in tests)
        console.warn(`[claude-subprocess] attempt ${attempt + 1}/${MAX_RETRIES} after ${delay}ms`)
        await sleep(delay)
      }

      try {
        return await runClaudeSubprocessOnce(params, tmpPath)
      } catch (err) {
        lastError = err instanceof Error ? err : new Error(String(err))
        // Extract subtype from error message to decide retryability
        const subtypeMatch = lastError.message.match(/\[claude-subprocess\] ([\w_-]+)/)
        const subtype = subtypeMatch?.[1]
        // Non-retryable or last attempt — propagate immediately
        if (subtype !== undefined && !RETRYABLE_SUBTYPES.has(subtype)) throw lastError
        if (attempt === MAX_RETRIES - 1) throw lastError
        console.warn(`[claude-subprocess] transient error (${lastError.message}), will retry`)
      }
    }

    throw lastError ?? new Error('[claude-subprocess] unexpected retry exit')
  } finally {
    unlink(tmpPath).catch(() => { /* ignore cleanup errors */ })
  }
}
