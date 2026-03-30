import { describe, expect, it } from 'bun:test'
import { assignLenses } from './lens-assigner.js'

describe('assignLenses', () => {
  it('fileCount=0 → skipped with reason', () => {
    const r = assignLenses(0)
    expect(r.kind).toBe('skipped')
    if (r.kind === 'skipped') {
      expect(r.reason).toContain('No changed files')
    }
  })

  it('fileCount=29 → full', () => {
    const r = assignLenses(29)
    expect(r.kind).toBe('full')
  })

  it('fileCount=30 → reduced', () => {
    const r = assignLenses(30)
    expect(r.kind).toBe('reduced')
  })

  it('fileCount=50 → reduced', () => {
    const r = assignLenses(50)
    expect(r.kind).toBe('reduced')
  })

  it('fileCount=51 → skipped', () => {
    const r = assignLenses(51)
    expect(r.kind).toBe('skipped')
    if (r.kind === 'skipped') {
      expect(r.reason).toContain('51')
    }
  })

  it('reduced mode → each teammate has exactly 1 lens', () => {
    const r = assignLenses(30)
    expect(r.kind).toBe('reduced')
    if (r.kind === 'reduced') {
      for (const assignment of r.assignments) {
        expect(assignment.lenses).toHaveLength(1)
      }
    }
  })

  it('full mode → correctness teammate has multiple lenses', () => {
    const r = assignLenses(1)
    expect(r.kind).toBe('full')
    if (r.kind === 'full') {
      const correctness = r.assignments.find(a => a.teammate === 'correctness')
      expect(correctness).toBeDefined()
      expect((correctness?.lenses.length ?? 0)).toBeGreaterThan(1)
    }
  })

  it('skip reason includes file count', () => {
    const r = assignLenses(75)
    expect(r.kind).toBe('skipped')
    if (r.kind === 'skipped') {
      expect(r.reason).toContain('75')
    }
  })
})
