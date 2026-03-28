import { readFileSync } from 'node:fs'
import type { AgentDefinition, SDKResultSuccess } from '@anthropic-ai/claude-agent-sdk'
import { query } from '@anthropic-ai/claude-agent-sdk'
import type { ResolvedConfig } from '../../config.js'
import { PLAN_CHALLENGE_PROMPT } from '../prompts/challenger.js'
import { ChallengeResultSchema, challengeResultJsonSchema, type ChallengeResult } from '../schemas/challenge.js'

function createChallenger(model: 'sonnet' | 'opus' | 'haiku'): AgentDefinition {
  return {
    description: 'Challenges implementation plans — goal is to remove scope creep and surface pre-work',
    prompt: PLAN_CHALLENGE_PROMPT,
    tools: ['Read', 'Grep', 'Glob'],
    model,
    maxTurns: 5,
  }
}

export async function runPlanChallenge(params: {
  planPath: string
  researchPath: string | undefined
  config: ResolvedConfig
}): Promise<ChallengeResult> {
  const planContent = readFileSync(params.planPath, 'utf8')
  const researchContent =
    params.researchPath !== undefined ? readFileSync(params.researchPath, 'utf8') : '(no research.md provided)'

  const agent = createChallenger(params.config.model)
  const prompt = `Challenge this implementation plan.\n\nPLAN:\n${planContent}\n\nRESEARCH:\n${researchContent}\n\nReturn verdicts as JSON.`

  for await (const msg of query({
    prompt,
    options: {
      agents: { challenger: agent },
      agent: 'challenger',
      allowedTools: ['Read', 'Grep', 'Glob'],
      // NOTE: permissionMode ignored inside Claude Code plugin — CLI use only
      permissionMode: 'bypassPermissions',
      allowDangerouslySkipPermissions: true,
      maxTurns: 5,
      maxBudgetUsd: 0.15,
      outputFormat: {
        type: 'json_schema',
        schema: challengeResultJsonSchema as Record<string, unknown>,
      },
    },
  })) {
    if (msg.type === 'result') {
      if (msg.subtype === 'success') {
        const result = msg as SDKResultSuccess
        const raw = result.structured_output
        if (raw === undefined || raw === null) {
          throw new Error('[sdk-plan-challenge] no structured_output — budget may have been exceeded')
        }
        const parsed = ChallengeResultSchema.safeParse(raw)
        if (!parsed.success) {
          throw new Error(
            `[sdk-plan-challenge] schema validation failed: ${JSON.stringify(parsed.error.issues)}`,
          )
        }
        return parsed.data
      } else {
        throw new Error(`[sdk-plan-challenge] ended with subtype: ${msg.subtype}`)
      }
    }
  }

  throw new Error('[sdk-plan-challenge] query ended without result message')
}
