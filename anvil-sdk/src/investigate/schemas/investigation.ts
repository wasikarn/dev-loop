import { z } from 'zod'

export const EvidenceSchema = z.object({
  file: z.string(),
  line: z.number().int().nullable(),
  snippet: z.string(),
})

export const RootCauseSchema = z.object({
  hypothesis: z.string(),
  confidence: z.enum(['high', 'medium', 'low']),
  evidence: z.array(EvidenceSchema),
  alternativeHypotheses: z.array(z.string()),
})

export const DxFindingSchema = z.object({
  severity: z.enum(['critical', 'warning', 'info']),
  category: z.enum(['observability', 'error-handling', 'test-coverage', 'resilience']),
  file: z.string(),
  line: z.number().int().nullable(),
  issue: z.string(),
  recommendation: z.string(),
})

export const FixPlanItemSchema = z.object({
  type: z.enum(['bug', 'test', 'dx']),
  description: z.string(),
  file: z.string(),
  line: z.number().int().nullable(),
})

export const InvestigationResultSchema = z.object({
  rootCause: RootCauseSchema,
  dxFindings: z.array(DxFindingSchema),
  fixPlan: z.array(FixPlanItemSchema),
})

// Manually crafted JSON schema — avoids z.toJSONSchema() quirks
export const investigationResultJsonSchema = {
  type: 'object',
  properties: {
    rootCause: {
      type: 'object',
      properties: {
        hypothesis: { type: 'string' },
        confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
        evidence: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              file: { type: 'string' },
              line: { type: 'integer' },
              snippet: { type: 'string' },
            },
            required: ['file', 'snippet'],
          },
        },
        alternativeHypotheses: { type: 'array', items: { type: 'string' } },
      },
      required: ['hypothesis', 'confidence', 'evidence', 'alternativeHypotheses'],
    },
    dxFindings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          severity: { type: 'string', enum: ['critical', 'warning', 'info'] },
          category: { type: 'string', enum: ['observability', 'error-handling', 'test-coverage', 'resilience'] },
          file: { type: 'string' },
          line: { type: 'integer' },
          issue: { type: 'string' },
          recommendation: { type: 'string' },
        },
        required: ['severity', 'category', 'file', 'issue', 'recommendation'],
      },
    },
    fixPlan: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          type: { type: 'string', enum: ['bug', 'test', 'dx'] },
          description: { type: 'string' },
          file: { type: 'string' },
          line: { type: 'integer' },
        },
        required: ['type', 'description', 'file'],
      },
    },
  },
  required: ['rootCause', 'dxFindings', 'fixPlan'],
} as const

export type Evidence = z.infer<typeof EvidenceSchema>
export type RootCause = z.infer<typeof RootCauseSchema>
export type DxFinding = z.infer<typeof DxFindingSchema>
export type FixPlanItem = z.infer<typeof FixPlanItemSchema>
export type InvestigationResult = z.infer<typeof InvestigationResultSchema>
