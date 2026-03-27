# Phase 1: Prerequisites, Worktree Setup, Bootstrap, Scope Assessment

## Prerequisite Check

Before anything, verify agent teams are available:

```text
If TeamCreate tool is not available → check graceful degradation:
- If Task (subagent) tool is available → "Agent Teams not enabled. Running in subagent mode (no debate, parallel subagent review)."
- If neither → "Running in solo mode. Lead performs sequential checklist-based review per review-conventions.md."
```

## Phase 1: Worktree Setup (Reviewer mode only)

In **Reviewer mode**: `gh pr checkout $0 --worktree /tmp/review-pr-$0`. Skip if already on PR branch or if worktree exists. Skip entirely in Author mode. Clean up after Phase 7: `git worktree remove /tmp/review-pr-$0`.

### Bootstrap

Start both simultaneously — do not wait between them:

**A) `pr-review-bootstrap` agent (Haiku):** Spawn with PR #$0 and Jira key if present. Output: `{bootstrap_context}` (diff summary, file groupings, AC checklist).

**B) Jira fetch** (only if Jira key found in `$ARGUMENTS`): Follow [jira-integration](../../../jira-integration/SKILL.md) §dlc-review while bootstrap agent runs:

1. Fetch ticket → summarize Problem / Value / Scope
2. Parse AC → numbered checklist
3. Map each AC to PR diff files — flag missing implementation or tests as Critical

Run Scope Assessment while A and B are in flight — it reads only the diff stat from the header.

**Merge before Phase 3:** Collect both outputs once available, then inject into all Phase 3 teammate prompts:

- `{bootstrap_context}` → all 3 teammate prompts
- AC summary → all 3 teammate prompts + Phase 4 output

**Fallbacks:** If bootstrap fails → Teammate 1 fetches full diff; teammates 2+3 use that instead. If no Jira key → skip B entirely.

### Scope Assessment

Parse `Diff stat` from header. Classify per [review-conventions](../../../review-conventions/SKILL.md) size thresholds:

| Size | Lines | Behavior |
| --- | --- | --- |
| Normal | <=400 | Full review with debate |
| Large | 401-1000 | Full review + suggest split |
| Massive | >1000 | Spawn Correctness reviewer (Hard Rules + confidence ≥85 only) · skip debate · lightweight falsification on Hard Rule findings · warn prominently |
