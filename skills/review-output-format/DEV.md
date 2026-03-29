# review-output-format skill

Library skill defining the shared PR review output format templates — header, phase sections, findings table, action sections, and final verdict — for `review` and `build` Phase 6.

## Skill Architecture

- `SKILL.md` only — this file IS the reference document
- `user-invocable: false`, `disable-model-invocation: true` — never auto-triggers
- Loaded by `skills/review/SKILL.md` and `skills/build/references/phase-6-review.md`
- Output language is Thai mixed with English technical terms — templates in SKILL.md use English for readability only
- Phase numbers in this file (Phase 1–4) are OUTPUT SECTIONS, not workflow phases

## Validate After Changes

```bash
npx markdownlint-cli2 "skills/review-output-format/SKILL.md"
```

## Gotchas

- Output must be written in Thai mixed with English technical terms — if adding new template sections, write example text in Thai, not English prose.
- Changes affect both `review` and `build` Phase 6 simultaneously.
- Verdict rules differ by mode — this is load-bearing: **Author mode** approves if all 🔴 are fixed + validate passes; **Reviewer mode** approves if no 🔴 remain (no validate requirement). Do not unify these.
- AC counts in Final Verdict are conditional on a Jira key being present — if the Jira section is absent, omit `AC: N/N` from the verdict line entirely.
- Phase numbering note in the file header ("Phase 1–4 are output sections, not workflow phases") must stay accurate — `review` workflow has phases 0–6, and the mismatch is a known source of confusion.
- The Reviewer Progress table (Part 1 of Phase 3) updates incrementally as each reviewer completes — this streaming pattern must be preserved when changing the output structure.
