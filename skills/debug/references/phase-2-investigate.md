# Phase 2: Investigate + DX Audit

## Bootstrap (concurrent with teammates)

Dispatch `devflow-debug-bootstrap` agent. Pass labeled input inline:

```text
Bug: {bug description from $ARGUMENTS}
Project Root: {project_root from Phase 1 detect-project output}
Artifacts Dir: {artifacts_dir}
```

**Do not wait** — proceed immediately to Step 1 to spawn the teammate team while bootstrap runs.

When bootstrap completes: the agent has appended `## Shared Context` to `debug-context.md`. Send that section's contents to each teammate via `SendMessage`:

```text
SHARED CONTEXT: {contents of ## Shared Context section from debug-context.md}
```

**Call-site fallback:** If bootstrap errors → execute inline: `rtk git log --oneline -10`, list primary affected files (max 5) from the error/stack trace, read key sections, then append `## Shared Context` to `debug-context.md` and send via `SendMessage` to teammates. Teammates begin with `SHARED CONTEXT: (pending — gathering inline)` until the SendMessage arrives.

## Step 1: SDK Investigation Fast-Path (try before spawning Agent Teams)

**Try the SDK Investigator first (faster, lower token cost):**

```bash
SDK_DIR="${CLAUDE_SKILL_DIR}/../../devflow-sdk"

if [ -d "$SDK_DIR" ] && [ -d "$SDK_DIR/node_modules" ]; then

  # Full mode: runs Investigator + DX Analyst concurrently
  # Quick mode: Investigator only (--quick flag)
  SDK_MODE_FLAG=""
  [ "{mode}" = "Quick" ] && SDK_MODE_FLAG="--quick"

  sdk_result=$(cd "$SDK_DIR" && node_modules/.bin/tsx src/cli.ts investigate \
    --bug "{bug_description}" \
    $SDK_MODE_FLAG \
    2>&1)
  sdk_exit=$?

else
  echo "devflow-sdk not available — skipping SDK-enhanced analysis"
  sdk_exit=1
fi
```

If `sdk_exit=0` and `sdk_result` is valid JSON (starts with `{`):

**Use SDK output directly:**

- Parse `sdk_result` as `InvestigationResult` JSON
- Map to `investigation.md` format per [artifact-templates.md](artifact-templates.md#investigation.md):
  - Root Cause section from `rootCause` (hypothesis, confidence, evidence[])
  - DX Findings table from `dxFindings[]` (Quick mode: empty)
  - Fix Plan from `fixPlan[]` (type: bug/test/dx)
- Report: `SDK Investigator: confidence={rootCause.confidence} · {dxFindings.length} DX findings · {fixPlan.length} fix items`
- **Skip Agent Teams spawning** — proceed directly to Step 2 (wait) using SDK result as investigation output
- **Do not wait for bootstrap** — proceed to Phase 3 immediately. When bootstrap completes, its `## Shared Context` is written to `debug-context.md` automatically (there are no teammates to SendMessage to). No lead action needed.

**If confidence is "low"** in SDK result — escalate to user regardless of source. Present `alternativeHypotheses` and ask for additional context.

**If `sdk_exit != 0` or result is not valid JSON**, log `SDK investigate failed (exit {sdk_exit}) — falling back to Agent Teams` and continue:

## Step 1 (fallback): Create Team

Create team `debug-{branch}` with 1-2 teammates using prompts from [teammate-prompts.md](teammate-prompts.md):

- **Full mode:** Investigator + DX Analyst (parallel)
- **Quick mode:** Investigator only

## Step 2: Wait for Teammates

```markdown
### Phase 2: Investigation

| Teammate | Status | Key finding |
| --- | --- | --- |
| Investigator | ... | ... |
| DX Analyst | ... | ... |
```

**CHECKPOINT** — all teammates must complete before proceeding.

## Step 3: Convergence

Lead shuts down all Phase 2 teammates.

**DX Signal Quality Check (Full mode only):** Before merging, check DX findings:

- If all findings are Info-severity → skip DX section in Fix Plan (no actionable improvements)
- If (Critical + Warning) / Total < 50% → note "low DX signal" to user before proceeding

Then merge findings into `{artifacts_dir}/investigation.md` — format: [artifact-templates.md](artifact-templates.md#investigation.md). Sections: Root Cause (hypothesis + file:line evidence), DX Findings table (Sev/Category/File/Line/Issue/Recommendation), Fix Plan (numbered: [Bug]/[Test]/[DX] items).

**GATE:** Root cause identified with file:line evidence **and confidence >= Medium** → proceed. If confidence is Low or root cause not found → escalate to user (present alternative hypotheses; do not proceed to Phase 3).
