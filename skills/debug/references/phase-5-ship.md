# Phase 5: Verify & Ship (Lead Only)

## Step 1: Present Summary

Output Debug Summary — format: [artifact-templates.md](artifact-templates.md#debug-summary). Shows: bug, root cause, fix commit refs, DX improvements count, commits table, completion options.

## Step 2: Cleanup

1. Shut down all remaining teammates
2. Clean up the team
3. Optionally archive `debug-context.md` + `investigation.md`

## Step 3: Jira Sync (conditional)

If a Jira key was identified in Phase 1 Step 2 context:

1. Run `jira-summary-poster` agent — pass `{artifacts_dir}/debug-context.md` as `$ARGUMENTS` (the agent reads from
   project root but explicit path avoids any ambiguity).
2. The agent posts an implementation summary to the ticket automatically — no manual drafting needed.

## Step 4: Metrics (optional)

Append one JSON line to `~/.claude/devflow-metrics.jsonl`:

```json
{"skill":"debug","date":"{YYYY-MM-DD}","mode":"debug","severity":"{P0|P1|P2}","task":"{bug_short}","fix_plan_items":{N},"dx_findings":{D}}
```
