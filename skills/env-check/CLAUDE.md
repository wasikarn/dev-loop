# env-check skill

Validates environment variable consistency between `.env.example` and `env.ts` schema.
Runs as isolated subagent (`context: fork`).

## Docs Index

| Reference | When to use |
| --- | --- |
| (no references) | SKILL.md is self-contained |

## Skill Architecture

- `SKILL.md` — 5-step workflow: read files → compare → fix → test → report
- Runs in `context: fork` with `agent: general-purpose` — isolated subagent, no lead context
- Target: tathep-platform-api only (AdonisJS `Env.schema` + `.env.example`)

## Validate After Changes

```bash
# Lint
npx markdownlint-cli2 "skills/env-check/**/*.md"

# Verify symlink
ls -la ~/.claude/skills/env-check

# Invoke (run in tathep-platform-api repo):
# /env-check
```

## Gotchas

- `context: fork` means this skill runs as an isolated subagent — no access to lead conversation context
- Only works with AdonisJS `Env.schema` pattern — not generic for all projects
- Uses `node ace test` for validation — must be run from tathep-platform-api root
- Sibling skill `env-heal` is a superset — scans all code references, not just schema vs example
