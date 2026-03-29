# respond skill

Address PR review comments: fetch threads → fix code → reply on GitHub → re-request review.

## How It Differs

See root [CLAUDE.md § Skill Comparison](../../CLAUDE.md) for full build/review/debug/respond comparison.

## Docs Index

| Reference | When to use |
| --- | --- |
| `references/teammate-prompts.md` | Modifying Fixer prompt or thread grouping strategy |
| `references/phase-gates.md` | Modifying gate conditions or escalation protocol |
| `references/operational.md` | Graceful Degradation, Context Compression Recovery, Success Criteria |
| `../../review-conventions/SKILL.md` | Shared comment labels and reply format conventions |
| `../../jira-integration/SKILL.md` | Jira detection, AC-based thread prioritization |

## Skill Architecture

- `SKILL.md` — lead orchestration playbook; phases, team creation, fix flow
- `references/teammate-prompts.md` — Fixer prompt template with battle-tested rules
- `references/phase-gates.md` — explicit gate conditions for every phase transition
- `references/operational.md` — graceful degradation levels, compression recovery, success criteria
- Project-specific Hard Rules loaded from `{project_root}/.claude/skills/review-rules/hard-rules.md` if present
- Dismissed patterns loaded (read-only) from `{review_memory_dir}/review-dismissed.md` if present

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/respond/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/respond

# Test invocation (requires a real PR with open review threads):
# /respond 42
# /respond 42 ABC-1234
```

## Gotchas

- Agent Teams constraints: see root [CLAUDE.md § Agent Teams Constraints](../../CLAUDE.md)
- `review-dismissed.md` is **read-only** here — `review` and `build` write it, `respond` only reads it
- `respond-context.md` is written to `{artifacts_dir}/respond-context.md` (centralized, not the project repo) — clean up after done
- Fixer teammates must validate BEFORE committing — not after (validated BEFORE vs AFTER matters for revert cost)
- Max 3 fix attempts per thread — beyond 3 = architectural mismatch, escalate to user
- Thread grouping: same file → 1 Fixer (never parallel writes to same file)
- Jira context is never blocking — if fetch fails, proceed without it
