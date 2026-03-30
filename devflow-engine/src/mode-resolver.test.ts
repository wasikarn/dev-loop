import { describe, expect, it } from 'bun:test'
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
