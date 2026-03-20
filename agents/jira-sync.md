---
name: jira-sync
description: "Post a structured implementation summary comment to the linked Jira ticket after completing a dev-loop task. Reads dev-loop-context.md or debug-context.md and posts what was implemented, files changed, and any AC deviations. Use at the end of dlc-build Phase 6 or dlc-debug Phase 3 cleanup when a Jira key is present in the context artifact."
tools: Read, Glob, Bash
model: haiku
maxTurns: 5
---

# Jira Sync

Post a concise implementation summary to the linked Jira ticket. All content comes from existing
context artifacts — no re-reading of source files required.

## Steps

### 1. Locate Context Artifact

Look for the context artifact in this order:

1. `.claude/dlc-build/dev-loop-context.md` — dlc-build artifact
2. `.claude/dlc-debug/debug-context.md` — dlc-debug artifact
3. `$ARGUMENTS` — caller may pass explicit path

If none found, output: `No context artifact found — cannot post Jira comment.` and exit.

### 2. Extract Jira Key

Read the context artifact. Look for a Jira key in:

- `**Jira:**` field
- `**Ticket:**` field
- Any `[A-Z]+-\d+` pattern in the header

If no Jira key found, output: `No Jira key in context artifact — skipping Jira sync.` and exit.

### 3. Build Comment Body

Extract from the context artifact:

- **What was implemented** — task summary or phase titles completed
- **Files changed** — from the artifact's files list or run `git diff --name-only origin/main...HEAD`
- **Validate result** — pass/fail status if recorded in artifact
- **AC deviations** — any "Deviations" or "Notes" section in the artifact

Format as:

```markdown
## Implementation Summary

**Completed:** {task or feature title}
**Branch:** {branch name}
**PR:** #{pr number if available}

### What was changed
{bullet list of what was implemented — from context artifact}

### Files modified
{file list — deduplicated, grouped by layer if possible}

### Validate
{pass/fail and command used}

### AC deviations
{list or "None — all AC implemented as specified"}
```

### 4. Post Comment

Use the MCP Jira tool to post the comment:

```text
mcp__mcp-atlassian__jira_add_comment(issue_key="{KEY}", comment="{comment_body}")
```

If MCP not available, output the formatted comment body and instruct: "Post manually to Jira {KEY}."

### 5. Confirm

Output: `✓ Jira {KEY} updated — implementation summary posted.`
