# optimize-context skill

Audits, scores, and optimizes CLAUDE.md files for maximum agent effectiveness.
SKILL.md is the agent entry point; references/ provides supporting detail.

## Docs Index

Prefer reading before editing — key references:

| Reference | When to use |
| --- | --- |
| `references/quality-criteria.md` | Updating scoring rubric or grade thresholds |
| `references/compression-guide.md` | Updating compression techniques |
| `references/templates.md` | Updating CLAUDE.md templates by project type |
| `scripts/pre-scan.sh` | Updating framework detection or file discovery logic |

## Skill Architecture

- `SKILL.md` — 5-phase workflow: Discovery → Score → Audit → Update → Verify
- `references/quality-criteria.md` — 100-point rubric (8 criteria, min thresholds for critical ones)
- `scripts/pre-scan.sh` — detects framework/scripts/structure in ~30ms; always run first in Phase 1
- Audit report written to `.claude/optimize-context-report.md` — survives context compaction

## Validate After Changes

```bash
# Lint all markdown in this skill
npx markdownlint-cli2 "skills/optimize-context/**/*.md"

# Verify skill symlink exists
ls -la ~/.claude/skills/optimize-context

# Test pre-scan script
bash skills/optimize-context/scripts/pre-scan.sh . | jq -c '.'

# Invoke skill:
# /optimize-context            → full 5-phase audit + edits
# /optimize-context --dry-run  → phases 1-3 only (report, no edits)
```

## Skill System

SKILL.md frontmatter controls how Claude invokes this skill:

- `description:` — Claude matches user intent; prefer trigger-complete descriptions — wrong description = skill never auto-triggers
- `name:` — the slash command name (`/optimize-context`)

## Gotchas

- This CLAUDE.md is **tracked in git** — changes here are shared with the team
- `pre-scan.sh` targets bash 3.x (macOS default) — no `declare -A`, no `mapfile`
- `stat -f%z` is macOS/BSD syntax for file size — GNU Linux uses `stat -c%s`
- Size measurement excludes auto-generated sections (`<claude-mem-context>`, plugin blocks) — score human-authored content only
- 100/100 is achievable for vertical/hybrid projects; non-framework projects may score lower on retrieval readiness if no docs index applies
