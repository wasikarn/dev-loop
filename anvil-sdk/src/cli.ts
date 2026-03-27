#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs'
import { resolveConfig } from './config.js'
import { runFalsification } from './review/agents/falsifier.js'
import { consolidate } from './review/consolidator.js'
import { readDiff } from './review/diff-reader.js'
import { formatJson, formatMarkdown } from './review/output.js'
import { runReview } from './review/orchestrator.js'
import { triage } from './review/triage.js'
import type { ReviewReport } from './types.js'

interface ParsedArgs {
  branch: string | undefined
  baseBranch: string | undefined
  output: 'json' | 'markdown'
  falsification: boolean
  hardRulesPath: string | undefined
  budget: number | undefined
}

function parseArgs(args: string[]): ParsedArgs {
  const result: ParsedArgs = {
    branch: undefined,
    baseBranch: undefined,
    output: 'json',
    falsification: true,
    hardRulesPath: undefined,
    budget: undefined,
  }

  for (let i = 0; i < args.length; i++) {
    const arg = args[i]
    if (arg === undefined) continue

    if (arg === '--no-falsification') {
      result.falsification = false
      continue
    }

    // Flags that consume the next argument
    const next = args[i + 1]

    if (arg === '--branch' && next !== undefined) {
      result.branch = next
      i++
    } else if (arg === '--base-branch' && next !== undefined) {
      result.baseBranch = next
      i++
    } else if (arg === '--output' && next !== undefined) {
      if (next === 'json' || next === 'markdown') {
        result.output = next
      } else {
        console.error(`[sdk-review] Unknown --output value: ${next}. Expected json or markdown.`)
        process.exit(1)
      }
      i++
    } else if (arg === '--hard-rules' && next !== undefined) {
      result.hardRulesPath = next
      i++
    } else if (arg === '--budget' && next !== undefined) {
      const parsed = parseFloat(next)
      if (Number.isNaN(parsed) || parsed <= 0) {
        console.error(`[sdk-review] --budget must be a positive number, got: ${next}`)
        process.exit(1)
      }
      result.budget = parsed
      i++
    }
  }

  return result
}

function loadHardRules(path: string | undefined): string {
  if (path !== undefined && path.length > 0) {
    if (!existsSync(path)) {
      console.warn(`[sdk-review] --hard-rules path not found: ${path}`)
      process.exit(1)
    }
    return readFileSync(path, 'utf8')
  }
  // Look in cwd
  const defaults = ['hard-rules.md', '.build/hard-rules.md', 'docs/hard-rules.md']
  for (const p of defaults) {
    if (existsSync(p)) return readFileSync(p, 'utf8')
  }
  return ''
}

async function main(): Promise<void> {
  const argv = process.argv
  const args = argv.length > 2 ? argv.slice(2) : []
  const parsed = parseArgs(args)

  const hardRules = loadHardRules(parsed.hardRulesPath)
  const config = resolveConfig({
    ...(parsed.budget !== undefined && { budgetUsd: parsed.budget }),
    noFalsification: !parsed.falsification,
  })

  let files: ReturnType<typeof readDiff>
  try {
    const diffTarget: { branch?: string; baseBranch?: string } = {}
    if (parsed.branch !== undefined) diffTarget.branch = parsed.branch
    if (parsed.baseBranch !== undefined) diffTarget.baseBranch = parsed.baseBranch
    files = readDiff(diffTarget)
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    console.error(`[sdk-review] failed to read diff: ${message}`)
    process.exit(1)
  }

  if (files.length === 0) {
    console.error(
      'No diff found. Make sure you are in a git repo with uncommitted changes or specify --branch.'
    )
    process.exit(1)
  }

  // Run reviewers in parallel
  const { results, totalCost, totalTokens } = await runReview({
    files,
    hardRules,
    dismissedPatterns: '',
    config,
  })

  // Collect all findings
  const allFindings = results.flatMap(r => r.findings)

  // Triage
  const { autoPass, autoDrop: _autoDrop, mustFalsify } = triage(allFindings)

  // Falsification
  let verdicts: Awaited<ReturnType<typeof runFalsification>> = []
  if (parsed.falsification && mustFalsify.length > 0) {
    verdicts = await runFalsification({ findings: mustFalsify, config })
  }

  // Consolidate
  const consolidated = consolidate({
    autoPass,
    mustFalsify,
    verdicts,
    confidenceThreshold: config.confidenceThreshold,
    patternCapCount: config.patternCapCount,
  })

  // Build report
  const critical = consolidated.filter(f => f.severity === 'critical').length
  const warning = consolidated.filter(f => f.severity === 'warning').length
  const info = consolidated.filter(f => f.severity === 'info').length

  const report: ReviewReport = {
    pr: parsed.branch ?? 'HEAD',
    summary: { critical, warning, info },
    findings: consolidated,
    strengths: [],
    verdict: critical > 0 ? 'REQUEST_CHANGES' : 'APPROVE',
    cost: {
      total_usd: totalCost,
      per_reviewer: results.map(r => r.cost),
    },
    tokens: {
      total: totalTokens,
      per_reviewer: results.map(r => r.tokens),
    },
  }

  if (parsed.output === 'markdown') {
    console.log(formatMarkdown(report))
  } else {
    console.log(formatJson(report))
  }
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err)
  console.error('[sdk-review] fatal:', message)
  process.exit(1)
})
