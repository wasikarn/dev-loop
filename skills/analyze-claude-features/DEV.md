# analyze-claude-features skill

Audits a project against all official Claude Code features and produces two scores: Analysis Quality and Project Coverage.

## Skill Architecture

- `SKILL.md` — everything: 9-step workflow, scoring rubric, 2 quality gates, decision matrix (~342 lines)
- No `references/` directory — all content is self-contained by design
- Fetches 12 live documentation sources via WebFetch at runtime (code.claude.com) + reads 1 local file (`docs/references/skill-creation-guide.md`)
- Two quality gates: Context Completeness (Step 3→4) and Opportunity Validity (Step 6→7)

## Validate After Changes

```bash
npx markdownlint-cli2 "skills/analyze-claude-features/SKILL.md"
```

## Gotchas

- Uses WebFetch to pull 12 docs at runtime — if URLs in the "Sources" section break, the gate at Step 3 will fail (≥12 of 13 required). Update the URL list in SKILL.md when Claude Code moves docs.
- `skill-creation-guide.md` is loaded locally via `${CLAUDE_SKILL_DIR}/../../docs/references/skill-creation-guide.md` (not a URL) — no network dependency for that entry.
- No `references/` dir is intentional — keeping everything in one file prevents partial-load issues during the multi-fetch workflow.
- `effort: medium` is required — Analysis Quality quality gate demands multiple web fetches before proceeding; setting `effort: low` would degrade output quality silently.
- The two scoring systems (Analysis Quality + Project Coverage) are independent — Project Coverage can be 100/100 even if Analysis Quality is B-grade.
- Decision matrix in Step 5 is load-bearing for flagging misplaced configuration (e.g., workflow logic in CLAUDE.md instead of a skill) — don't simplify it.
