# Operational Reference

## Graceful Degradation

| Level | Available tools | Behavior |
| --- | --- | --- |
| **Agent Teams** | TeamCreate, SendMessage | Full workflow — teammates communicate |
| **Subagent** | Task (Agent tool) | Same phases, teammates as subagents (no messaging). Investigator + DX Analyst as parallel subagents. Fixer as sequential subagent. |
| **Solo** | None (lead only) | Lead executes all phases sequentially. Investigation = systematic-debugging methodology inline. DX = checklist from `dx-checklist.md`. Fix = lead implements directly. |

Detect at Prerequisite Check and inform user of mode.

## Context Compression Recovery

If session compacts mid-workflow, re-read in order:

1. `debug-context.md` — bug, severity, mode, project, Hard Rules
2. `investigation.md` — root cause + DX findings + fix plan (if exists)
3. Progress tracker in conversation — current phase

## Success Criteria

- [ ] Prerequisite check completed (Agent Teams / subagent / solo detected)
- [ ] Project detected and conventions loaded
- [ ] Investigator completed with root cause evidence (file:line)
- [ ] DX Analyst completed with findings table (Full mode only)
- [ ] investigation.md written with merged findings and fix plan
- [ ] Bug fix committed with regression test
- [ ] DX improvements committed (Critical: all, Warning: as appropriate)
- [ ] Validate command passes after all commits
- [ ] Summary presented to user with completion options
- [ ] Team cleaned up (all teammates shut down)
