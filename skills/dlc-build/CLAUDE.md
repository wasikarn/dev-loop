# team-dev-loop skill

Full development loop with Agent Teams: Research → Plan → Implement → Review → Ship.
Uses dynamic team roster (explorers, workers, reviewers) with iterative implement-review loop.

## How It Differs from Other Skills

| Aspect | team-review-pr | team-dev-loop | team-debug |
| --- | --- | --- | --- |
| Scope | PR review + debate | Full dev loop | Debug + DX harden |
| Execution | 3 teammates (debate) | Dynamic roster per phase | Investigator + DX Analyst + Fixer |
| Review | Adversarial debate | Embedded (reuses team-review-pr) | N/A (no review phase) |
| Loop | None | Implement-Review (max 3 iter) | Fix-only (max 3 attempts) |
| Artifacts | Findings in output | research.md, plan.md, review-findings-N.md | debug-context.md, investigation.md |

## Docs Index

| Reference | When to use |
| --- | --- |
| `references/phase-gates.md` | Modifying gate conditions or escalation protocol |
| `references/teammate-prompts.md` | Modifying explorer, worker, reviewer, or fixer prompts |
| `references/workflow-modes.md` | Modifying Full vs Quick classification criteria |
| `../../references/review-conventions.md` | Shared review conventions (labels, dedup, strengths) |
| `references/operational.md` | Graceful Degradation, Context Compression Recovery, Success Criteria |
| `../../references/review-output-format.md` | Review output format template |
| `../team-review-pr/references/debate-protocol.md` | Adversarial debate rules |

## Skill Architecture

- `SKILL.md` — lead orchestration playbook; phases, team creation, loop flow
- `references/phase-gates.md` — gate conditions for every phase transition
- `references/teammate-prompts.md` — prompt templates for all teammate roles
- `references/workflow-modes.md` — Full vs Quick classification criteria
- Reuses `team-review-pr` for Phase 4 (review + debate)
- Reuses `deep-research-workflow` patterns for Phase 1-2 (research + plan)
- Project-specific Hard Rules loaded dynamically from `tathep-*-review-pr` skills

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/team-dev-loop/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/team-dev-loop

# Test invocation (requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1):
# /team-dev-loop "Add health check endpoint" --full
# /team-dev-loop "Fix null check in UserService" --quick
```

## Gotchas

- Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` — degrades gracefully to subagent or solo mode
- Agent Teams have no session resumption — if lead crashes, artifacts on disk enable manual recovery
- Workers and reviewers are never alive simultaneously — workers during Phase 3, reviewers during Phase 4
- Review scope narrows each iteration: 3 reviewers → 2 → 1, full debate → focused → spot-check
- Hard Rules cannot be dropped via debate — only reclassified with evidence
- Max 3 loop iterations enforced — prevents runaway token usage
- Artifacts written to **target project root** (not this skills repo): `dev-loop-context.md`, `research.md`, `plan.md`, `review-findings-*.md`
- Team cleanup must be done by lead in Phase 6 — teammates don't self-terminate
- One team per session — cannot run multiple team-dev-loop in parallel
