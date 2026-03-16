# Workflow Modes

Classification criteria for Full vs Quick mode. Lead auto-classifies at Phase 0; user can override.

## Mode Selection

| Mode | When | Phases | Estimated sessions |
| --- | --- | --- | --- |
| **Full** | Multi-file feature, architectural change, new domain | All (0-6) | 9-14 |
| **Quick** | Bug fix, small refactor, fix PR comments, single-file change | Skip Phase 1 | 6-10 |

## Auto-Classification Rules

**Full mode** — any of:

- Task mentions "new feature", "add endpoint", "new module", "redesign", "migration"
- Task references a Jira epic or multi-story ticket
- Task requires touching 3+ files across different layers
- Task involves schema change or API contract change
- User explicitly passes `--full`

**Quick mode** — all of:

- Task is a bug fix, refactor, or PR comment fix
- Scope is 1-2 files in the same layer
- No schema or API contract changes
- No new domain concepts introduced
- User explicitly passes `--quick`

**Ambiguous** — ask user: "This could be Full or Quick. Full adds a research phase (~2-3 explorer sessions). Which do you prefer?"

## Mode Differences

| Aspect | Full | Quick |
| --- | --- | --- |
| Phase 1 (Research) | 2-3 explorer teammates | Skipped |
| Phase 2 (Plan) | From research.md | From task description directly |
| Phase 3 (Implement) | May use parallel workers | Usually 1 worker |
| Phase 4 (Review) | Full 3-reviewer debate | Full 3-reviewer debate |
| Artifacts | research.md + plan.md | plan.md only |

## User Override

User can always override classification:

- `/team-dev-loop "simple bug" --full` → forces Full mode (extra research won't hurt)
- `/team-dev-loop "big feature" --quick` → forces Quick mode (lead warns about risk but complies)
