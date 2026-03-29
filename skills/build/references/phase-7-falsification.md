# Phase 7: Falsification Pass

> Skip this phase if Stage 2 used the SDK Review Engine — falsification was already applied internally.

**Full mode iter 1 only.** Skip for: Quick/Hotfix mode, iter 2+ reviews.

**Run consolidation and falsification in parallel** — they operate independently on the same raw
findings. Dispatch both immediately after debate completes; merge results when both finish.

## Step 1: Dispatch consolidator (do not wait)

Dispatch `review-consolidator` agent with the raw findings table from all reviewers. **Do not wait** — proceed immediately to Step 2 while consolidator runs.

## Step 2: Run falsifier concurrently

Try the SDK Falsifier while the consolidator runs:

```bash
SDK_DIR="${CLAUDE_SKILL_DIR}/../../devflow-sdk"

if [ -d "$SDK_DIR" ] && [ -d "$SDK_DIR/node_modules" ]; then

  FINDINGS_FILE=$(mktemp /tmp/devflow-findings-XXXXXX.json)
  # Write pre-consolidation findings as JSON array to $FINDINGS_FILE

  sdk_result=$(cd "$SDK_DIR" && node_modules/.bin/tsx src/cli.ts falsify \
    --findings-file "$FINDINGS_FILE" \
    2>&1)
  sdk_exit=$?
  rm -f "$FINDINGS_FILE"

else
  echo "devflow-sdk not available — skipping SDK-enhanced analysis"
  sdk_exit=1
fi
```

If `sdk_exit=0` and `sdk_result` is valid JSON: verdicts are in `sdk_result.verdicts[]`.

**If `sdk_exit != 0` or not valid JSON**, fall back to Agent Teams: spawn `falsification-agent` with the raw findings table inline. Wait for it to complete.

## Step 3: Wait for both and merge

Wait for the consolidator agent to complete (if not already done). Then merge:

For each verdict in the falsifier output, apply it to the **consolidated findings** by `file:line` key:

| Verdict | Action on consolidated output |
| --- | --- |
| SUSTAINED | No change |
| DOWNGRADED | Update severity in the consolidated row matching that file:line |
| REJECTED | Remove the consolidated row matching that file:line |

If multiple raw findings share the same `file:line` (consolidated into one row): apply the harshest
verdict — if any raw finding was REJECTED and the rest were also REJECTED, remove the row; if any
was SUSTAINED, keep the row (REJECTED of one duplicate finding does not remove a corroborated finding).

Note the final REJECTED count in the Phase 6 status line: `(N findings rejected by Falsification Pass)`.
