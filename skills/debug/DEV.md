# debug skill

Systematic debugging with Agent Teams: parallel Investigator + DX Analyst, then Fixer.
Combines systematic-debugging methodology with DX analysis to fix bugs and harden the affected area.

## How It Differs

See root [CLAUDE.md § Skill Comparison](../../CLAUDE.md) for full build/review/debug/respond comparison.

## Docs Index

| Reference | When to use |
| --- | --- |
| `references/teammate-prompts.md` | Modifying Investigator, DX Analyst, or Fixer prompts |
| `references/dx-checklist.md` | Modifying DX audit categories, severity criteria, or Quick mode checklist |
| `references/phase-gates.md` | Modifying gate conditions or escalation protocol |
| `../../review-conventions/SKILL.md` | Shared review conventions (if adding review phase later) |
| `references/operational.md` | Graceful Degradation, Context Compression Recovery, Success Criteria |

## Skill Architecture

- `SKILL.md` — lead orchestration playbook; phases, team creation, fix flow
- `references/teammate-prompts.md` — prompt templates for Investigator, DX Analyst, Fixer (Full + Quick)
- `references/dx-checklist.md` — DX audit categories with severity criteria
- `references/phase-gates.md` — gate conditions for every phase transition
- Project-specific Hard Rules loaded from `{project_root}/.claude/skills/review-rules/hard-rules.md` if present

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/debug/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/debug

# Test invocation (requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1):
# /debug "NullPointerException in UserService.findById"
# /debug "API returns 500 on empty payload" --quick
```

## Gotchas

- Agent Teams constraints: see root [CLAUDE.md § Agent Teams Constraints](../../CLAUDE.md)
- Agent Teams have no session resumption — if lead crashes, `debug-context.md` + `investigation.md` enable manual recovery
- Investigator and DX Analyst are never alive simultaneously with Fixer — Phase 1 teammates shut down before Phase 2
- Max 2 teammates concurrent (Investigator + DX Analyst), then 1 (Fixer)
- DX scope = affected area only — not codebase-wide improvements
- 3 fix attempts max — beyond that is an architectural problem, escalate to user
- Artifacts written to `{artifacts_dir}` (path from `scripts/artifact-dir.sh debug`): `debug-context.md`, `investigation.md`
- Quick mode still has DX awareness via condensed checklist — not zero DX
