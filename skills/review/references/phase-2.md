# Phase 2: Project Detection

Use the `Project` JSON from the header (output of `detect-project.sh`). It contains: `project`, `repo`, `validate`, `base_branch`, `branch`.

Check for project-specific rules at `{project_root}/.claude/skills/review-rules/`:

```text
.claude/skills/review-rules/hard-rules.md exists?
├→ Yes: load it as project Hard Rules + note checklist.md and examples.md paths:
│       {project_root}/.claude/skills/review-rules/checklist.md
│       {project_root}/.claude/skills/review-rules/examples.md
└→ No:  use generic rules below
```

Pass checklist.md and examples.md paths to Phase 3 teammates so they can reference project-specific patterns.

If no review-rules found, use generic rules:

**Generic Hard Rules** (flag unconditionally):

- `as any` / `as unknown as T` → Critical (destroys type safety)
- empty `catch {}` / swallowed errors → Critical (silent failures)
- nesting > 1 level → Critical (use guard clauses, extract function, or lookup table)
- query inside loop → Critical (N+1)
- `console.log` in production code → Critical (use structured logger)
