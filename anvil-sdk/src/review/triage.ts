import type { Finding, TriagedFindings } from '../types.js'

/**
 * Splits findings into three buckets:
 * - autoPass: Hard Rule violations with confidence >= autoPassThreshold (certainties, no need to challenge)
 * - autoDrop: NON-Hard-Rule info-severity with confidence <= autoDropThreshold (noise)
 * - mustFalsify: everything else (goes to falsification)
 *
 * Hard Rules are NEVER auto-dropped regardless of severity or confidence.
 */
export function triage(findings: Finding[], params?: {
  autoPassThreshold?: number  // default 90
  autoDropThreshold?: number  // default 79
}): TriagedFindings {
  const autoPassAt = params?.autoPassThreshold ?? 90
  const autoDropAt = params?.autoDropThreshold ?? 79
  return {
    autoPass: findings.filter(f => f.isHardRule && f.confidence >= autoPassAt),
    autoDrop: findings.filter(f => !f.isHardRule && f.severity === 'info' && f.confidence <= autoDropAt),
    mustFalsify: findings.filter(
      f => !(f.isHardRule && f.confidence >= autoPassAt) && !(!f.isHardRule && f.severity === 'info' && f.confidence <= autoDropAt)
    ),
  }
}
