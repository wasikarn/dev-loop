---
name: dlc-debug
description: "Agent Teams debugging with parallel DX analysis — Investigator traces root cause while DX Analyst audits observability, error handling, and test coverage. Pass a Jira key (BEP-XXXX) to enrich bug context from ticket details. Use when: debugging complex bugs, production incidents, or when you want to harden the affected area. Triggers: debug, team debug, investigate bug, /dlc-debug."
argument-hint: "[bug-description-or-jira-key] [--quick?]"
compatibility: "Requires gh CLI, git, and CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (degrades gracefully without)"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *)
---

# Team Debug — Systematic Debugging with DX

Invoke as `/dlc-debug [bug-description-or-jira-key] [--quick?]`

## References

| File |
| --- |
| [teammate-prompts.md](references/teammate-prompts.md) |
| [dx-checklist.md](references/dx-checklist.md) |
| [phase-gates.md](references/phase-gates.md) |
| [../../references/review-conventions.md](../../references/review-conventions.md) |
| [jira-integration.md](../../references/jira-integration.md) — Jira detection, MCP fetch, bug enrichment (loaded when Jira key detected) |
| [references/operational.md](references/operational.md) — Graceful Degradation, Context Compression Recovery, Success Criteria |

---

**Bug:** $ARGUMENTS | **Today:** !`date +%Y-%m-%d`
**Git branch:** !`git branch --show-current`
**Recent commits:** !`git log --oneline -5 2>/dev/null`
**Project:** !`bash "${CLAUDE_SKILL_DIR}/../../scripts/detect-project.sh" 2>/dev/null`

**Args:** `$0`=bug description (required) · `$1`=`--quick` (optional, skip DX Analyst)
**Modes:** Full = Investigator + DX Analyst + Fixer · Quick = Investigator + Fixer (DX checklist only)

Read CLAUDE.md first — auto-loaded, contains project patterns and conventions.

---

## Prerequisite Check

Before anything, verify agent teams are available:

```text
If TeamCreate tool is not available → check graceful degradation:
- If Task (subagent) tool is available → "Agent Teams not enabled. Running in subagent mode (no messaging)."
- If neither → "Running in solo mode. All phases executed by lead sequentially."
```

---

## Phase 0: Triage (Lead Only)

### Step 1: Detect Project

Use the `Project` JSON from the header (output of `detect-project.sh`). It contains: `project`, `repo`, `validate`, `review_skill`, `base_branch`, `branch`.

If `review_skill` is non-empty, load project-specific Hard Rules from the corresponding `tathep-*-review-pr` skill.

### Step 1.5: Jira Context (skip if no Jira)

Scan `$ARGUMENTS` for Jira key (`BEP-\d+`). If found, follow [jira-integration.md](../../references/jira-integration.md) §team-debug:

1. Fetch ticket — enrich bug description with ticket details
2. Check linked issues — related bugs may share root cause
3. Use ticket priority to inform severity classification (Step 2)
4. Add Jira context to `debug-context.md` (Step 4) and Investigator prompt (Phase 1)

If no Jira key — skip to Step 2.

### Step 2: Classify Severity

| Severity | Criteria | Effect |
| --- | --- | --- |
| **P0 — Outage** | Production down, data loss | Full mode forced, skip mode confirmation only (fix plan approval still required) |
| **P1 — Critical** | Major feature broken, workaround exists | Full mode default |
| **P2 — Minor** | Edge case, cosmetic, non-blocking | Quick mode default |

**P0 gate clarification:** Only the mode confirmation gate is skipped (auto-Full). All other gates remain.

### Step 3: Classify Mode

- `--quick` flag or P2 severity → **Quick mode** (skip DX Analyst)
- P0/P1, multi-file, cross-cutting → **Full mode**
- Ambiguous → ask user

### Step 4: Create Context Artifact

Write `debug-context.md` at **target project root**:

```markdown
# Debug Context

Bug: {description}
Severity: {P0/P1/P2}
Mode: {Full/Quick}
Project: {project_name}
Validate: {validate_command}
Started: {date}
Branch: {branch_name}

## Reproduction Steps
{from user description}

## Hard Rules
{project_hard_rules}
```

**GATE:** User confirms mode → proceed. (P0: auto-proceed with Full mode.)

---

## Phase 1: Investigate + DX Audit

### Step 1: Create Team

Create team `debug-{branch}` with 1-2 teammates using prompts from [teammate-prompts.md](references/teammate-prompts.md):

- **Full mode:** Investigator + DX Analyst (parallel)
- **Quick mode:** Investigator only

### Step 2: Wait for Teammates

```markdown
### Phase 1: Investigation

| Teammate | Status | Key finding |
| --- | --- | --- |
| Investigator | ... | ... |
| DX Analyst | ... | ... |
```

**CHECKPOINT** — all teammates must complete before proceeding.

### Step 3: Convergence

Lead shuts down all Phase 1 teammates, then merges findings into `investigation.md` at **target project root**:

```markdown
# Investigation Report

## Root Cause
{Investigator findings — hypothesis, evidence, file:line}

## DX Findings
| # | Sev | Category | File | Line | Issue | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Critical | Silent failure | ... | ... | ... | ... |

## Fix Plan
1. [Bug] Fix root cause: {description}
2. [Test] Add regression test: {description}
3. [DX] {each DX improvement as separate item}
```

**GATE:** Root cause identified with file:line evidence → proceed. If Investigator cannot find root cause → escalate to user (do not proceed to Phase 2).

---

## Phase 2: Fix + Harden

Create Fixer in same team using prompts from [teammate-prompts.md](references/teammate-prompts.md):

- **Full mode:** Full Mode Fixer prompt (references investigation.md)
- **Quick mode:** Quick Mode Fixer prompt (includes condensed DX checklist from [dx-checklist.md](references/dx-checklist.md))

Fixer executes Fix Plan from `investigation.md`.

Commit strategy:

```text
commit 1: fix(area): fix root cause — {description}
commit 2: test(area): add regression test for {bug}
commit 3: dx(area): improve error message in {file}
commit 4: dx(area): add logging at {decision point}
commit 5: dx(area): add validation for {edge case}
```

**Validate gate:** Project validate command must pass after every commit.

**If fix fails:** If 3+ fix attempts fail → Fixer messages lead. Lead questions architecture and escalates to user. Do not attempt fix #4 without user guidance.

After Fixer completes, Lead shuts down Fixer.

**GATE:** All Fix Plan items done + validate passes → proceed.

---

## Phase 3: Verify & Ship (Lead Only)

### Step 1: Present Summary

```markdown
## Debug Summary

**Bug:** {description}
**Root Cause:** {one-line}
**Fix:** {commit refs}
**DX Improvements:** {count} items (Critical: X, Warning: Y)

### Commits
| # | Type | Description |
| --- | --- | --- |
| 1 | fix | ... |
| 2 | test | ... |
| 3 | dx | ... |

### Completion Options
1. Create PR
2. Commit to current branch
3. Keep for manual review
```

### Step 2: Cleanup

1. Shut down all remaining teammates
2. Clean up the team
3. Optionally archive `debug-context.md` + `investigation.md`

---

## Constraints

- **Max 2 teammates concurrent** — Investigator + DX Analyst in Phase 1, then Fixer alone in Phase 2
- **No debate phase** — debugging needs speed, not consensus
- **Investigator is READ-ONLY** — no file modifications during Phase 1
- **DX Analyst is READ-ONLY** — no file modifications during Phase 1
- **Fixer follows Fix Plan** — no scope creep beyond investigation findings. Fix with the simplest correct approach; do not introduce abstractions or refactors not in the Fix Plan
- **DX scope = affected area only** — not codebase-wide improvements
- **3 fix attempts max** — beyond that is an architectural problem, escalate to user
- **Hard Rules from project detection** — loaded dynamically, cannot be skipped
- **Artifacts at target project root** — `debug-context.md`, `investigation.md` (not this skills repo)
- **Team name convention** — `debug-{branch}` (e.g., `debug-fix/null-check`)

---

## Operational Reference

See [references/operational.md](references/operational.md) for Graceful Degradation levels, Context Compression Recovery steps, and Success Criteria checklist.
