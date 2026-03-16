# Operational Reference

## Graceful Degradation

| Level | Available tools | Behavior |
| --- | --- | --- |
| **Agent Teams** | TeamCreate, SendMessage | Full workflow — 3 teammates with adversarial debate |
| **Subagent** | Task (Agent tool) | Same phases, but: reviewers as parallel subagents (existing tathep-\*-review-pr pattern). No debate (can't message). Lead consolidation only. |
| **Solo** | None (lead only) | Recommend project-specific review skills (`/tathep-*-review-pr`). If none available, lead does sequential checklist-based review. |

Detect at Prerequisite Check and inform user of mode.

## Context Compression Recovery

If session compacts mid-workflow, re-read in order:

1. PR diff (`gh pr diff $0`) — what's being reviewed
2. Debate summary (if in Phase 3+) — findings and consensus status
3. Progress tracker in conversation — current phase

## Success Criteria

- [ ] Agent team created with 3 teammates
- [ ] All 3 independent reviews completed (CHECKPOINT)
- [ ] Debate round(s) completed with summary table
- [ ] Findings consolidated with consensus indicators
- [ ] Critical issues: zero (Author) or documented (Reviewer)
- [ ] Author: validate passes / Reviewer: review submitted
- [ ] Team cleaned up
