# env-heal skill

Scans entire codebase for env var references, cross-references against schema and `.env.example`, auto-fixes and tests.
Runs as isolated subagent (`context: fork`).

## Docs Index

| Reference | When to use |
| --- | --- |
| (no references) | SKILL.md is self-contained |

## Skill Architecture

- `SKILL.md` — 7-phase workflow: discover → read schema → gap analysis → classify → fix → test → report
- Runs in `context: fork` with `agent: general-purpose` — isolated subagent, no lead context
- Target: tathep-platform-api primarily (AdonisJS `Env.schema`), but grep patterns work for any Node.js project

## Validate After Changes

```bash
# Lint
npx markdownlint-cli2 "skills/env-heal/**/*.md"

# Verify symlink
ls -la ~/.claude/skills/env-heal

# Invoke (run in tathep-platform-api repo):
# /env-heal
```

## Gotchas

- `context: fork` means this skill runs as an isolated subagent — no access to lead conversation context
- Superset of `env-check` — scans all `process.env.*`, `Env.get()`, `env()` patterns in code
- Auto-fix uses heuristics for type inference (name contains PORT → number, contains ENABLE → boolean)
- Reverts changes if tests fail 3 times — safe by design
- Never adds actual secret values — only empty strings or placeholders
