import { describe, expect, it } from 'bun:test'
import { triage } from './triage.js'
import type { Finding } from '../types.js'

function makeFinding(overrides: Partial<Finding> = {}): Finding {
  return {
    severity: 'warning',
    rule: 'NO_ANY',
    file: 'src/foo.ts',
    line: 10,
    confidence: 85,
    issue: 'uses any',
    fix: 'use unknown',
    isHardRule: false,
    ...overrides,
  }
}

describe('triage', () => {
  it('hard rule at high confidence → autoPass', () => {
    const f = makeFinding({ isHardRule: true, confidence: 95 })
    const { autoPass, mustFalsify, autoDrop } = triage([f])
    expect(autoPass).toHaveLength(1)
    expect(mustFalsify).toHaveLength(0)
    expect(autoDrop).toHaveLength(0)
  })

  it('hard rule below autoPassThreshold → mustFalsify (not autoDrop)', () => {
    const f = makeFinding({ isHardRule: true, confidence: 80, severity: 'info' })
    const { autoPass, mustFalsify, autoDrop } = triage([f])
    expect(autoPass).toHaveLength(0)
    expect(autoDrop).toHaveLength(0)
    expect(mustFalsify).toHaveLength(1)
  })

  it('non-hard-rule info at low confidence → autoDrop', () => {
    const f = makeFinding({ isHardRule: false, severity: 'info', confidence: 60 })
    const { autoDrop, autoPass, mustFalsify } = triage([f])
    expect(autoDrop).toHaveLength(1)
    expect(autoPass).toHaveLength(0)
    expect(mustFalsify).toHaveLength(0)
  })

  it('non-hard-rule warning at any confidence → mustFalsify', () => {
    const f = makeFinding({ isHardRule: false, severity: 'warning', confidence: 50 })
    const { mustFalsify } = triage([f])
    expect(mustFalsify).toHaveLength(1)
  })

  it('non-hard-rule critical at any confidence → mustFalsify', () => {
    const f = makeFinding({ isHardRule: false, severity: 'critical', confidence: 40 })
    const { mustFalsify } = triage([f])
    expect(mustFalsify).toHaveLength(1)
  })

  it('respects custom autoPassThreshold', () => {
    const f = makeFinding({ isHardRule: true, confidence: 85 })
    const { autoPass } = triage([f], { autoPassThreshold: 90 })
    expect(autoPass).toHaveLength(0)
    const { autoPass: pass2 } = triage([f], { autoPassThreshold: 80 })
    expect(pass2).toHaveLength(1)
  })

  it('respects custom autoDropThreshold', () => {
    const f = makeFinding({ isHardRule: false, severity: 'info', confidence: 75 })
    const { autoDrop } = triage([f], { autoDropThreshold: 70 })
    expect(autoDrop).toHaveLength(0)
    const { autoDrop: drop2 } = triage([f], { autoDropThreshold: 80 })
    expect(drop2).toHaveLength(1)
  })

  it('empty input returns three empty buckets', () => {
    const { autoPass, autoDrop, mustFalsify } = triage([])
    expect(autoPass).toEqual([])
    expect(autoDrop).toEqual([])
    expect(mustFalsify).toEqual([])
  })
})
