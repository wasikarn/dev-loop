# tathep-web-review-pr skill

PR review skill for tathep-website (Next.js 14 Pages Router + Chakra UI + React Query v3).
SKILL.md is the agent entry point; references/ provides supporting detail.

## Docs Index

Prefer reading before editing — key references:

| Reference | When to use |
| --- | --- |
| `references/checklist.md` | Adding/updating review criteria for a rule |
| `references/examples.md` | Adding ✅/❌ code examples for a rule |
| `../../references/review-workflow.md` | Updating shared review phases or agent dispatch logic |

## Skill Architecture

- `SKILL.md` — agent entry point; defines project-specific Hard Rules, config, and constraints; references shared workflow
- `../../references/review-workflow.md` — shared phase orchestration (Phase 0-4, agent dispatch, consolidation, GitHub submission)
- `references/checklist.md` — 12-rule criteria with 🔴/🟡/🔵 severity markers; loaded by Phase 3 agents
- `references/examples.md` — ✅/❌ code examples per rule; evidence agents use when flagging issues

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/tathep-web-review-pr/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/tathep-web-review-pr

# Invoke skill (run in tathep-website repo):
# /tathep-web-review-pr <pr-number> [jira-key?] [Author|Reviewer]

# Project validate (run in tathep-website repo):
# npm run ts-check && npm run lint:fix && npm test
```

## Project Context

- **GitHub repo:** `100-Stars-Co/bluedragon-eye-website`
- **Jira key format:** `BEP-XXXX`
- **Validate command:** `npm run ts-check && npm run lint:fix && npm test`
- **Scope:** `git diff develop...HEAD` — changed files only

## Gotchas

- **Phase 0 (PR Scope Assessment)** runs before ticket fetch — classifies PR size, adapts review behavior for large PRs
- **Phase 3.5 (Consolidation)** is explicit sub-phase after CHECKPOINT — dedup, verify, remove false positives
- **Shared conventions** in `references/review-conventions.md` — comment labels, dedup protocol, strengths guidelines, PR size thresholds
- This CLAUDE.md is **tracked in git** — changes here are shared with the team
- **Pages Router project** — App Router patterns (RSC, Server Components, `React.cache()`) do NOT apply
- Reviewer comments must be in Thai mixed with English technical terms (casual Slack/PR tone)
- Submit all inline comments + decision in ONE `gh api` call — not one-by-one
- Phase 3 agents are READ-ONLY — code edits only happen in Phase 4 (Author mode)
- Hard Rules in SKILL.md bypass confidence filter — always reported unconditionally; keep criteria precise
