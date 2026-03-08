# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A collection of Claude Code skills (custom slash commands). Each skill is a self-contained prompt workflow installed into Claude Code via the skills system.

## Docs Index

Prefer reading source before editing — key references:

| Reference | Contents |
| --- | --- |
| [`references/skills-best-practices.md`](references/skills-best-practices.md) | Full frontmatter spec, description rules, substitutions (`$0`/`$1`/`!`), context budget |
| `skills/<name>/references/checklist.md` | Per-skill review criteria with severity markers (review-pr skills) |
| `skills/<name>/references/examples.md` | Per-skill ✅/❌ code examples for all 12 rules (review-pr skills) |

## Skill Structure

Each skill lives at `skills/<skill-name>/` with this layout:

```text
skills/<name>/
  SKILL.md          # Agent entry point — required; loaded when skill is invoked
  CLAUDE.md         # Contributor context — read by Claude when editing this repo
  references/       # Supporting docs loaded into agent context from SKILL.md
  assets/           # Static assets (templates, boilerplate)
  scripts/          # Helper scripts referenced from SKILL.md or CLAUDE.md
```

### SKILL.md Frontmatter

```yaml
---
name: skill-name                    # Slash command trigger: /skill-name
description: "What it does. Use when: X, Y, Z."  # Max 1024 chars — cover what + when + triggers
argument-hint: "[arg1] [arg2?]"    # Optional: shown in /autocomplete
compatibility: "Requires gh CLI"   # Optional: prerequisites (CLIs, env, repo context)
disable-model-invocation: true      # Optional: removes description from context; manual-only
allowed-tools: Read, Grep, Glob    # Optional: auto-approve these tools when skill is active
model: sonnet                       # Optional: override model (sonnet/opus/haiku/inherit)
context: fork                       # Optional: run in isolated subagent context
agent: Explore                      # Optional: subagent type when context: fork (default: general-purpose)
hooks: {}                           # Optional: lifecycle hooks scoped to this skill
---
```

**Substitutions:** `$ARGUMENTS` (all args), `$0`/`$1` (positional), `${CLAUDE_SKILL_DIR}` (skill directory path), `` !`command` `` (shell injection)

Full field reference: [references/skills-best-practices.md](references/skills-best-practices.md)

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

## Agents

Custom subagents live at `agents/<name>.md` with YAML frontmatter. Symlinked to `~/.claude/agents/` via `link-skill.sh`.

| Field | Purpose |
| --- | --- |
| `name` | Unique identifier (lowercase + hyphens) |
| `description` | When Claude should delegate to this agent (include "proactively" to auto-trigger) |
| `tools` | Allowlist: `Read, Grep, Glob, Bash` etc. Inherits all if omitted |
| `disallowedTools` | Denylist: removed from inherited/specified tools |
| `model` | `sonnet`, `opus`, `haiku`, or `inherit` (default) |
| `skills` | Skills to preload into agent context at startup |
| `memory` | `user`, `project`, or `local` — persistent cross-session memory |
| `hooks` | Lifecycle hooks scoped to this agent |
| `permissionMode` | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | Max agentic turns before stop |
| `background` | `true` to always run as background task |
| `isolation` | `worktree` for isolated git worktree copy |

Current agents: `tathep-reviewer` (code reviewer with persistent memory, preloads `next-best-practices` + `clean-code` skills)

## Hooks

Lifecycle hooks automate actions at specific points. Configured in `.claude/settings.json` or `~/.claude/settings.json`.

| Event | Matcher | Common use |
| --- | --- | --- |
| `SessionStart` | `compact` | Re-inject context after compaction |
| `PostToolUse` | `Edit\|Write` | Auto-format/lint after file edits |
| `PreToolUse` | `Bash` | Validate commands before execution |
| `Notification` | `*` | Desktop alerts when Claude needs input |
| `Stop` | — | Verify tasks complete before stopping |
| `SubagentStart/Stop` | agent name | Setup/cleanup for specific agents |

Hook types: `command` (shell), `prompt` (single LLM call), `agent` (multi-turn with tools), `http` (POST to URL)

Hook scripts live at `hooks/` and are symlinked to `~/.claude/hooks/` via `link-skill.sh`.

## Output Styles

Custom output styles live at `output-styles/<name>.md` with frontmatter (`name`, `description`, `keep-coding-instructions`). Symlinked to `~/.claude/output-styles/` via `link-skill.sh`.

Output styles replace the default system prompt's coding instructions unless `keep-coding-instructions: true`. Use for consistent formatting/tone across sessions.

Current styles: `thai-tech-lead` (Thai language tech lead mode with architecture focus)

## Adding a New Skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter
2. Add `argument-hint` if the skill takes arguments; add `compatibility` for prerequisite tools
3. Add `references/` docs if the skill needs supporting material
4. Keep `description:` trigger-complete (what + when + keywords) — max 1024 chars
5. Use `disable-model-invocation: true` for side-effect skills (deploy, PR review)
6. Create `skills/<name>/CLAUDE.md` with contributor context: architecture overview, validate commands, gotchas specific to this skill
7. Install symlink: `bash scripts/link-skill.sh <name>` (or `--list` to check, no args to link all)
8. Lint: `npx markdownlint-cli2 "skills/<name>/**/*.md"` — pre-commit hook auto-fixes staged `.md` files

## Repo Commands

| Task | Command |
| --- | --- |
| Lint all markdown | `npx markdownlint-cli2 "skills/**/*.md"` |
| Link one skill | `bash scripts/link-skill.sh <name>` |
| Link everything | `bash scripts/link-skill.sh` (skills, agents, hooks, output-styles) |
| Check all links | `bash scripts/link-skill.sh --list` |

## Gotchas

- `context: fork` in SKILL.md frontmatter — officially supported; use with `agent` field to pick execution environment (`Explore`, `Plan`, `general-purpose`, or custom agent name)
- Pre-commit hook auto-fixes staged `.md` files — runs `scripts/fix-tables.py` + `markdownlint-cli2 --fix`; no manual fix needed before commit
- `disable-model-invocation: true` removes description from context entirely (skill never auto-triggers); `user-invocable: false` hides from menu but keeps context — different effects
- Run `/optimize-context` when this file feels stale
