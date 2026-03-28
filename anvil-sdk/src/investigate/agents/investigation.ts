import type { AgentDefinition, SDKResultSuccess } from '@anthropic-ai/claude-agent-sdk'
import { query } from '@anthropic-ai/claude-agent-sdk'
import type { ResolvedConfig } from '../../config.js'
import { DX_ANALYST_PROMPT } from '../prompts/dx-analyst.js'
import { INVESTIGATOR_PROMPT } from '../prompts/investigator.js'
import {
  InvestigationResultSchema,
  investigationResultJsonSchema,
  type DxFinding,
  type InvestigationResult,
  type RootCause,
} from '../schemas/investigation.js'

// Investigator returns root cause + fix plan items (no DX)
const investigatorOutputSchema = {
  type: 'object',
  properties: {
    rootCause: investigationResultJsonSchema.properties.rootCause,
    fixPlan: investigationResultJsonSchema.properties.fixPlan,
  },
  required: ['rootCause', 'fixPlan'],
} as const

// DX Analyst returns only dxFindings
const dxAnalystOutputSchema = {
  type: 'object',
  properties: {
    dxFindings: investigationResultJsonSchema.properties.dxFindings,
  },
  required: ['dxFindings'],
} as const

function createInvestigator(model: 'sonnet' | 'opus' | 'haiku'): AgentDefinition {
  return {
    description: 'Traces root cause of bugs — find file:line evidence, never guess',
    prompt: INVESTIGATOR_PROMPT,
    tools: ['Read', 'Grep', 'Glob', 'Bash'],
    model,
    maxTurns: 15,
  }
}

function createDxAnalyst(model: 'sonnet' | 'opus' | 'haiku'): AgentDefinition {
  return {
    description: 'Audits affected area for observability, error handling, and test coverage gaps',
    prompt: DX_ANALYST_PROMPT,
    tools: ['Read', 'Grep', 'Glob'],
    model,
    maxTurns: 10,
  }
}

async function runInvestigator(params: {
  bugDescription: string
  config: ResolvedConfig
}): Promise<{ rootCause: RootCause; fixPlan: InvestigationResult['fixPlan'] }> {
  const agent = createInvestigator(params.config.model)
  const prompt = `Investigate this bug and return root cause + fix plan as JSON.\n\nBUG:\n${params.bugDescription}`

  for await (const msg of query({
    prompt,
    options: {
      agents: { investigator: agent },
      agent: 'investigator',
      allowedTools: ['Read', 'Grep', 'Glob', 'Bash'],
      // NOTE: permissionMode ignored inside Claude Code plugin — CLI use only
      permissionMode: 'bypassPermissions',
      allowDangerouslySkipPermissions: true,
      maxTurns: 15,
      maxBudgetUsd: params.config.maxBudgetPerReviewer,
      outputFormat: {
        type: 'json_schema',
        schema: investigatorOutputSchema as Record<string, unknown>,
      },
    },
  })) {
    if (msg.type === 'result') {
      if (msg.subtype === 'success') {
        const result = msg as SDKResultSuccess
        const raw = result.structured_output
        if (raw === undefined || raw === null) {
          throw new Error('[sdk-investigate] investigator returned no structured_output')
        }
        const parsed = InvestigationResultSchema.pick({ rootCause: true, fixPlan: true }).safeParse(raw)
        if (!parsed.success) {
          throw new Error(
            `[sdk-investigate] investigator schema failed: ${JSON.stringify(parsed.error.issues)}`,
          )
        }
        return parsed.data
      }
      throw new Error(`[sdk-investigate] investigator ended with subtype: ${msg.subtype}`)
    }
  }
  throw new Error('[sdk-investigate] investigator query ended without result')
}

async function runDxAnalyst(params: {
  bugDescription: string
  config: ResolvedConfig
}): Promise<DxFinding[]> {
  const agent = createDxAnalyst(params.config.model)
  const prompt = `Audit the affected area of this bug for DX issues. Return findings as JSON.\n\nBUG:\n${params.bugDescription}`

  for await (const msg of query({
    prompt,
    options: {
      agents: { dxAnalyst: agent },
      agent: 'dxAnalyst',
      allowedTools: ['Read', 'Grep', 'Glob'],
      // NOTE: permissionMode ignored inside Claude Code plugin — CLI use only
      permissionMode: 'bypassPermissions',
      allowDangerouslySkipPermissions: true,
      maxTurns: 10,
      maxBudgetUsd: params.config.maxBudgetFalsification,
      outputFormat: {
        type: 'json_schema',
        schema: dxAnalystOutputSchema as Record<string, unknown>,
      },
    },
  })) {
    if (msg.type === 'result') {
      if (msg.subtype === 'success') {
        const result = msg as SDKResultSuccess
        const raw = result.structured_output
        if (raw === undefined || raw === null) {
          console.warn('[sdk-investigate] dx-analyst returned no structured_output — returning empty DX findings')
          return []
        }
        const parsed = InvestigationResultSchema.pick({ dxFindings: true }).safeParse(raw)
        if (!parsed.success) {
          console.warn(
            `[sdk-investigate] dx-analyst schema failed — returning empty: ${JSON.stringify(parsed.error.issues)}`,
          )
          return []
        }
        return parsed.data.dxFindings
      }
      // DX analyst failure is non-fatal — return empty findings
      console.warn(
        `[sdk-investigate] dx-analyst ended with subtype: ${msg.subtype} — returning empty DX findings`,
      )
      return []
    }
  }
  return []
}

export async function runInvestigation(params: {
  bugDescription: string
  quickMode: boolean
  config: ResolvedConfig
}): Promise<InvestigationResult> {
  if (params.quickMode) {
    // Quick mode: Investigator only, no DX analysis
    const { rootCause, fixPlan } = await runInvestigator({
      bugDescription: params.bugDescription,
      config: params.config,
    })
    return { rootCause, dxFindings: [], fixPlan }
  }

  // Full mode: Investigator + DX Analyst in parallel
  const [investigatorResult, dxFindings] = await Promise.all([
    runInvestigator({ bugDescription: params.bugDescription, config: params.config }),
    runDxAnalyst({ bugDescription: params.bugDescription, config: params.config }),
  ])

  // Merge actionable DX findings into fix plan as [dx] items
  const dxFixItems = dxFindings
    .filter(f => f.severity !== 'info')
    .map(f => ({ type: 'dx' as const, description: f.recommendation, file: f.file, line: f.line }))

  return {
    rootCause: investigatorResult.rootCause,
    dxFindings,
    fixPlan: [...investigatorResult.fixPlan, ...dxFixItems],
  }
}
