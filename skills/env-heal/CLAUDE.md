# env-heal skill

Scans entire codebase for env var references, cross-references against schema and `.env.example`, auto-fixes and tests.
Runs as isolated subagent (`context: fork`).

## Docs Index

| Reference | When to use |
| --- | --- |
| `scripts/scan-env-refs.sh` | Phase 1 env var discovery — bash 3.x compatible, outputs JSON |

## Skill Architecture

- `SKILL.md` — 7-phase workflow: discover → read schema → gap analysis → classify → fix → test → report
- **`--quick` mode** skips Phase 1 (codebase scan) and Phase 4 (classify), only comparing schema vs example — replaces the former `env-check` skill
- Runs in `context: fork` with `agent: general-purpose` — isolated subagent, no lead context
- Target: tathep-platform-api primarily (AdonisJS `Env.schema`), but grep patterns work for any Node.js project

## Validate After Changes

```bash
# Lint
npx markdownlint-cli2 "skills/env-heal/**/*.md"

# Verify symlink
ls -la ~/.claude/skills/env-heal

# Invoke (run in tathep-platform-api repo):
# /env-heal            # full mode
# /env-heal --quick    # schema vs example only (former env-check)
```

## Gotchas

- `context: fork` means this skill runs as an isolated subagent — no access to lead conversation context
- `env-check` has been merged into this skill as `--quick` mode — the `env-check` skill no longer exists
- Auto-fix uses heuristics for type inference (name contains PORT → number, contains ENABLE → boolean)
- Reverts changes if tests fail 3 times — safe by design
- Never adds actual secret values — only empty strings or placeholders
