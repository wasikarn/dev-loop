# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A collection of Claude Code skills (custom slash commands). Each skill is a self-contained prompt workflow installed into Claude Code via the skills system.

## Skill Structure

Each skill lives at `skills/<skill-name>/` with this layout:

```text
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
description: "What it does. Use when: X, Y, Z."  # Max 1024 chars — cover what + when + triggers
argument-hint: "[arg1] [arg2?]"    # Optional: shown in /autocomplete
compatibility: "Requires gh CLI"   # Optional: prerequisites (CLIs, env, repo context)
disable-model-invocation: true      # Optional: removes description from context; manual-only
---
```

Full field reference with description rules, substitutions (`$0`/`$1`/`!`), and context budget:
[references/skills-best-practices.md](references/skills-best-practices.md)

## Skills in This Repo

| Skill |
| ------- |
| `optimize-context` |
| `deep-research-workflow` |
| `spec-kit` |
| `api-review-pr` |
| `web-review-pr` |
| `admin-review-pr` |

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
2. Add `argument-hint` if the skill takes arguments; add `compatibility` for prerequisite tools
3. Add `references/` docs if the skill needs supporting material
4. Keep `description:` trigger-complete (what + when + keywords) — max 1024 chars
5. Use `disable-model-invocation: true` for side-effect skills (deploy, PR review)
6. Install symlink: `bash scripts/link-skill.sh <name>` (or `--list` to check, no args to link all)
