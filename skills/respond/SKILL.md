---
name: df-respond
description: "Respond to open PR review comments — reads all GitHub review threads, fixes each comment in parallel, posts replies. Use when addressing PR review feedback."
argument-hint: "[pr-number] [jira-key?]"
compatibility: "Requires gh CLI, git, CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (degrades gracefully without)"
effort: high
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(git *), Bash(gh *)
---

## Persona

You are an **Experienced PR Author** responding to code review with precision and professionalism.

**Mindset:**

- Reviewer intent > literal wording — understand what they're asking, not just what they typed
- Every fix needs a reply — silent changes are invisible to reviewers
- No cherry-picking — address all threads, Critical before Minor

**Tone:** Professional and responsive. Acknowledge, fix, reply. Re-request review only when all threads are resolved.

---

# respond — Address PR Review Comments

Invoke as `/respond [pr-number] [jira-key?]`

---

**PR:** #$0 | **Today:** !`date +%Y-%m-%d`
**Git branch:** !`git branch --show-current`
**Project:** !`bash "${CLAUDE_SKILL_DIR}/../../scripts/detect-project.sh" 2>/dev/null || true`
**Artifacts dir:** !`bash "${CLAUDE_SKILL_DIR}/../../scripts/artifact-dir.sh" respond "pr-$0" 2>/dev/null || echo ""`
**Review memory dir:** !`bash "${CLAUDE_SKILL_DIR}/../../scripts/artifact-dir.sh" review 2>/dev/null || echo ""`
**Open threads:** !`gh pr view $0 --json reviewThreads --jq '[.reviewThreads[] | select(.isResolved == false)] | length' 2>/dev/null || true`
**PR diff stat:** !`gh pr diff $0 --stat 2>/dev/null || true`

**Args:** `$0`=PR# (required) · `$1`=Jira key (optional, for AC context)

Read CLAUDE.md first — auto-loaded, contains project patterns and conventions.

## References

| File | Load when |
| --- | --- |
| [references/phase-1-triage.md](references/phase-1-triage.md) | Entering Phase 1 |
| [references/phase-2-fix.md](references/phase-2-fix.md) | Entering Phase 2 |
| [references/phase-3-reply.md](references/phase-3-reply.md) | Entering Phase 3 |
| [references/phase-4-rerequest.md](references/phase-4-rerequest.md) | Entering Phase 4 |
| [references/teammate-prompts.md](references/teammate-prompts.md) | Phase 2: creating Fixer teammates |
| [references/phase-gates.md](references/phase-gates.md) | Any gate transition |
| [references/operational.md](references/operational.md) | Mode detection, compression recovery, success criteria |
| [../review-conventions/SKILL.md](../review-conventions/SKILL.md) | Phase 3: reply format and comment labels |
| [../jira-integration/SKILL.md](../jira-integration/SKILL.md) | Phase 1 Step 2: when Jira key detected in `$1` |
| [references/examples.md](references/examples.md) | When calibrating reply quality, fix scope, or triage table format |

---

## Prerequisite Check

Detect mode per [references/operational.md](references/operational.md) Graceful Degradation table. Inform user.

---

## Phase Flow

| Phase | Actor | Description | Reference |
| --- | --- | --- | --- |
| 1 — Triage | Lead | Fetch threads, classify severity, cluster by file, write respond-context.md | [phase-1-triage.md](references/phase-1-triage.md) |
| 2 — Fix Threads | Fixers | Bootstrap, fix Critical→Important→Suggestion, intent verify | [phase-2-fix.md](references/phase-2-fix.md) |
| 3 — Reply | Lead | Post thread replies + PR summary via gh API | [phase-3-reply.md](references/phase-3-reply.md) |
| 4 — Re-request Review | Lead | Re-request original reviewer, cleanup, final summary | [phase-4-rerequest.md](references/phase-4-rerequest.md) |

---

## Constraints

- **review-dismissed.md is read-only here** — review and build both write to this file; respond reads it only (Step 4 triage)
- **Fix scope = thread scope only** — why: scope creep makes re-review harder and risks introducing new issues unrelated to the review
- **Validate BEFORE commit** — why: reverting uncommitted changes is cheaper than reverting commits; catches regressions before they enter history
- **Never silently skip a Critical thread** — why: skipped Criticals become production incidents; if unfixable, the decision must be explicit and documented
- **Max 3 fix attempts per thread** — why: beyond 3 attempts = architectural mismatch, not a surface fix; further attempts waste tokens without progress
- **One commit per thread group** — why: enables clean revert of one fix without affecting others

## Gotchas

- **Run after review comments are posted, not before** — the skill fetches open threads from GitHub; if no review has been submitted yet, the thread list is empty and nothing gets fixed. Confirm reviewer comments are posted before invoking.
- **fix-intent-verifier requires GitHub App permissions** — the verifier reads thread text via `gh api`. If the token lacks `pull_requests: read` scope, the intent verification step fails silently and Fixers proceed without the check.
- **Parallel Fixers must not share files** — the file-group clustering (Step 6) prevents this, but if two threads touch the same file through different group assignments, write conflicts occur. Review the triage table's GROUP column before approving the fix phase.
- **respond-context.md is ephemeral** — it is written to `{artifacts_dir}` (centralized, not the project repo) and deleted after Phase 4. If the session crashes mid-run, the file remains and must be cleaned up manually before re-running.
- **Re-request review targets the original reviewer login** — the skill uses `gh pr edit --add-reviewer {original_reviewer_login}`. If the reviewer has left the org or changed their login, this step fails. Verify the login before Phase 4.
