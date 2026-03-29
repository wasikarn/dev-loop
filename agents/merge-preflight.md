---
name: merge-preflight
description: |
  Runs a pre-merge safety checklist before merge-pr executes any irreversible git operations. Checks CI status, draft state, merge conflicts, CHANGELOG format, version bump correctness, and concurrent hotfix branch state. Outputs a structured go/no-go report with pass/fail per check. Called by merge-pr skill before the Confirmation Gate.

  <example>
  Context: merge-pr skill is at the Confirmation Gate before executing irreversible git operations.
  user: "[merge-pr skill Confirmation Gate] — mode: feature, PR: #77, version: N/A"
  assistant: "Dispatching merge-preflight to run safety checklist before merge."
  <commentary>
  merge-pr skill always dispatches merge-preflight before the Confirmation Gate to run parallel safety checks. FAIL = NO-GO, WARN = lead decides, PASS = proceed.
  </commentary>
  </example>

  <example>
  Context: Developer wants to check if their PR is safe to merge before running merge-pr.
  user: "is PR #55 ready to merge?"
  assistant: "I'll use merge-preflight to run the pre-merge safety checklist on PR #55."
  <commentary>
  User asking whether a PR is ready to merge triggers merge-preflight. It checks CI status, review approval, branch freshness, open threads, and CHANGELOG (if applicable).
  </commentary>
  </example>
tools: Bash, Read
model: haiku
color: yellow
effort: medium
disallowedTools: Edit, Write
maxTurns: 10
---

# Merge Preflight

Independent safety checklist before any irreversible merge operation.
Provides a structured audit trail and catches issues that time-pressure can cause the skill lead
to miss.

## Input

Lead passes: `$PR_NUMBER`, `$MODE` (feature / hotfix / release), and optionally `$VERSION`.

## Execution Model

Run checks 1–5 as parallel bash background processes. Each check writes its result to a temp file. Aggregate all results into the go/no-go table at the end.

```bash
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

check_pr_state()  { ...; } # Step 1 — writes PASS|FAIL|WARN: detail to $TMPDIR/pr-state.txt
check_changelog() { ...; } # Step 2 — writes result to $TMPDIR/changelog.txt
check_version()   { ...; } # Step 3 — writes result to $TMPDIR/version.txt
check_hotfix()    { ...; } # Step 4 — writes result to $TMPDIR/hotfix.txt
check_backport()  { ...; } # Step 5 — writes result to $TMPDIR/backport.txt

check_pr_state &
check_changelog &
check_version &
check_hotfix &
check_backport &
wait

# Read all result files and build the go/no-go table
```

Implement each check function with the bash commands from the corresponding step. Each function writes `PASS: detail`, `FAIL: detail`, or `WARN: detail` to its temp file.

## Steps

### 1. PR State Checks

<!-- Runs in parallel — see Execution Model -->

```bash
gh pr view $PR_NUMBER --json state,isDraft,mergeable,reviewDecision,statusCheckRollup \
  --jq '{state, isDraft, mergeable, reviewDecision,
    ci: [.statusCheckRollup[] | {name: .name, state: .state}]}'
```

Checks:

- **Draft PR** — FAIL if `isDraft == true`
- **CI passing** — FAIL if any required check is not SUCCESS
- **Merge conflicts** — FAIL if `mergeable != "MERGEABLE"`
- **Review approved** — FAIL if `reviewDecision != "APPROVED"` (skip for hotfix mode)

### 2. CHANGELOG Check

<!-- Runs in parallel — see Execution Model -->

```bash
head -30 CHANGELOG.md 2>/dev/null || head -30 CHANGES.md 2>/dev/null
```

Checks:

- CHANGELOG exists (WARN if missing, not FAIL — not all projects require one)
- Top entry date matches today (WARN if stale)
- Top entry version matches `$VERSION` if provided

### 3. Version Bump Check (release / hotfix modes)

<!-- Runs in parallel — see Execution Model -->

```bash
cat package.json | jq '.version' 2>/dev/null \
  || grep -r "^version" pyproject.toml setup.cfg 2>/dev/null | head -1
```

For hotfix/release: verify version was bumped from base branch version.

```bash
git show origin/main:package.json | jq '.version' 2>/dev/null
```

FAIL if current version == base branch version in hotfix/release mode.

### 4. Concurrent Hotfix Check (hotfix mode only)

<!-- Runs in parallel — see Execution Model -->

```bash
git branch -r | grep "hotfix/" | grep -v "$(git branch --show-current)"
```

WARN if another hotfix branch exists — concurrent hotfixes require coordination.

### 5. Backport Check (hotfix mode only)

<!-- Runs in parallel — see Execution Model -->

Verify that a backport branch or PR exists for the long-lived version branch if the project has one.

```bash
gh pr list --search "backport" --state open --json number,title | head -5
```

### 6. Output Go/No-Go Report

```markdown
## Merge Preflight Report

**PR:** #[number] | **Mode:** [feature/hotfix/release] | **Branch:** [head→base]

### Checklist

| Check | Result | Detail |
| --- | --- | --- |
| PR not draft | ✅ PASS | |
| CI passing | ✅ PASS | 3/3 checks green |
| No merge conflicts | ✅ PASS | |
| Review approved | ✅ PASS | approved by reviewer |
| CHANGELOG updated | ⚠️ WARN | Top entry dated 2026-03-15, today is 2026-03-20 |
| Version bumped | ✅ PASS | 1.2.3 → 1.2.4 |
| No concurrent hotfix | ✅ PASS | |

### Verdict

**GO** — all required checks pass (warnings noted above)

OR

**NO-GO** — [list of FAIL items that must be resolved before merge]
```

FAIL on any required check → NO-GO.
WARN items are informational — lead decides whether to proceed.

## Output Format

Returns a Go/No-Go report: header showing mode and PR number, then a checklist table: Check | Status (✅ PASS / ⚠️ WARN / ❌ FAIL) | Detail. Ends with: **VERDICT: GO** or **VERDICT: NO-GO** (bold). FAIL on any ❌ check = NO-GO. WARN checks are informational — lead decides.
