# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A collection of Claude Code skills (custom slash commands). Each skill is a self-contained prompt workflow installed into Claude Code via the skills system.

> **Note:** `.gitignore` excludes `**/CLAUDE.md` (to suppress claude-mem auto-generated files). This root CLAUDE.md is therefore not tracked by git — it's for local session context only.

## Skill Structure

Each skill lives at `skills/<skill-name>/` with this layout:

```
skills/<name>/
  SKILL.md          # Main entry point — required
  references/       # Supporting docs referenced from SKILL.md
  assets/           # Static assets
  scripts/          # Helper scripts
```

### SKILL.md Frontmatter

```yaml
---
name: skill-name                    # Slash command trigger: /skill-name
description: |                      # When to invoke (used by Claude to match intent)
  ...
argument-hint: "[arg1] [arg2?]"    # Optional: shown in autocomplete
context: fork                       # Optional: isolate skill in fork context
disable-model-invocation: true      # Optional: prevent nested model calls
---
```

## Skills in This Repo

| Skill | Purpose |
|-------|---------|
| `optimize-context` | Audit + score + optimize CLAUDE.md files (5-phase workflow) |
| `deep-research-workflow` | Research → Plan → Implement for complex features |
| `api-review-pr` | PR review for tathep-platform-api (AdonisJS 5.9 + Effect-TS + Clean Arch) |
| `web-review-pr` | PR review for tathep-website (Next.js 14 Pages Router + Chakra UI) |
| `admin-review-pr` | PR review for tathep-admin (Next.js 14 Pages Router + Tailwind + Vitest) |

## PR Review Skills Pattern

All three `*-review-pr` skills share the same structure:

- **Args:** `[pr-number] [jira-key?] [Author|Reviewer]`
- **Scope:** `git diff develop...HEAD`
- **Phase 1-2:** Jira ticket fetch + AC verification (skipped if no Jira key)
- **Phase 3:** 7 agents dispatched in foreground parallel (READ-ONLY checkpoint before fixes)
- **Phase 4:** Author mode = fix code + `validate`; Reviewer mode = submit GitHub review in Thai
- **Agents used:** `pr-review-toolkit:{code-reviewer,comment-analyzer,pr-test-analyzer,silent-failure-hunter,type-design-analyzer,code-simplifier}` + `feature-dev:code-reviewer`
- **Reviewer language:** Thai mixed with English technical terms (casual Slack/PR tone)
- **GitHub repos:** `100-Stars-Co/bd-eye-platform-api` (api), `100-Stars-Co/bluedragon-eye-website` (web), `100-Stars-Co/bluedragon-eye-admin` (admin)

Validate commands per project:

- api: `npm run validate:all`
- web: `npm run ts-check && npm run lint:fix && npm test`
- admin: `npm run ts-check && npm run lint@fix && npm run test` (`lint@fix` uses `@`, not `:`)

## Adding a New Skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter
2. Add `references/` docs if the skill needs supporting material
3. Keep `description:` concise but trigger-complete — Claude uses it to decide when to invoke the skill
4. Use `context: fork` + `disable-model-invocation: true` for heavy agent-dispatching skills
