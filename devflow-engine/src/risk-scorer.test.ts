import { describe, expect, it } from 'bun:test'
import { computeScore } from './risk-scorer.js'
import { toFilePath } from './types.js'

function signals(overrides: {
  loc?: number
  files?: string[]
  hasJiraKey?: boolean
  dismissed?: string[]
  diff?: string
} = {}): Parameters<typeof computeScore>[0] {
  return {
    loc: overrides.loc ?? 0,
    changedFiles: (overrides.files ?? []).map(toFilePath),
    hasJiraKey: overrides.hasJiraKey ?? false,
    dismissedPatterns: overrides.dismissed ?? [],
    diffContent: overrides.diff ?? '',
  }
}

describe('loc scoring', () => {
  it('loc=0 → locScore=0', () => {
    const r = computeScore(signals({ loc: 0 }))
    expect(r.breakdown.loc).toBe(0)
  })

  it('loc=399 → locScore=39 (floored)', () => {
    const r = computeScore(signals({ loc: 399 }))
    expect(r.breakdown.loc).toBe(39)
  })

  it('loc=400 → locScore=40 (cap exact)', () => {
    const r = computeScore(signals({ loc: 400 }))
    expect(r.breakdown.loc).toBe(40)
  })

  it('loc=401 → locScore=40 (cap holds)', () => {
    const r = computeScore(signals({ loc: 401 }))
    expect(r.breakdown.loc).toBe(40)
  })

  it('loc=1600 → locScore=40 (large LOC still capped)', () => {
    const r = computeScore(signals({ loc: 1600 }))
    expect(r.breakdown.loc).toBe(40)
  })
})

describe('fileType scoring', () => {
  it('auth file → 35', () => {
    const r = computeScore(signals({ files: ['src/auth/login.ts'] }))
    expect(r.breakdown.fileType).toBe(35)
  })

  it('migrations file → 35', () => {
    const r = computeScore(signals({ files: ['db/migrations/001_create_users.ts'] }))
    expect(r.breakdown.fileType).toBe(35)
  })

  it('CI/CD yml file → 25', () => {
    const r = computeScore(signals({ files: ['.github/workflows/deploy.yml'] }))
    expect(r.breakdown.fileType).toBe(25)
  })

  it('controller file → 15', () => {
    const r = computeScore(signals({ files: ['src/controllers/user.controller.ts'] }))
    expect(r.breakdown.fileType).toBe(15)
  })

  it('test file → 5', () => {
    const r = computeScore(signals({ files: ['src/user.test.ts'] }))
    expect(r.breakdown.fileType).toBe(5)
  })

  it('auth + test file in same PR → 35 (highest wins, not sum)', () => {
    const r = computeScore(signals({ files: ['src/auth/login.ts', 'src/auth/login.test.ts'] }))
    expect(r.breakdown.fileType).toBe(35)
  })

  it('no matching file → 0', () => {
    const r = computeScore(signals({ files: ['src/utils/format.ts'] }))
    expect(r.breakdown.fileType).toBe(0)
  })
})

describe('semantic scoring', () => {
  it('secret pattern in diff → 30', () => {
    const r = computeScore(signals({ diff: '+const password = process.env.DB_PASS' }))
    expect(r.breakdown.semantic).toBe(30)
  })

  it('SQL migration in diff → 20', () => {
    const r = computeScore(signals({ diff: '+CREATE TABLE users (id int)' }))
    expect(r.breakdown.semantic).toBe(20)
  })

  it('auth token pattern in diff → 15', () => {
    const r = computeScore(signals({ diff: '+const token = req.headers.authorization.replace("Bearer ", "")' }))
    expect(r.breakdown.semantic).toBe(15)
  })

  it('SQL + secrets in same diff → 30 (highest wins, not additive)', () => {
    const r = computeScore(signals({ diff: '+CREATE TABLE users\n+const api_key = "abc"' }))
    expect(r.breakdown.semantic).toBe(30)
  })

  it('no semantic match → 0', () => {
    const r = computeScore(signals({ diff: '+const greeting = "hello world"' }))
    expect(r.breakdown.semantic).toBe(0)
  })
})

describe('contextBonus', () => {
  it('Jira key present → +10', () => {
    const r = computeScore(signals({ hasJiraKey: true }))
    expect(r.breakdown.contextBonus).toBe(10)
  })

  it('1 dismissed match → -10', () => {
    const r = computeScore(signals({
      diff: '+const foo = bar',
      dismissed: ['const foo = bar'],
    }))
    expect(r.breakdown.contextBonus).toBe(-10)
  })

  it('2 dismissed matches → -10 (floor holds, not -20)', () => {
    const r = computeScore(signals({
      diff: '+const foo = bar\n+const baz = qux',
      dismissed: ['const foo = bar', 'const baz = qux'],
    }))
    expect(r.breakdown.contextBonus).toBe(-10)
  })

  it('Jira + 1 dismissed match → 0 (+10 - 10)', () => {
    const r = computeScore(signals({
      hasJiraKey: true,
      diff: '+const foo = bar',
      dismissed: ['const foo = bar'],
    }))
    expect(r.breakdown.contextBonus).toBe(0)
  })
})

describe('mode thresholds', () => {
  it('score=29 → micro', () => {
    // 0 LOC + no files + no semantic + no bonus ≈ 0; force score via auth file + loc
    const r = computeScore(signals({ loc: 290 }))  // loc=290 → locScore=29
    expect(r.mode).toBe('micro')
  })

  it('score=30 → quick', () => {
    const r = computeScore(signals({ loc: 300 }))  // loc=300 → locScore=30
    expect(r.mode).toBe('quick')
  })

  it('score=54 → quick (boundary just below full threshold)', () => {
    // loc=390 → locScore=Math.floor((390/400)*40)=39
    // test file → fileType=5
    // SQL → semantic=20
    // dismissed match → bonus=-10
    // total = 39+5+20-10 = 54 → quick (not full which requires ≥55)
    const r = computeScore(signals({
      loc: 390,
      files: ['src/user.test.ts'],
      diff: '+CREATE TABLE orders (id int)',
      dismissed: ['CREATE TABLE orders (id int)'],
    }))
    expect(r.total).toBe(54)
    expect(r.mode).toBe('quick')
  })

  it('score=55 → full', () => {
    // loc=400(40) + auth file(35) → 75 capped at 100 → full
    const r = computeScore(signals({ loc: 400, files: ['src/auth/jwt.ts'] }))
    expect(r.mode).toBe('full')
  })
})

describe('total ceiling', () => {
  it('max signals → total ≤ 100', () => {
    const r = computeScore(signals({
      loc: 1600,
      files: ['src/auth/login.ts'],
      diff: '+const api_key = process.env.SECRET_KEY',
      hasJiraKey: true,
    }))
    expect(r.total).toBeLessThanOrEqual(100)
  })
})

describe('float boundary', () => {
  it('loc=399 produces integer locScore (no float leakage)', () => {
    const r = computeScore(signals({ loc: 399 }))
    expect(Number.isInteger(r.breakdown.loc)).toBe(true)
  })
})
