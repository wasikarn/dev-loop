# api-review-pr skill

PR review skill for tathep-platform-api (AdonisJS 5.9 + Effect-TS + Clean Architecture + Japa tests).
SKILL.md is the agent entry point; references/ provides supporting detail.

## Docs Index

Prefer reading before editing — key references:

| Reference | When to use |
| --- | --- |
| `references/checklist.md` | Adding/updating review criteria for a rule |
| `references/examples.md` | Adding ✅/❌ code examples for a rule |

## Skill Architecture

- `SKILL.md` — agent entry point; defines phase workflow, Hard Rules, and 7-agent dispatch
- `references/checklist.md` — 12-rule criteria with 🔴/🟡/🔵 severity markers; loaded by Phase 3 agents
- `references/examples.md` — ✅/❌ code examples per rule; evidence agents use when flagging issues

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/api-review-pr/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/api-review-pr

# Invoke skill (run in tathep-platform-api repo):
# /api-review-pr <pr-number> [jira-key?] [Author|Reviewer]

# Project validate (run in tathep-platform-api repo):
# npm run validate:all
```

## Skill System

SKILL.md frontmatter controls how Claude invokes this skill:

- `description:` — Claude matches user intent; prefer trigger-complete descriptions — wrong description = skill never auto-triggers
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
- Phase 3 agents are READ-ONLY — code edits only happen in Phase 4 (Author mode)
- Hard Rules in SKILL.md bypass confidence filter — always reported unconditionally; keep criteria precise
