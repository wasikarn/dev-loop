/**
 * Tests for runClaudeSubprocess — retry logic, budgetExceeded signal, stderr capture.
 *
 * Set DEVFLOW_RETRY_DELAY_MS=0 so retry tests run instantly without sleeping.
 */
import { describe, expect, it, mock, beforeEach, afterEach } from 'bun:test'

// ─── Mock external I/O ───────────────────────────────────────────────────────
const mockExecFile = mock()
mock.module('node:child_process', () => ({ execFile: mockExecFile }))
mock.module('node:fs/promises', () => ({
  writeFile: mock(async () => {}),
  unlink: mock(async () => {}),
}))

// ─── Import SUT after mocks ──────────────────────────────────────────────────
import { runClaudeSubprocess } from './claude-subprocess.js'

// ─── Helpers ─────────────────────────────────────────────────────────────────

function makeOutput(override: Record<string, unknown> = {}): string {
  return JSON.stringify({
    type: 'result',
    subtype: 'success',
    result: 'ok',
    is_error: false,
    total_cost_usd: 0.01,
    usage: { input_tokens: 100, output_tokens: 50, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 },
    ...override,
  })
}

function makeError(subtype: string, costUsd = 0): string {
  return JSON.stringify({
    type: 'result',
    subtype,
    result: '',
    is_error: true,
    total_cost_usd: costUsd,
    usage: { input_tokens: 0, output_tokens: 0, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 },
  })
}

/** Make execFile invoke its callback with stdout and no error. */
function stubSuccess(stdout: string): void {
  mockExecFile.mockImplementation(
    (_cmd: string, _args: string[], _opts: unknown, cb: (err: null, out: string, stderr: string) => void) => {
      cb(null, stdout, '')
    },
  )
}

/** Make execFile invoke its callback with stdout containing an error JSON. */
function stubErrorOutput(stdout: string): void {
  mockExecFile.mockImplementation(
    (_cmd: string, _args: string[], _opts: unknown, cb: (err: null, out: string, stderr: string) => void) => {
      cb(null, stdout, '')
    },
  )
}

/** Make execFile invoke its callback with no stdout and an error (process crash). */
function stubProcessCrash(message: string, stderr = ''): void {
  mockExecFile.mockImplementation(
    (_cmd: string, _args: string[], _opts: unknown, cb: (err: Error, out: string, stderr: string) => void) => {
      cb(new Error(message), '', stderr)
    },
  )
}

const MIN_PARAMS = {
  systemPrompt: 'sys',
  userMessage: 'msg',
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('runClaudeSubprocess', () => {
  beforeEach(() => {
    mockExecFile.mockReset()
    process.env['DEVFLOW_RETRY_DELAY_MS'] = '0'
  })

  afterEach(() => {
    delete process.env['DEVFLOW_RETRY_DELAY_MS']
  })

  describe('happy path', () => {
    it('returns text, cost, and tokens on success', async () => {
      stubSuccess(makeOutput({ result: 'hello', structured_output: { x: 1 } }))
      const result = await runClaudeSubprocess(MIN_PARAMS)

      expect(result.text).toBe('hello')
      expect(result.structuredOutput).toEqual({ x: 1 })
      expect(result.costUsd).toBe(0.01)
      expect(result.tokens).toBe(150) // 100 + 50
      expect(result.budgetExceeded).toBeUndefined()
    })

    it('sums all token fields correctly', async () => {
      stubSuccess(makeOutput({
        usage: { input_tokens: 100, output_tokens: 50, cache_creation_input_tokens: 20, cache_read_input_tokens: 10 },
      }))
      const result = await runClaudeSubprocess(MIN_PARAMS)
      expect(result.tokens).toBe(180) // 100+50+20+10
    })
  })

  describe('budgetExceeded signal', () => {
    it('returns budgetExceeded:true and preserves cost instead of throwing', async () => {
      stubErrorOutput(makeError('budget_exceeded', 0.05))
      const result = await runClaudeSubprocess(MIN_PARAMS)

      expect(result.budgetExceeded).toBe(true)
      expect(result.costUsd).toBe(0.05)
      // Should NOT have thrown
    })

    it('does not retry on budget_exceeded', async () => {
      stubErrorOutput(makeError('budget_exceeded', 0.05))
      await runClaudeSubprocess(MIN_PARAMS)
      expect(mockExecFile.mock.calls.length).toBe(1)
    })
  })

  describe('retry on transient errors', () => {
    it('retries rate_limit_exceeded and succeeds on second attempt', async () => {
      let calls = 0
      mockExecFile.mockImplementation(
        (_cmd: string, _args: string[], _opts: unknown, cb: (err: null, out: string, stderr: string) => void) => {
          calls++
          if (calls === 1) {
            cb(null, makeError('rate_limit_exceeded'), '')
          } else {
            cb(null, makeOutput({ result: 'done' }), '')
          }
        },
      )

      const result = await runClaudeSubprocess(MIN_PARAMS)
      expect(result.text).toBe('done')
      expect(mockExecFile.mock.calls.length).toBe(2)
    })

    it('retries server_error up to MAX_RETRIES then throws', async () => {
      stubErrorOutput(makeError('server_error'))
      await expect(runClaudeSubprocess(MIN_PARAMS)).rejects.toThrow('server_error')
      expect(mockExecFile.mock.calls.length).toBe(3) // MAX_RETRIES = 3
    })

    it('retries overloaded_error', async () => {
      let calls = 0
      mockExecFile.mockImplementation(
        (_cmd: string, _args: string[], _opts: unknown, cb: (err: null, out: string, stderr: string) => void) => {
          calls++
          cb(null, calls < 3 ? makeError('overloaded_error') : makeOutput(), '')
        },
      )
      await runClaudeSubprocess(MIN_PARAMS)
      expect(mockExecFile.mock.calls.length).toBe(3)
    })
  })

  describe('non-retryable errors', () => {
    it('throws immediately on unknown subtype without retrying', async () => {
      stubErrorOutput(makeError('unknown'))
      await expect(runClaudeSubprocess(MIN_PARAMS)).rejects.toThrow('unknown')
      expect(mockExecFile.mock.calls.length).toBe(1)
    })

    it('throws immediately on invalid_api_key without retrying', async () => {
      stubErrorOutput(makeError('invalid_api_key'))
      await expect(runClaudeSubprocess(MIN_PARAMS)).rejects.toThrow('invalid_api_key')
      expect(mockExecFile.mock.calls.length).toBe(1)
    })
  })

  describe('stderr capture', () => {
    it('includes stderr in error message when process crashes with no stdout', async () => {
      stubProcessCrash('SIGTERM', 'claude: authentication failed')
      await expect(runClaudeSubprocess(MIN_PARAMS)).rejects.toThrow('authentication failed')
    })

    it('includes stderr hint in invalid JSON error', async () => {
      mockExecFile.mockImplementation(
        (_cmd: string, _args: string[], _opts: unknown, cb: (err: null, out: string, stderr: string) => void) => {
          cb(null, 'not-json', 'internal panic')
        },
      )
      await expect(runClaudeSubprocess(MIN_PARAMS)).rejects.toThrow('internal panic')
    })
  })
})
