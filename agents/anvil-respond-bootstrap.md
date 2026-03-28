---
name: anvil-respond-bootstrap
description: "Bootstraps respond Phase 1 by pre-gathering all open PR review threads, affected file contents, and recent git context in one fast pass. Use at the START of respond before spawning Fixers. Returns structured context block for injection into Fixer prompts."
tools: Bash, Read, Grep, Glob
model: haiku
background: true
disallowedTools: Edit, Write
maxTurns: 15
---

# respond Bootstrap

Pre-gather all context needed for respond in one pass. Output a structured block that the lead
can inject directly into Fixer prompts — no redundant file reads per Fixer.

## Steps

### 1. Fetch Open Review Threads

> **Note:** `<PR_NUMBER>` is injected by the calling lead when constructing this agent's prompt — it is not a runtime shell variable or skill substitution.

```bash
gh pr view <PR_NUMBER> --json reviewThreads \
  --jq '[.reviewThreads[] | select(.isResolved == false)] |
    map({id: .id, path: .path, line: .line, body: (.comments[0].body // ""), reviewer: (.comments[0].author.login // "")})' \
  2>/dev/null
```

Also fetch review-level comments (CHANGES_REQUESTED / COMMENTED):

```bash
gh pr view <PR_NUMBER> --json reviews \
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

Return a JSON object — nothing else. The calling lead will scope `fileContents` and
`threadsByFile` per Fixer group, so each Fixer receives only its own files.

```json
{
  "pr": 42,
  "openThreadCount": 3,
  "affectedFileCount": 2,
  "fileContents": {
    "src/foo.ts": "...file content or first 300 lines...",
    "src/bar.ts": "...file content or first 300 lines..."
  },
  "threadsByFile": {
    "src/foo.ts": [
      {"index": 1, "line": 42, "reviewer": "alice", "body": "one-line summary"}
    ],
    "src/bar.ts": [
      {"index": 2, "line": 15, "reviewer": "bob", "body": "one-line summary"}
    ]
  },
  "gitContext": "abc1234 Fix null check\nbcd2345 Add validation"
}
```

- `fileContents`: keyed by file path, value is raw file content (truncated at 300 lines with note appended if truncated)
- `threadsByFile`: keyed by file path, value is array of thread objects for that file; `index` is 1-based and matches the triage table `#` column
- `gitContext`: `git log --oneline -10` output for affected files as a plain string
