# web-review-pr skill

PR review skill for tathep-website (Next.js 14 Pages Router + Chakra UI + React Query v3).
SKILL.md is the agent entry point; references/ provides supporting detail.

## Reference File Map

| File | Purpose |
|------|---------|
| `references/checklist.md` | 12-point review criteria with severity levels |
| `references/examples.md` | Code examples for project-specific rules |

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/web-review-pr/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/web-review-pr
```

## Skill System

SKILL.md frontmatter controls how Claude invokes this skill:

- `description:` — Claude matches user intent against this field; **must be trigger-complete**
- `name:` — the slash command name (`/web-review-pr`)
- `context: fork` + `disable-model-invocation: true` — isolates heavy 7-agent dispatch

## Project Context

- **GitHub repo:** `100-Stars-Co/bluedragon-eye-website`
- **Jira key format:** `BEP-XXXX`
- **Validate command:** `npm run ts-check && npm run lint:fix && npm test`
- **Scope:** `git diff develop...HEAD` — changed files only

## Gotchas

- This CLAUDE.md is **tracked in git** — changes here are shared with the team
- **Pages Router project** — App Router patterns (RSC, Server Components, `React.cache()`) do NOT apply
- Reviewer comments must be in Thai mixed with English technical terms (casual Slack/PR tone)
- Submit all inline comments + decision in ONE `gh api` call — not one-by-one
