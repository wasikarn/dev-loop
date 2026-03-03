# api-review-pr skill

PR review skill for tathep-platform-api (AdonisJS 5.9 + Effect-TS + Clean Architecture + Japa tests).
SKILL.md is the agent entry point; references/ provides supporting detail.

## Reference File Map

| File | Purpose |
|------|---------|
| `references/checklist.md` | 12-point review criteria with severity levels |
| `references/examples.md` | Code examples for project-specific rules (#2–#8) |

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/api-review-pr/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/api-review-pr
```

## Skill System

SKILL.md frontmatter controls how Claude invokes this skill:

- `description:` — Claude matches user intent against this field; **must be trigger-complete**
- `name:` — the slash command name (`/api-review-pr`)
- `context: fork` + `disable-model-invocation: true` — isolates heavy 7-agent dispatch

## Project Context

- **GitHub repo:** `100-Stars-Co/bd-eye-platform-api`
- **Jira key format:** `BEP-XXXX`
- **Validate command:** `npm run validate:all`
- **Reference modules:** `Questionnaire/` (simple pattern), `Sms/` (gold standard)
- **Scope:** `git diff develop...HEAD` — changed files only

## Gotchas

- This CLAUDE.md is **tracked in git** — changes here are shared with the team
- Reviewer comments must be in Thai mixed with English technical terms (casual Slack/PR tone)
- Submit all inline comments + decision in ONE `gh api` call — not one-by-one
