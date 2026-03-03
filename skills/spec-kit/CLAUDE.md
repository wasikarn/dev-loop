# spec-kit skill

Wraps [github/spec-kit](https://github.com/github/spec-kit) SDD toolkit.
SKILL.md is the agent entry point; references/ provides supporting detail.

## Docs Index

Prefer reading before editing — key references:

| Reference | When to use |
| --- | --- |
| `references/workflow.md` | Updating phase descriptions or gate conditions |
| `references/prerequisites.md` | Updating required tools or setup steps |
| `references/cli.md` | Updating command templates |
| `references/spec-quality.md` | Updating spec quality criteria |
| `scripts/detect-phase.sh` | Updating phase detection logic |

## Skill Architecture

- `SKILL.md` — maps 6 ordered slash commands: constitution → specify → clarify → plan → tasks → implement
- `references/workflow.md` — phase sequence and gate conditions (each phase output gates the next)
- `references/cli.md` — command templates (synced from upstream github/spec-kit)
- `references/spec-quality.md` — defines what makes a spec complete, testable, and unambiguous
- `scripts/detect-phase.sh` — infers current phase from artifacts present in repo

## Updating This Skill

When upstream spec-kit releases changes, fetch command templates directly:

```bash
gh api "repos/github/spec-kit/contents/templates/commands/<cmd>.md" --jq '.content' | base64 -d
```

Commands: `constitution`, `specify`, `clarify`, `plan`, `tasks`, `implement`, `analyze`, `checklist`, `taskstoissues`

Also check `spec-driven.md` for workflow philosophy updates:

```bash
curl -s https://raw.githubusercontent.com/github/spec-kit/main/spec-driven.md
```

## Skill System

SKILL.md frontmatter controls how Claude invokes this skill:

- `description:` — Claude matches user intent; prefer trigger-complete descriptions — wrong description = skill never fires; include trigger phrases like "start a spec", "speckit"
- `name:` — the slash command name (`/spec-kit`)
- `context: fork` — isolates skill in a fork context (add for agent-heavy skills)

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/spec-kit/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/spec-kit

# Invoke skill:
# /spec-kit <feature-description>
# Then follow phase prompts: /speckit.constitution → /speckit.specify → ... → /speckit.implement
```

## Gotchas

- This CLAUDE.md is **tracked in git** — changes here are shared with the team
- Phases run in strict order — each phase output is required input to the next; skipping produces incomplete artifacts
- Upstream spec-kit may release breaking changes — check `spec-driven.md` before updating `references/cli.md`
