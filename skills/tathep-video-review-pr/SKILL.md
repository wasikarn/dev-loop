---
name: tathep-video-review-pr
description: "PR review skill for tathep-video-processing (TypeScript 5.9 + Bun + Hono + Effect-TS + Drizzle ORM + Vitest + Clean Architecture DDD). Dispatches 7 parallel specialized agents, verifies Jira AC, then fixes issues (Author) or submits inline comments (Reviewer). Triggers: review PR, check PR, code review, /tathep-video-review-pr."
argument-hint: "[pr-number] [jira-key?] [Author|Reviewer]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(gh *), Bash(git *)
compatibility: "Requires gh CLI and git. Run from within the tathep-video-processing repo."
---

# PR Review — tathep-video-processing

Invoke as `/tathep-video-review-pr [pr-number] [jira-key?] [Author|Reviewer]`

**PR:** #$0 | **Jira:** $1 | **Mode:** $2 (default: Author)
**Today:** !`date +%Y-%m-%d`
**Diff stat:** !`git diff develop...HEAD --stat 2>/dev/null | tail -10`
**PR title:** !`gh pr view $0 --json title,body,labels,author --jq '{title,body,labels: [.labels[].name],author: .author.login}' 2>/dev/null`
**PR comments:** !`gh pr view $0 --comments --json comments --jq '[.comments[] | {author: .author.login, body: .body[:200]}]' 2>/dev/null`
**Changed files:** !`gh pr diff $0 --name-only 2>/dev/null`

**Args:** `$0`=PR# (required) · `$1`=Jira key or Author/Reviewer · `$2`=Author/Reviewer
**Role:** Tech Lead — improve code health via architecture, mentoring, team standards. Not a linter. Explain *why*, cite patterns, respect valid approaches.

Read CLAUDE.md first — auto-loaded, contains full project patterns and conventions.

## Project Config

| Key | Value |
| --- | --- |
| GitHub repo | `100-Stars-Co/tathep-video-processing` |
| Validate | `bun run check && bun run test` |
| Scope | `git diff develop...HEAD` |
| Default branch | `develop` (NOT `main`) |

## References

| File | Content |
| --- | --- |
| [review-workflow.md](../../references/review-workflow.md) | Shared phase workflow — follow this |
| [checklist.md](references/checklist.md) | 12-point review criteria |
| [examples.md](references/examples.md) | Project-specific code examples |
| [review-output-format.md](../../references/review-output-format.md) | Output format |
| [review-conventions.md](../../references/review-conventions.md) | Comment labels, dedup, strengths |

## Hard Rules

Flag unconditionally — no confidence filter, always report:

- `any` type → Critical (destroys type safety — Biome + strict TypeScript forbid it; use specific types or generics)
- `.forEach()` → Critical (use `for...of` — Biome enforces `noForEach`; forEach hides control flow)
- raw `try { } catch { }` → Critical (use `rethrowOrWrapError()` or `createErrorHandler()` from `@/utils/error-handling` — raw try-catch loses error context)
- generic `new Error()` or `throw new Error()` → Critical (use domain exceptions `VideoProcessingError.transient()` / `.permanent()` or `ProcessingError.fromCode()` — generic errors bypass error classification)
- `biome-ignore` comment → Critical (fix the issue instead — suppressing lints hides problems)
- nesting > 1 level → Critical (use guard clauses, extract function, or lookup table — deep nesting buries the happy path)
- `--no-verify` on git commands → Critical (never bypass pre-commit/pre-push hooks)
- query inside loop (N+1) → Critical (batch INSERT/UPDATE — exponential DB load)
- `console.log` / `console.error` → Critical (use `LoggerFactory.getLogger()` from `@/infrastructure/telemetry/LoggerFactory` — console output is unstructured)

`feature-dev:code-reviewer` applies TypeScript advanced type principles (branded types, discriminated unions, type guards — NO `any`), Clean Architecture DDD principles (domain isolation, hexagonal ports/adapters, value objects), and Effect-TS patterns (`Effect.gen`, `Layer`, `pipe`).

## Project Constraints

- Flag changed files with missing tests (Critical) — 85% coverage threshold enforced
- **DDD/Hexagonal architecture** — domain layer must have zero external dependencies
- **Bun runtime** — use `bun run test` (NEVER `bun test`), `import.meta.dir` (not `__dirname`)

## Reviewer Examples

**Comment style:** Thai mixed with English technical terms — casual Slack/PR tone.
Examples: "ใช้ `for...of` แทน `forEach` ด้วยนะครับ Biome จะ fail", "ตรงนี้ใช้ `rethrowOrWrapError()` แทน raw try-catch ดีกว่าครับ", "N+1 อยู่ ลอง batch insert ดูครับ"

**Strengths:** "domain layer ไม่ import infrastructure", "domain exception transient/permanent ถูก", "rethrowOrWrapError pattern ครบ"

---

**Read [review-workflow.md](../../references/review-workflow.md) and follow the phase workflow.** Use the Project Config, Hard Rules, and References above as inputs.
