import { z } from 'zod'

export const MinimalFindingSchema = z.object({
  taskNumber: z.number().int().min(1),
  taskName: z.string(),
  verdict: z.enum(['SUSTAINED', 'CHALLENGED']),
  ground: z.string(), // '—' for SUSTAINED, 'YAGNI'|'SCOPE'|'ORDER'|'MISSING' for CHALLENGED
  rationale: z.string(),
})

export const CleanFindingSchema = z.object({
  area: z.string(),
  issue: z.string(),
  evidence: z.string(), // file:line or research.md:line
  recommendation: z.string(),
})

export const ChallengeResultSchema = z.object({
  minimal: z.array(MinimalFindingSchema),
  missingTasks: z.array(z.string()),
  dependencyIssues: z.array(z.string()),
  clean: z.array(CleanFindingSchema),
  recommendation: z.string(),
})

// Manually crafted JSON schema — avoids z.toJSONSchema() $schema field quirks
export const challengeResultJsonSchema = {
  type: 'object',
  properties: {
    minimal: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          taskNumber: { type: 'integer', minimum: 1 },
          taskName: { type: 'string' },
          verdict: { type: 'string', enum: ['SUSTAINED', 'CHALLENGED'] },
          ground: { type: 'string' },
          rationale: { type: 'string' },
        },
        required: ['taskNumber', 'taskName', 'verdict', 'ground', 'rationale'],
      },
    },
    missingTasks: { type: 'array', items: { type: 'string' } },
    dependencyIssues: { type: 'array', items: { type: 'string' } },
    clean: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          area: { type: 'string' },
          issue: { type: 'string' },
          evidence: { type: 'string' },
          recommendation: { type: 'string' },
        },
        required: ['area', 'issue', 'evidence', 'recommendation'],
      },
    },
    recommendation: { type: 'string' },
  },
  required: ['minimal', 'missingTasks', 'dependencyIssues', 'clean', 'recommendation'],
} as const

export type MinimalFinding = z.infer<typeof MinimalFindingSchema>
export type CleanFinding = z.infer<typeof CleanFindingSchema>
export type ChallengeResult = z.infer<typeof ChallengeResultSchema>
