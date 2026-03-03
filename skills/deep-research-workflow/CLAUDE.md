# deep-research-workflow skill

Structured 3-phase development workflow (Research → Plan → Implement) for complex features.
SKILL.md is the agent entry point; references/ provides artifact templates.

## Docs Index

Prefer reading before editing — key references:

| Reference | When to use |
| --- | --- |
| `references/research-template.md` | Updating Phase 1 research output format |
| `references/plan-template.md` | Updating Phase 2 plan output format |

## Skill Architecture

- `SKILL.md` — defines 3-phase workflow: Research → Plan → Implement
- `references/research-template.md` — Phase 1 artifact format (`research.md`)
- `references/plan-template.md` — Phase 2 artifact format (`plan.md`)
- Artifacts written to **target project root** (not this skills repo)

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/deep-research-workflow/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/deep-research-workflow

# Invoke skill:
# /deep-research-workflow <feature-description>

# Resume after context compaction:
# Re-read research.md Summary + plan.md Annotations to restore phase context
```

## Skill System

SKILL.md frontmatter controls how Claude invokes this skill:

- `description:` — Claude matches user intent; prefer trigger-complete descriptions — wrong description = skill never auto-triggers
- `name:` — the slash command name (`/deep-research-workflow`)
- `argument-hint:` — shown in autocomplete as `[feature-description]`

## Gotchas

- This CLAUDE.md is **tracked in git** — changes here are shared with the team
- Artifacts (`research.md`, `plan.md`) are written at the **project root** of the target project, not inside this skills repo
- The skill uses `context: fork` semantics conceptually but the frontmatter attribute isn't supported — the skill is heavy and long-running; expect it to consume significant context
- If context is compacted mid-workflow, the agent should re-read `research.md` Summary + `plan.md` Annotations to resume
