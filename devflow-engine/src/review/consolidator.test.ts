import { describe, it, expect } from 'bun:test'
import { consolidate, findingKey } from './consolidator.js'
import type { Finding, Verdict } from '../types.js'

// ─── fixtures ────────────────────────────────────────────────────────────────

function makeFinding(overrides: Partial<Finding> = {}): Finding {
  return {
    severity: 'warning',
    rule: 'NO_ANY',
    file: 'src/foo.ts',
    line: 10,
    confidence: 80,
    issue: 'uses any',
    fix: 'use unknown',
    isHardRule: false,
    ...overrides,
  }
}

const BASE_PARAMS = { autoPass: [], verdicts: [], patternCapCount: 3 }

// ─── findingKey ───────────────────────────────────────────────────────────────

describe('findingKey', () => {
  it('returns file:line:rule', () => {
    const f = makeFinding({ file: 'src/a.ts', line: 5, rule: 'NULL_CHECK' })
    expect(findingKey(f)).toBe('src/a.ts:5:NULL_CHECK')
  })

  it('uses "null" when line is null', () => {
    const f = makeFinding({ line: null })
    expect(findingKey(f)).toBe('src/foo.ts:null:NO_ANY')
  })
})

// ─── consolidate — empty inputs ───────────────────────────────────────────────

describe('consolidate — empty', () => {
  it('returns [] when no findings', () => {
    const result = consolidate({ perReviewer: [], ...BASE_PARAMS })
    expect(result).toEqual([])
  })

  it('returns [] when all reviewers have empty findings', () => {
    const result = consolidate({
      perReviewer: [
        { role: 'correctness', findings: [] },
        { role: 'architecture', findings: [] },
      ],
      ...BASE_PARAMS,
    })
    expect(result).toEqual([])
  })
})

// ─── consolidate — verdict application ───────────────────────────────────────

describe('consolidate — verdicts', () => {
  it('REJECTED verdict removes finding', () => {
    const f = makeFinding()
    const verdict: Verdict = {
      findingIndex: 0,
      findingKey: findingKey(f),
      originalSummary: '',
      verdict: 'REJECTED',
      rationale: 'false positive',
    }
    const result = consolidate({
      perReviewer: [{ role: 'correctness', findings: [f] }],
      autoPass: [],
      verdicts: [verdict],
      patternCapCount: 3,
    })
    expect(result).toEqual([])
  })

  it('SUSTAINED verdict keeps finding unchanged', () => {
    const f = makeFinding()
    const verdict: Verdict = {
      findingIndex: 0,
      findingKey: findingKey(f),
      originalSummary: '',
      verdict: 'SUSTAINED',
      rationale: 'legit issue',
    }
    const result = consolidate({
      perReviewer: [{ role: 'correctness', findings: [f] }],
      autoPass: [],
      verdicts: [verdict],
      patternCapCount: 3,
    })
    expect(result).toHaveLength(1)
    expect(result[0]?.severity).toBe('warning')
  })

  it('DOWNGRADED verdict changes severity', () => {
    const f = makeFinding({ severity: 'critical' })
    const verdict: Verdict = {
      findingIndex: 0,
      findingKey: findingKey(f),
      originalSummary: '',
      verdict: 'DOWNGRADED',
      newSeverity: 'warning',
      rationale: 'less severe than reported',
    }
    const result = consolidate({
      perReviewer: [{ role: 'correctness', findings: [f] }],
      autoPass: [],
      verdicts: [verdict],
      patternCapCount: 3,
    })
    expect(result).toHaveLength(1)
    expect(result[0]?.severity).toBe('warning')
  })

  it('finding with no matching verdict is kept', () => {
    const f = makeFinding()
    const result = consolidate({
      perReviewer: [{ role: 'correctness', findings: [f] }],
      ...BASE_PARAMS,
    })
    expect(result).toHaveLength(1)
  })
})

// ─── consolidate — deduplication + consensus ─────────────────────────────────

describe('consolidate — dedup and consensus', () => {
  it('same finding from two reviewers → consensus "2/2"', () => {
    const f = makeFinding()
    const result = consolidate({
      perReviewer: [
        { role: 'correctness', findings: [f] },
        { role: 'architecture', findings: [f] },
      ],
      ...BASE_PARAMS,
    })
    expect(result).toHaveLength(1)
    expect(result[0]?.consensus).toBe('2/2')
  })

  it('finding from one of two reviewers → consensus "1/2"', () => {
    const f = makeFinding()
    const result = consolidate({
      perReviewer: [
        { role: 'correctness', findings: [f] },
        { role: 'architecture', findings: [] },
      ],
      ...BASE_PARAMS,
    })
    expect(result).toHaveLength(1)
    expect(result[0]?.consensus).toBe('1/2')
  })

  it('keeps highest severity when same finding reported at different severities', () => {
    const fWarn = makeFinding({ severity: 'warning' })
    const fCrit = makeFinding({ severity: 'critical' })
    const result = consolidate({
      perReviewer: [
        { role: 'correctness', findings: [fWarn] },
        { role: 'architecture', findings: [fCrit] },
      ],
      ...BASE_PARAMS,
    })
    expect(result).toHaveLength(1)
    expect(result[0]?.severity).toBe('critical')
  })
})

// ─── consolidate — autoPass bypass ───────────────────────────────────────────

describe('consolidate — autoPass', () => {
  it('autoPass findings get consensus "auto"', () => {
    const f = makeFinding({ isHardRule: true, confidence: 95 })
    const result = consolidate({
      perReviewer: [],
      autoPass: [f],
      verdicts: [],
      patternCapCount: 3,
    })
    expect(result).toHaveLength(1)
    expect(result[0]?.consensus).toBe('auto')
  })

  it('autoPass findings are NOT subject to falsification verdicts', () => {
    const f = makeFinding({ isHardRule: true, confidence: 95 })
    // Even with a REJECTED verdict, autoPass bypasses falsification entirely
    const result = consolidate({
      perReviewer: [],
      autoPass: [f],
      verdicts: [{ findingIndex: 0, findingKey: findingKey(f), originalSummary: '', verdict: 'REJECTED', rationale: 'x' }],
      patternCapCount: 3,
    })
    expect(result).toHaveLength(1)
  })
})

// ─── consolidate — pattern cap ────────────────────────────────────────────────

describe('consolidate — pattern cap', () => {
  it('caps findings with same rule at patternCapCount (keeps highest severity)', () => {
    const findings = [
      makeFinding({ file: 'a.ts', line: 1, severity: 'critical' }),
      makeFinding({ file: 'b.ts', line: 2, severity: 'warning' }),
      makeFinding({ file: 'c.ts', line: 3, severity: 'info' }),
      makeFinding({ file: 'd.ts', line: 4, severity: 'info' }),
    ]
    const result = consolidate({
      perReviewer: [{ role: 'correctness', findings }],
      verdicts: [],
      autoPass: [],
      patternCapCount: 3,
    })
    expect(result).toHaveLength(3)
    // patternNote added to last kept
    const last = result[2]
    expect(last?.patternNote).toMatch(/\+ 1 more/)
  })

  it('does not cap when findings <= patternCapCount', () => {
    const findings = [
      makeFinding({ file: 'a.ts', line: 1 }),
      makeFinding({ file: 'b.ts', line: 2 }),
    ]
    const result = consolidate({
      perReviewer: [{ role: 'correctness', findings }],
      verdicts: [],
      autoPass: [],
      patternCapCount: 3,
    })
    expect(result).toHaveLength(2)
    expect(result.every(f => f.patternNote === undefined)).toBe(true)
  })
})

// ─── consolidate — sort order ─────────────────────────────────────────────────

describe('consolidate — sort order', () => {
  it('sorts critical before warning before info', () => {
    const findings = [
      makeFinding({ file: 'a.ts', line: 1, severity: 'info' }),
      makeFinding({ file: 'b.ts', line: 2, rule: 'B', severity: 'critical' }),
      makeFinding({ file: 'c.ts', line: 3, rule: 'C', severity: 'warning' }),
    ]
    const result = consolidate({
      perReviewer: [{ role: 'correctness', findings }],
      ...BASE_PARAMS,
    })
    expect(result[0]?.severity).toBe('critical')
    expect(result[1]?.severity).toBe('warning')
    expect(result[2]?.severity).toBe('info')
  })
})

// ─── consolidate — confidence filter ─────────────────────────────────────────

describe('consolidate — confidence filter', () => {
  it('drops non-hard-rule findings below role confidence threshold', () => {
    // correctness threshold = 75
    const lowConf = makeFinding({ confidence: 70, isHardRule: false })
    const result = consolidate({
      perReviewer: [{ role: 'correctness', findings: [lowConf] }],
      ...BASE_PARAMS,
    })
    expect(result).toEqual([])
  })

  it('keeps hard-rule findings regardless of confidence', () => {
    const lowConfHardRule = makeFinding({ confidence: 50, isHardRule: true })
    const result = consolidate({
      perReviewer: [{ role: 'correctness', findings: [lowConfHardRule] }],
      ...BASE_PARAMS,
    })
    expect(result).toHaveLength(1)
  })
})
