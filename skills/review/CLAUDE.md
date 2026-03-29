# review skill

Experimental Agent Teams-based PR review with adversarial debate.
Uses 3 reviewer teammates that challenge each other's findings instead of 7 parallel subagents.

## How It Differs

See root [CLAUDE.md § Skill Comparison](../../CLAUDE.md) for full build/review/debug/respond comparison.

## Docs Index

| Reference | When to use |
| --- | --- |
| `../../debate-protocol/SKILL.md` | Modifying debate rules, round structure, or consensus criteria |
| `../../review-conventions/SKILL.md` | Shared review conventions (labels, dedup, strengths) |
| `../../review-output-format/SKILL.md` | Output format template |
| `references/operational.md` | Graceful Degradation, Context Compression Recovery, Success Criteria |

## Skill Architecture

- `SKILL.md` — lead orchestration playbook; phases, team creation, debate flow
- `../../debate-protocol/SKILL.md` — debate rules, round-robin assignment, consensus criteria
- Reuses shared `../../review-conventions/SKILL.md` and `../../review-output-format/SKILL.md`
- Project-specific Hard Rules loaded from `{project_root}/.claude/skills/review-rules/hard-rules.md` if present

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/review/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/review

# Test invocation (requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1):
# /review <pr-number> [Author|Reviewer]
```

## Gotchas

- Agent Teams constraints: see root [CLAUDE.md § Agent Teams Constraints](../../CLAUDE.md)
- Agent teams have no session resumption for in-process teammates — recommend tmux mode
- Teammates are READ-ONLY during review and debate — code changes only in action phase
- Max 2 debate rounds enforced by lead — prevents runaway token usage
- Phase 1 Bootstrap uses `pr-review-bootstrap` agent (Haiku) — if unavailable, teammates gather context themselves
- Pre-Debate Triage skips debate for Auto-pass (Hard Rule + conf ≥90) and Auto-drop (Info + conf <80) findings
- Dismissed findings persist at `{review_memory_dir}/review-dismissed.md` — cap 50 entries FIFO
