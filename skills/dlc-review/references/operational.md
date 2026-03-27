# Operational Reference

## Graceful Degradation

| Level | Available tools | Behavior |
| --- | --- | --- |
| **Agent Teams** | TeamCreate, SendMessage | Full workflow — 3 teammates with adversarial debate |
| **Subagent** | Task (Agent tool) | Same phases, but: reviewers as parallel subagents. No debate (can't message). Lead consolidation only. |
| **Solo** | None (lead only) | Lead does sequential checklist-based review using review-conventions.md. |

Detect at Prerequisite Check and inform user of mode.

### Phase Coverage by Mode

| Phase | Agent Teams | Subagent | Solo |
| --- | --- | --- | --- |
| Phase 1: Worktree Setup | ✅ | ✅ | ✅ |
| Phase 1 Bootstrap (pr-review-bootstrap) | ✅ | ✅ (or fallback) | ❌ skip |
| Phase 1 Bootstrap (Jira fetch, concurrent, if key) | ✅ if Jira key | ✅ if Jira key | ✅ if Jira key |
| Phase 1 Scope Assessment | ✅ | ✅ | ✅ |
| Phase 2: Project Detection | ✅ | ✅ | ✅ |
| Phase 3: Independent Review | ✅ (3 teammates) | ✅ (3 subagents) | ✅ (lead only, sequential) |
| Phase 4: Debate | ✅ | ❌ skip (no messaging) | ❌ skip |
| Phase 5: Convergence | ✅ | ✅ (lead consolidates) | ✅ (lead consolidates) |
| Phase 6: Action | ✅ | ✅ | ✅ |
| Phase 7: Cleanup | ✅ | ✅ | ✅ |

## Context Compression Recovery

If session compacts mid-workflow, re-read in order:

1. PR diff (`gh pr diff $0`) — what's being reviewed
2. Debate summary (if in Phase 4+) — findings and consensus status
3. Progress tracker in conversation — current phase
4. Phase 3 progress table from conversation — which teammates completed (prevents re-running finished reviews)
5. Re-run `pr-review-bootstrap` agent if `{bootstrap_context}` is lost — avoids 3x diff reads
6. AC checklist from Phase 1 Bootstrap output in conversation — if Jira key was provided

## Success Criteria

- [ ] Agent team created with 3 teammates
- [ ] All 3 independent reviews completed (CHECKPOINT)
- [ ] Debate round(s) completed with summary table
- [ ] Findings consolidated with consensus indicators
- [ ] Critical issues: zero (Author) or documented (Reviewer)
- [ ] Author: validate passes / Reviewer: review submitted
- [ ] Team cleaned up

## Gotchas

- **Agent Teams required for adversarial debate** — without `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, the skill falls back to subagent mode (no debate, parallel subagent review) or solo mode (sequential checklist). Three-reviewer debate only runs in Agent Teams mode.
- **Input must be a PR number, not a title or URL** — passing PR title text or a GitHub URL instead of a bare number causes `gh pr diff` to fail silently. Extract the numeric ID first: `gh pr list` or the PR URL's trailing number.
- **Massive PRs (>1000 lines) skip debate** — the skill auto-downgrades to Correctness-only review with Hard Rules + confidence ≥85. Users expecting full debate on large diffs will not get it; split the PR if full coverage is needed.
- **Reviewer mode creates a git worktree** — `gh pr checkout $0 --worktree /tmp/review-pr-$0` requires a clean repo state. If the worktree already exists from a previous failed run, the checkout fails. Clean up manually: `git worktree remove /tmp/review-pr-$0`.
- **Dismissed patterns file persists across sessions** — `review-dismissed.md` accumulates up to 50 entries and suppresses re-raising of those patterns. If a pattern was wrongly dismissed, manually remove it from the file before re-running the review.
