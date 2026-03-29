# build skill

Full development loop with Agent Teams: Research → Plan → Implement → Review → Ship.
Uses dynamic team roster (explorers, workers, reviewers) with iterative implement-review loop.

## How It Differs

See root [CLAUDE.md § Skill Comparison](../../CLAUDE.md) for full build/review/debug/respond comparison.

## Docs Index

| Reference | When to use |
| --- | --- |
| `references/phase-gates.md` | Modifying gate conditions or escalation protocol |
| `references/phase-{1-9}-*.md` | Modifying a specific phase's logic — one file per phase |
| `references/explorer-prompts.md` | Modifying explorer prompts (Phase 2) |
| `references/worker-prompts.md` | Modifying worker implementation prompt (Phase 4 iter 1) |
| `references/fixer-prompts.md` | Modifying fixer prompt (Phase 4 iter 2+) |
| `references/reviewer-prompts.md` | Modifying reviewer prompts (Phase 6) |
| `references/reviewer-shared-rules.md` | Shared reviewer rules/output format (referenced by each reviewer template) |
| `references/workflow-modes.md` | Modifying Full/Quick/Hotfix classification + mode decision tree |
| `references/review-lenses/` | Domain-specific review checklists (security/perf/frontend/DB/TypeScript) |
| `references/review-lenses/error-handling.md` | Error handling lens — silent failure patterns; injected when diff contains try/catch/async |
| `../../review-conventions/SKILL.md` | Shared review conventions (labels, dedup, strengths) |
| `references/operational.md` | Graceful Degradation, Crash Recovery, Regression Gate, Solo findings |
| `../../review-output-format/SKILL.md` | Review output format template |
| `../../debate-protocol/SKILL.md` | Adversarial debate rules (fallback in phase-6-review.md) |

## Skill Architecture

- `SKILL.md` — overview, phase flow, reference table, constraints, gate summary (~100 lines)
- `references/phase-{1-9}-*.md` — phase-specific instructions (load on demand)
- Role-specific prompt files: explorer, worker, fixer, reviewer
- `references/review-lenses/` — domain checklists injected into reviewer prompts at Phase 6
- `references/phase-gates.md` — gate conditions for every phase transition
- `references/explorer-prompts.md`, `references/worker-prompts.md`, `references/fixer-prompts.md`, `references/reviewer-prompts.md` — role-specific prompt templates
- `references/workflow-modes.md` — Mode Capability Matrix (Micro/Quick/Full/Hotfix), blast-radius scoring, PhaseVerdict schema
- Reuses `review` pattern for Phase 6 Stage 2 (review + debate)
- Project-specific Hard Rules loaded from `.claude/skills/review-rules/hard-rules.md` in the target project

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/build/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/build

# Test invocation (requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1):
# /build "Add health check endpoint" --full
# /build "Fix null check in UserService" --quick
# /build "ABC-1234 production crash" --hotfix
```

## Gotchas

- Agent Teams constraints: see root [CLAUDE.md § Agent Teams Constraints](../../CLAUDE.md)
- Agent Teams have no session resumption — if lead crashes, artifacts on disk enable manual recovery
- Workers and reviewers are never alive simultaneously — workers during Phase 4, reviewers during Phase 6
- Review scope narrows each iteration: 3 reviewers → 2 → 1, full debate → focused → spot-check
- Max 3 loop iterations enforced — prevents runaway token usage
- Artifacts written to **`{artifacts_dir}/{date}-{slug}/`** (path from `scripts/artifact-dir.sh build`): `devflow-context.md`, `research.md`, `plan.md`, `verify-results.md`, `review-findings-*.md`. All artifacts in one folder — `~/.claude/plans/` is no longer used.
