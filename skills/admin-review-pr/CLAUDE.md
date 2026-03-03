# admin-review-pr skill

PR review skill for tathep-admin (Next.js 14 Pages Router + Tailwind + Headless UI + Vitest).
SKILL.md is the agent entry point; references/ provides supporting detail.

## Reference File Map

| File | Purpose |
|------|---------|
| `references/checklist.md` | 12-point review criteria with severity levels |
| `references/examples.md` | Code examples for project-specific rules |

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/admin-review-pr/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/admin-review-pr
```

## Skill System

SKILL.md frontmatter controls how Claude invokes this skill:

- `description:` — Claude matches user intent against this field; **must be trigger-complete**
- `name:` — the slash command name (`/admin-review-pr`)
- `context: fork` + `disable-model-invocation: true` — isolates heavy 7-agent dispatch

## Project Context

- **GitHub repo:** `100-Stars-Co/bluedragon-eye-admin`
- **Jira key format:** `BEP-XXXX`
- **Validate command:** `npm run ts-check && npm run lint@fix && npm run test`
- **Scope:** `git diff develop...HEAD` — changed files only

## Gotchas

- This CLAUDE.md is **tracked in git** — changes here are shared with the team
- **`lint@fix` uses `@` not `:`** — `npm run lint@fix` (NOT `lint:fix`) — easy to confuse with web skill
- **Pages Router project** — App Router patterns (RSC, Server Components, `React.cache()`) do NOT apply
- Reviewer comments must be in Thai mixed with English technical terms (casual Slack/PR tone)
- Submit all inline comments + decision in ONE `gh api` call — not one-by-one
