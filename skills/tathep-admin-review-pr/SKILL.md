---
name: tathep-admin-review-pr
description: "PR review skill for tathep-admin (Next.js 14 Pages Router + Tailwind + Headless UI + Vitest). Dispatches 7 parallel specialized agents, verifies Jira AC, then fixes issues (Author) or submits inline comments (Reviewer). Triggers: review PR, check PR, code review, /tathep-admin-review-pr."
argument-hint: "[pr-number] [jira-key?] [Author|Reviewer]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(gh *), Bash(git *)
compatibility: "Requires gh CLI and git. Run from within the tathep-admin repo."
---

# PR Review — tathep-admin

Invoke as `/tathep-admin-review-pr [pr-number] [jira-key?] [Author|Reviewer]`

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
| GitHub repo | `100-Stars-Co/bluedragon-eye-admin` |
| Validate | `npm run ts-check && npm run lint@fix && npm run test` |
| Scope | `git diff develop...HEAD` |

**NOTE:** `lint@fix` uses `@` not `:` — `npm run lint@fix` (NOT `lint:fix`)

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

- `as any` / `as unknown as T` → Critical (destroys type safety — runtime errors slip past the compiler)
- `result.data` accessed without checking `result.isOk` first → Critical (crashes on error responses — always guard the success path)
- hardcoded route strings (`/manage/...`, `/ad/...`) → Critical (use `ROUTE_PATHS` — breaks silently on route rename, no type checking)
- hardcoded Thai status text → Critical (use `*_STATUS_TEXT` constants — duplicated strings diverge over time and miss future i18n)
- empty `catch {}` / swallowed errors → Critical (silent failures hide production bugs — errors vanish with no trace)
- nesting > 1 level → Critical (use guard clauses, extract function, or lookup table — deep nesting buries the happy path)
- `import { useQuery } from '@tanstack/react-query'` → Critical (must be `'react-query'` v3 — tanstack v5 API is incompatible with this codebase)
- query/fetch inside loop → Critical (N+1 — exponential network load; batch or preload instead)
- `console.log` in non-test code → Warning (leaks debug output to production; use structured logger)

`feature-dev:code-reviewer` applies TypeScript advanced type principles (generics, branded types, discriminated unions, type guards — NO `as any`) and Clean Code principles (SRP, early returns, naming intent, function size).

## Project Constraints

- Flag changed files <80% coverage (Critical)
- #13 React/Next.js performance rules are embedded in checklist — see `references/checklist.md` #13 section
- Pages Router project — App Router patterns (RSC, Server Components, `React.cache()`) do NOT apply

## Reviewer Examples

**Comment style:** Thai mixed with English technical terms — casual Slack/PR tone.
Examples: "ใช้ ROUTE_PATHS ด้วยนะ ไม่งั้น hardcode", "logic ซ้ำกัน extract เป็น util ไว้เลยดีกว่าครับ", "ตรงนี้ N+1 อยู่ ลอง preload ดูครับ"

**Strengths:** "ใช้ STATUS_TEXT constants ไม่ hardcode Thai", "Headless UI pattern ถูกต้อง", "test coverage ครบ"

---

**Read [review-workflow.md](../../references/review-workflow.md) and follow the phase workflow.** Use the Project Config, Hard Rules, and References above as inputs.
