export type { Finding } from './review/schemas/finding.js'
export type { Verdict } from './review/schemas/verdict.js'

import type { Finding } from './review/schemas/finding.js'
import type { Verdict } from './review/schemas/verdict.js'

export type ReviewRole = 'correctness' | 'architecture' | 'dx'
export type PRComplexity = 'trivial' | 'standard' | 'complex'
export type Severity = Finding['severity']
export type VerdictType = Verdict['verdict']

export interface FileDiff {
  path: string
  hunks: string
  language: string
  /** Total lines in the diff (additions + deletions). Used for workload estimation. */
  diffLineCount: number
}

export interface DiffBucket {
  role: ReviewRole
  files: FileDiff[]
  totalLines: number
}

export interface ConsolidatedFinding extends Finding {
  consensus: string
  patternNote?: string
}

export interface ReviewReport {
  pr: string
  summary: Record<Severity, number>
  findings: ConsolidatedFinding[]
  strengths: string[]
  verdict: 'APPROVE' | 'REQUEST_CHANGES'
  noiseWarning?: boolean
  /** Complexity classification used to determine reviewer count. trivial = 1 reviewer ran. */
  complexity: PRComplexity
  cost: { total_usd: number; per_reviewer: number[]; falsification_usd: number }
  tokens: { total: number; per_reviewer: number[]; falsification: number }
}

export interface TriagedFindings {
  autoPass: Finding[]
  autoDrop: Finding[]
  mustFalsify: Finding[]
}

export interface ReviewerResult {
  findings: Finding[]
  strengths: string[]
  cost: number
  tokens: number
}
