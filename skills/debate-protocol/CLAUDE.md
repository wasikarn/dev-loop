# debate-protocol skill

Library skill defining adversarial debate rules for Devflow review workflows — loaded by `review` and `build` Phase 6, never invoked directly.

## Skill Architecture

- `SKILL.md` only — this file IS the reference document
- `user-invocable: false`, `disable-model-invocation: true` — never auto-triggers or appears in menu
- Loaded via markdown link from `skills/review/SKILL.md` and `skills/build/references/phase-6-review.md`
- Defines: pre-debate triage table, round-robin assignment, round limits, consensus rules, lead decision template, Hard Rule exception, new finding escalation, anti-patterns

## Validate After Changes

```bash
npx markdownlint-cli2 "skills/debate-protocol/SKILL.md"

# Verify consumers still reference this skill
grep -r "debate-protocol" skills/review/ skills/build/
```

## Gotchas

- Changes here affect BOTH `review` and `build` Phase 6 simultaneously — coordinate changes across both consumers.
- Pre-debate triage table thresholds (Auto-pass: Hard Rule + ≥90 confidence; Auto-drop: Info + <80) are calibrated for accuracy/cost balance — don't adjust without re-validating against S2-MAD benchmark note in the file.
- "Hard Rules cannot be dropped via debate" is a non-negotiable invariant. A challenger can only prove the code doesn't match the rule pattern — they cannot argue the rule away.
- Round limits (max 2) are hard enforced by the lead — do not relax them; runaway debate is the primary cost-explosion risk in adversarial review.
- The round-robin assignment table (each reviewer challenges a different teammate's findings) must stay consistent with the three-reviewer roster in `review/SKILL.md` (Correctness & Security, Architecture & Performance, DX & Testing).
- New finding escalation gate (max 2 per teammate per debate) prevents scope explosion — keep the cap explicit.
