import type { ResolvedConfig } from '../config.js'
import type { DiffBucket, FileDiff, PRComplexity, ReviewerResult, ReviewRole } from '../types.js'
import { runReviewer } from './agents/reviewer.js'
import { mapToDomains } from './domain-mapper.js'

const ADONIS_PATH_RE = /(?:app\/(?:controllers|models|validators|services)|start\/routes)/

function detectAdonisProject(files: FileDiff[]): boolean {
  return files.some(f => ADONIS_PATH_RE.test(f.path))
}

/**
 * Classify PR complexity to determine reviewer count.
 * trivial  (<50 diff lines, ≤1 active domain) → 1 reviewer
 * complex  (>500 diff lines OR ≥3 active domains) → all reviewers
 * standard → all reviewers (default)
 */
function classifyComplexity(activeBuckets: DiffBucket[], totalDiffLines: number): PRComplexity {
  if (totalDiffLines < 50 && activeBuckets.length <= 1) return 'trivial'
  if (totalDiffLines > 500 || activeBuckets.length >= 3) return 'complex'
  return 'standard'
}

export async function runReview(params: {
  files: FileDiff[]
  hardRules: string
  dismissedPatterns: string
  config: ResolvedConfig
}): Promise<{ results: ReviewerResult[]; roles: ReviewRole[]; totalCost: number; totalTokens: number; complexity: PRComplexity }> {
  const buckets = mapToDomains(params.files)
  const allActiveBuckets = buckets.filter((b: DiffBucket) => b.files.length > 0)
  const totalDiffLines = params.files.reduce((sum, f) => sum + f.diffLineCount, 0)
  const complexity = classifyComplexity(allActiveBuckets, totalDiffLines)

  // For trivial PRs, run only one reviewer (lowest-index active bucket = most relevant domain)
  const activeBuckets = complexity === 'trivial' ? allActiveBuckets.slice(0, 1) : allActiveBuckets

  const isAdonisProject = detectAdonisProject(params.files)

  const settled = await Promise.allSettled(
    activeBuckets.map((bucket: DiffBucket) =>
      runReviewer({
        bucket,
        hardRules: params.hardRules,
        dismissedPatterns: params.dismissedPatterns,
        isAdonisProject,
        config: params.config,
      })
    )
  )

  const results: ReviewerResult[] = settled.map(r => {
    if (r.status === 'rejected') {
      console.warn(`[sdk-review] reviewer failed: ${String(r.reason)}`)
      return { findings: [], strengths: [], cost: 0, tokens: 0 }
    }
    return r.value
  })

  // roles[i] corresponds to results[i] — preserves reviewer attribution
  const roles: ReviewRole[] = activeBuckets.map((b: DiffBucket) => b.role)

  const totalCost = results.reduce((sum, r) => sum + r.cost, 0)
  const totalTokens = results.reduce((sum, r) => sum + r.tokens, 0)

  return { results, roles, totalCost, totalTokens, complexity }
}
