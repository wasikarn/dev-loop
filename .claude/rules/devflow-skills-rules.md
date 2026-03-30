---
paths:
  - "skills/**"
---

# Devflow Skill Conventions

Skills live at `skills/<name>/SKILL.md`. See `docs/references/skills-best-practices.md` for full spec.

**Required frontmatter fields:** `name` · `description`

**Optional fields:** `argument-hint` · `compatibility` · `effort` · `allowed-tools` · `user-invocable` · `model` · `context` · `agent`

**Rules:**

- `description:` trigger-complete (what + when + keywords), max 1024 chars
- `user-invocable: false` hides from `/` menu but allows auto-trigger — use for reference/background skills
- `disable-model-invocation` is explicitly NOT used in devflow (removed in daf9ca9 to enable auto-triggering)
- `compatibility:` recommended for skills with external tool dependencies
- `context: fork` + `agent:` runs skill in isolated subagent — used sparingly (only env-heal)
- `allowed-tools:` restricts which tools the skill can invoke
- Background skills (preloaded into agents via `skills:`) use `user-invocable: false`

**Reference structure:**

```text
skills/<name>/
├── SKILL.md           # entry point
├── CLAUDE.md          # contributor context
└── references/        # on-demand docs (load when needed)
    ├── phase-*.md
    └── *.md
```

**Pre-commit hook** auto-fixes staged `.md` files — no manual lint before commit.
