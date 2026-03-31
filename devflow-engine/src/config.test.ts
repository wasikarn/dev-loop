import { describe, expect, it } from 'bun:test'
import { resolveConfig } from './config.js'

describe('resolveConfig — effort presets', () => {
  it('low → haiku, maxTurns 8, budget 0.10/0.05', () => {
    const cfg = resolveConfig({ effort: 'low' })
    expect(cfg.model).toBe('haiku')
    expect(cfg.maxTurnsReviewer).toBe(8)
    expect(cfg.maxBudgetPerReviewer).toBe(0.10)
    expect(cfg.maxBudgetFalsification).toBe(0.05)
  })

  it('medium → sonnet, maxTurns 15, budget 0.20/0.10', () => {
    const cfg = resolveConfig({ effort: 'medium' })
    expect(cfg.model).toBe('sonnet')
    expect(cfg.maxTurnsReviewer).toBe(15)
    expect(cfg.maxBudgetPerReviewer).toBe(0.20)
    expect(cfg.maxBudgetFalsification).toBe(0.10)
  })

  it('high → sonnet (default), maxTurns 20, budget 0.30/0.15', () => {
    const cfg = resolveConfig({ effort: 'high' })
    expect(cfg.model).toBe('sonnet')
    expect(cfg.maxTurnsReviewer).toBe(20)
    expect(cfg.maxBudgetPerReviewer).toBe(0.30)
    expect(cfg.maxBudgetFalsification).toBe(0.15)
  })

  it('max → opus, maxTurns 30, budget 0.60/0.25', () => {
    const cfg = resolveConfig({ effort: 'max' })
    expect(cfg.model).toBe('opus')
    expect(cfg.maxTurnsReviewer).toBe(30)
    expect(cfg.maxBudgetPerReviewer).toBe(0.60)
    expect(cfg.maxBudgetFalsification).toBe(0.25)
  })

  it('undefined effort → falls back to high defaults', () => {
    const cfg = resolveConfig()
    expect(cfg.effort).toBe('high')
    expect(cfg.model).toBe('sonnet')
    expect(cfg.maxTurnsReviewer).toBe(20)
  })

  it('effort absent in config object → falls back to high defaults', () => {
    const cfg = resolveConfig({})
    expect(cfg.effort).toBe('high')
    expect(cfg.model).toBe('sonnet')
  })
})

describe('resolveConfig — effort field is preserved in output', () => {
  it('resolved config includes the correct effort level', () => {
    expect(resolveConfig({ effort: 'low' }).effort).toBe('low')
    expect(resolveConfig({ effort: 'medium' }).effort).toBe('medium')
    expect(resolveConfig({ effort: 'high' }).effort).toBe('high')
    expect(resolveConfig({ effort: 'max' }).effort).toBe('max')
  })
})

describe('resolveConfig — static defaults', () => {
  it('autoPassThreshold=90, autoDropThreshold=79 across all efforts', () => {
    for (const effort of ['low', 'medium', 'high', 'max'] as const) {
      const cfg = resolveConfig({ effort })
      expect(cfg.autoPassThreshold).toBe(90)
      expect(cfg.autoDropThreshold).toBe(79)
    }
  })

  it('maxBudgetVerification=0.10 by default (not overridden by effort)', () => {
    for (const effort of ['low', 'medium', 'high', 'max'] as const) {
      const cfg = resolveConfig({ effort })
      expect(cfg.maxBudgetVerification).toBe(0.10)
    }
  })
})

describe('resolveConfig — explicit budgetUsd override', () => {
  it('budgetUsd=3 splits 80% / 3 reviewers + 20% falsification', () => {
    const cfg = resolveConfig({ budgetUsd: 3 })
    expect(cfg.maxBudgetPerReviewer).toBeCloseTo((3 * 0.8) / 3)
    expect(cfg.maxBudgetFalsification).toBeCloseTo(3 * 0.2)
  })

  it('budgetUsd sets maxBudgetVerification to full budgetUsd', () => {
    const cfg = resolveConfig({ budgetUsd: 5 })
    expect(cfg.maxBudgetVerification).toBe(5)
  })

  it('budgetUsd overrides effort preset budgets but not model/turns', () => {
    const cfg = resolveConfig({ effort: 'low', budgetUsd: 6 })
    expect(cfg.model).toBe('haiku')
    expect(cfg.maxTurnsReviewer).toBe(8)
    expect(cfg.maxBudgetPerReviewer).toBeCloseTo(1.6)
  })
})

describe('resolveConfig — optional fields', () => {
  it('hardRulesPath is forwarded when provided', () => {
    const cfg = resolveConfig({ hardRulesPath: '/path/to/rules.md' })
    expect(cfg.hardRulesPath).toBe('/path/to/rules.md')
  })

  it('hardRulesPath is absent when not provided', () => {
    const cfg = resolveConfig()
    expect(cfg.hardRulesPath).toBeUndefined()
  })

  it('noFalsification is forwarded when true', () => {
    const cfg = resolveConfig({ noFalsification: true })
    expect(cfg.noFalsification).toBe(true)
  })

  it('noFalsification is absent when not provided', () => {
    const cfg = resolveConfig()
    expect(cfg.noFalsification).toBeUndefined()
  })
})
