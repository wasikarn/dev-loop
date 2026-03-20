---
name: dlc-respond-bootstrap
description: "Bootstraps dlc-respond Phase 1 by pre-gathering all open PR review threads, affected file contents, and recent git context in one fast pass. Use at the START of dlc-respond before spawning Fixers. Returns structured context block for injection into Fixer prompts."
tools: Bash, Read, Grep, Glob
model: haiku
disallowedTools: Edit, Write
maxTurns: 15
---

# dlc-respond Bootstrap

Pre-gather all context needed for dlc-respond in one pass. Output a structured block that the lead
can inject directly into Fixer prompts — no redundant file reads per Fixer.

## Steps

### 1. Fetch Open Review Threads

```bash
gh pr view $0 --json reviewThreads \
  --jq '[.reviewThreads[] | select(.isResolved == false)] |
    map({id: .id, path: .path, line: .line, body: (.comments[0].body // ""), reviewer: (.comments[0].author.login // "")})' \
  2>/dev/null
```

Also fetch review-level comments (CHANGES_REQUESTED / COMMENTED):

```bash
gh pr view $0 --json reviews \
  --jq '[.reviews[] | select(.state == "CHANGES_REQUESTED" or .state == "COMMENTED") |
    {reviewer: .author.login, body: .body, state: .state}]' \
  2>/dev/null
```

### 2. Extract Affected Files

Collect unique file paths from open threads. Deduplicate.

### 3. Read Affected Files

For each unique file path from Step 2, read the file content. Limit to first 300 lines for files
over 300 lines — note truncation if applied.

### 4. Fetch Git Context

```bash
git log --oneline -10 -- {affected_files_space_separated}
git diff origin/main...HEAD -- {affected_files_space_separated} --stat
```

### 5. Output Structured Context

Return this exact block — nothing else:

```markdown
## dlc-respond Bootstrap Context

**PR:** #[number]
**Open threads:** [count]
**Affected files:** [count]

### Open Threads Summary

| # | File | Line | Reviewer | Summary |
| --- | --- | --- | --- | --- |
| 1 | src/foo.ts | 42 | reviewer | one-line summary |

### Pre-read File Contents

#### `src/foo.ts` ([line count] lines)
[file content or first 300 lines if truncated]

#### `src/bar.ts` ([line count] lines)
[file content or first 300 lines if truncated]

### Recent Git Context
[git log --oneline -10 output for affected files]
```

Keep each section concise — this is input to Fixer agents, not a human report.
