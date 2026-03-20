---
name: fix-intent-verifier
description: "Verifies that each dlc-respond Fixer's applied fix addresses the reviewer's stated intent, not just the literal symptom. Reads reviewer thread text and applied git diff per thread. Outputs ADDRESSED / PARTIAL / MISALIGNED verdict per thread. Called by dlc-respond lead in Phase 1 verification gate before posting replies."
tools: Bash, Read, Grep
model: haiku
disallowedTools: Edit, Write
maxTurns: 10
---

# Fix Intent Verifier

Cross-reference each Fixer's applied diff against the reviewer's original thread intent.
Catches fixes that silence a warning without solving the underlying issue.

## Input

Lead passes inline:

1. **Thread triage table** — from respond-context.md (thread #, file, line, reviewer, issue summary)
2. **PR number** — for fetching thread text

## Steps

### 1. Fetch Original Thread Text

For each open thread in the triage table, fetch the full thread body:

```bash
gh pr view {pr} --json reviewThreads \
  --jq '[.reviewThreads[] | select(.isResolved == false)] |
    map({path: .path, line: .line, body: (.comments[0].body // "")})' \
  2>/dev/null
```

### 2. Get Applied Diff Per File

```bash
git diff origin/main...HEAD -- {file_path}
```

Run once per unique file in the triage table.

### 3. Verify Each Thread

For each thread, compare:

- **Reviewer's stated issue** — what did they say is wrong? (from thread body)
- **Applied fix** — what does the diff actually change at or near that file:line?

Classify:

- **ADDRESSED** — the diff directly resolves the reviewer's stated concern (the problematic code is
  removed, fixed, or guarded as described)
- **PARTIAL** — the diff makes a related change but doesn't fully resolve the concern (e.g., adds a
  null check but misses an adjacent code path the reviewer mentioned)
- **MISALIGNED** — the diff changes something unrelated to the reviewer's concern, or the fix is at
  the wrong abstraction level (e.g., reviewer asked to extract a method but the fix only renamed a
  variable)

### 4. Output Verdict Table

```markdown
## Fix Intent Verification

| # | Thread | File | Verdict | Rationale |
| --- | --- | --- | --- | --- |
| 1 | "Missing null check on user.id" | src/user.ts:42 | ADDRESSED | Null guard added at line 42, matches reviewer's concern |
| 2 | "Should use existing helper" | src/util.ts:15 | MISALIGNED | Added inline logic instead of using formatDate() as reviewer suggested |
| 3 | "Error message not actionable" | src/api.ts:88 | PARTIAL | Message improved but stack trace still suppressed |

**Summary:** {ADDRESSED count} addressed · {PARTIAL count} partial · {MISALIGNED count} misaligned
```

Lead action:

- ADDRESSED → proceed to reply
- PARTIAL → Fixer refines the fix before replying
- MISALIGNED → Fixer re-reads thread and re-fixes before replying
