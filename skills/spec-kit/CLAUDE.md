# spec-kit skill

Wraps [github/spec-kit](https://github.com/github/spec-kit) SDD toolkit.
SKILL.md is the agent entry point; references/ provides supporting detail.

## Reference File Map

| File |
| ------ |
| `references/workflow.md` |
| `references/prerequisites.md` |
| `references/cli.md` |
| `references/spec-quality.md` |
| `scripts/detect-phase.sh` |

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

- `description:` — Claude matches user intent against this field; **must be trigger-complete**
  (wrong description = skill never fires; include explicit trigger phrases like "start a spec", "speckit", etc.)
- `name:` — the slash command name (`/spec-kit`)
- `context: fork` — isolates skill in a fork context (add for agent-heavy skills)

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/spec-kit/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/spec-kit
```

## Gotchas

- This CLAUDE.md is **tracked in git** — changes here are shared with the team
