import { execSync } from 'node:child_process'
import { extname } from 'node:path'
import type { FileDiff } from '../types.js'

const LANGUAGE_MAP: Record<string, string> = {
  '.ts': 'typescript',
  '.tsx': 'typescript',
  '.js': 'javascript',
  '.jsx': 'javascript',
  '.py': 'python',
  '.go': 'go',
  '.rs': 'rust',
  '.sql': 'sql',
  '.json': 'json',
  '.yaml': 'yaml',
  '.yml': 'yaml',
  '.md': 'markdown',
  '.sh': 'shell',
}

function detectLanguage(filePath: string): string {
  const ext = extname(filePath).toLowerCase()
  return LANGUAGE_MAP[ext] ?? 'unknown'
}

function parseFileBlock(block: string): FileDiff | null {
  // Extract file path from +++ b/... line
  const pathMatch = block.match(/^\+\+\+ b\/(.+)$/m)
  const rawPath = pathMatch?.[1]
  if (!rawPath) return null

  const path = rawPath.trim()

  // Skip binary files
  if (block.includes('Binary files')) return null

  // Count added/removed lines (lines starting with + or -, excluding +++ and ---)
  const lines = block.split('\n')
  let diffLineCount = 0
  const hunkLines: string[] = []
  let inHunk = false

  for (const line of lines) {
    if (line.startsWith('@@')) {
      inHunk = true
      hunkLines.push(line)
      continue
    }
    if (inHunk) {
      hunkLines.push(line)
      // Count added lines: starts with + but not +++
      if (line.startsWith('+') && !line.startsWith('+++')) {
        diffLineCount++
      }
      // Count removed lines: starts with - but not ---
      if (line.startsWith('-') && !line.startsWith('---')) {
        diffLineCount++
      }
    }
  }

  const hunks = hunkLines.join('\n')
  const language = detectLanguage(path)

  return { path, hunks, language, diffLineCount }
}

function parseDiffOutput(output: string): FileDiff[] {
  if (!output.trim()) return []
  const blocks = output.split(/^diff --git /m).filter(b => b.trim().length > 0)
  const results: FileDiff[] = []
  for (const block of blocks) {
    const parsed = parseFileBlock(block)
    if (parsed !== null) results.push(parsed)
  }
  return results
}

const SAFE_REF = /^[\w/.-]+$/

// Thresholds based on review quality degradation: >300 files causes context dilution;
// >10k diff lines causes reviewer focus loss; >50MB raw approaches the 250MB buffer ceiling.
const LARGE_DIFF_FILE_THRESHOLD = 300
const LARGE_DIFF_LINE_THRESHOLD = 10_000

function warnIfLargeDiff(files: FileDiff[], rawByteLength: number): void {
  const totalLines = files.reduce((sum, f) => sum + f.diffLineCount, 0)
  if (files.length > LARGE_DIFF_FILE_THRESHOLD) {
    console.warn(`[diff-reader] large diff: ${files.length} files (>${LARGE_DIFF_FILE_THRESHOLD}) — review quality may degrade`)
  }
  if (totalLines > LARGE_DIFF_LINE_THRESHOLD) {
    console.warn(`[diff-reader] large diff: ${totalLines} diff lines (>${LARGE_DIFF_LINE_THRESHOLD}) — review quality may degrade`)
  }
  const mb = (rawByteLength / (1024 * 1024)).toFixed(1)
  if (rawByteLength > 50 * 1024 * 1024) {
    console.warn(`[diff-reader] very large diff: ${mb}MB raw — approaching buffer limits`)
  }
}

/**
 * Reads git diff for the current branch and returns parsed file diffs.
 * Caller is responsible for checking out the branch/PR before calling.
 * Runs `git diff` once — callers receive pre-parsed data, no redundant re-reads.
 */
export function readDiff(target: { branch?: string; baseBranch?: string }): FileDiff[] {
  if (target.branch !== undefined && !SAFE_REF.test(target.branch)) {
    throw new Error(`Unsafe branch name: ${target.branch}`)
  }
  if (target.baseBranch !== undefined && !SAFE_REF.test(target.baseBranch)) {
    throw new Error(`Unsafe base branch name: ${target.baseBranch}`)
  }

  const base = target.baseBranch ?? 'origin/main'

  let mergeBase: string
  try {
    mergeBase = execSync(`git merge-base HEAD ${base}`, { encoding: 'utf8', maxBuffer: 1024 * 1024 }).trim()
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    throw new Error(`git merge-base failed: ${message}`)
  }

  let output: string
  try {
    output = execSync(`git diff ${mergeBase}...HEAD`, { encoding: 'utf8', maxBuffer: 250 * 1024 * 1024 })
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    throw new Error(`git diff failed: ${message}`)
  }

  const files = parseDiffOutput(output)
  warnIfLargeDiff(files, output.length)
  return files
}

/**
 * Reads diff for a GitHub PR via `gh pr diff` and returns parsed file diffs.
 * Does not require checking out the PR branch.
 */
export function readPrDiff(prNumber: number): FileDiff[] {
  if (!Number.isInteger(prNumber) || prNumber <= 0) {
    throw new Error(`Invalid PR number: ${prNumber}`)
  }

  let output: string
  try {
    output = execSync(`gh pr diff ${prNumber}`, { encoding: 'utf8', maxBuffer: 250 * 1024 * 1024 })
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    throw new Error(`gh pr diff ${prNumber} failed: ${message}`)
  }

  const files = parseDiffOutput(output)
  warnIfLargeDiff(files, output.length)
  return files
}
