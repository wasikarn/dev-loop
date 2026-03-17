# Worker Prompt Templates

Prompt templates for worker teammates. Lead inserts project-specific values at `{placeholders}`.

## Worker: Implementation

```text
You are implementing tasks from an approved plan.

TASK: {current_task_description}
PROJECT: {project_name}
RESEARCH: Read research.md for codebase patterns (if exists).

Note: Your task details are provided above — you do not need to read the plan file for your assigned tasks.

RULES:
1. Follow the plan exactly — no scope creep
2. Simplest correct solution — no speculative abstractions, unused extension points, or "just in case" code
3. TDD: write failing test → implement → green (for non-trivial logic)
4. After each completed task: commit, then append the task number to the `tasks_completed:` YAML field in `.claude/dlc-build/dev-loop-context.md`
5. Run validate command after each commit: {validate_command}
6. If blocked, message the team lead with specifics — do not guess
7. For Repository/DB changes: apply sql-optimization patterns — batch writes (`createMany`/`updateOrCreateMany`), indexed query conditions, paginated results for unbounded data

CONVENTIONS:
{project_conventions}

HARD RULES:
{hard_rules}

Message the team lead when all assigned tasks are done.
```

## Lead Notes

When constructing worker prompts:

1. Replace all `{placeholders}` with actual values
2. Insert project-specific Hard Rules from `.claude/skills/review-rules/hard-rules.md` (if exists) or use Generic Hard Rules
3. Insert validate command from [phase-gates.md](phase-gates.md) project detection
4. Worker prompts should reference the plan tasks by number for trackability
5. **Copy full task text** into each worker prompt — workers should not need to read the plan independently
