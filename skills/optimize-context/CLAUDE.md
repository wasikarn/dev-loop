# optimize-context skill

Audits, scores, and optimizes CLAUDE.md files for maximum agent effectiveness.
SKILL.md is the agent entry point; references/ provides supporting detail.

## Reference File Map

| File | Purpose |
|------|---------|
| `references/quality-criteria.md` | 100-pt rubric with per-score breakdown |
| `references/compression-guide.md` | 9 compression techniques + passive context patterns |
| `references/templates.md` | CLAUDE.md templates by project type |
| `scripts/pre-scan.sh` | Phase 1 metadata collector — run first to save ~2-4k tokens |

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/optimize-context/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/optimize-context

# Test pre-scan script
bash skills/optimize-context/scripts/pre-scan.sh . | jq -c '.'
```

## Skill System

SKILL.md frontmatter controls how Claude invokes this skill:

- `description:` — Claude matches user intent against this field; **must be trigger-complete**
- `name:` — the slash command name (`/optimize-context`)

## Gotchas

- This CLAUDE.md is **tracked in git** — changes here are shared with the team
- `pre-scan.sh` targets bash 3.x (macOS default) — no `declare -A`, no `mapfile`
- `stat -f%z` is macOS/BSD syntax for file size — GNU Linux uses `stat -c%s`
