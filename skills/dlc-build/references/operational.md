# Operational Reference

## Graceful Degradation

| Level | Available tools | Behavior |
| --- | --- | --- |
| **Agent Teams** | TeamCreate, SendMessage | Full workflow as described |
| **Subagent** | Task (Agent tool) | Same phases, but: explorers/workers/reviewers as subagents. No debate (can't message). Review = 7-agent parallel (existing tathep-\*-review-pr pattern). |
| **Solo** | None (lead only) | Lead executes all phases sequentially. Research = lead explores. Review = self-review with checklist. Loop still applies. |

Detect at Phase 0 and inform user of mode.

## Context Compression Recovery

If session compacts mid-workflow, re-read in order:

1. `dev-loop-context.md` — task, mode, project, Hard Rules
2. `plan.md` — task list with checkmarks showing progress
3. Latest `review-findings-*.md` — current iteration findings (if in loop)
4. Progress tracker in conversation — iteration count and phase

## Success Criteria

- [ ] Prerequisite check completed (Agent Teams / subagent / solo detected)
- [ ] Project detected and conventions loaded
- [ ] Mode classified (Full/Quick) and confirmed by user
- [ ] Research completed with file:line evidence (Full mode only)
- [ ] Plan approved by user (annotation cycle done)
- [ ] All plan tasks implemented with commits
- [ ] Validate command passes after implementation
- [ ] Review completed with findings consolidated
- [ ] Critical findings resolved (zero remaining or user-accepted)
- [ ] Summary presented to user with completion options
- [ ] Team cleaned up (all teammates shut down)
