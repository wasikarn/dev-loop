# deep-research-workflow skill

Structured 3-phase development workflow (Research → Plan → Implement) for complex features.
SKILL.md is the agent entry point; references/ provides artifact templates.

## Reference File Map

| File |
| ------ |
| `references/research-template.md` |
| `references/plan-template.md` |

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/deep-research-workflow/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/deep-research-workflow
```

## Skill System

SKILL.md frontmatter controls how Claude invokes this skill:

- `description:` — Claude matches user intent against this field; **must be trigger-complete**
- `name:` — the slash command name (`/deep-research-workflow`)
- `argument-hint:` — shown in autocomplete as `[feature-description]`

## Gotchas

- This CLAUDE.md is **tracked in git** — changes here are shared with the team
- Artifacts (`research.md`, `plan.md`) are written at the **project root** of the target project, not inside this skills repo
- The skill uses `context: fork` semantics conceptually but the frontmatter attribute isn't supported — the skill is heavy and long-running; expect it to consume significant context
- If context is compacted mid-workflow, the agent should re-read `research.md` Summary + `plan.md` Annotations to resume
