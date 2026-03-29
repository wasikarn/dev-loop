# review-examples skill

Library skill providing canonical TypeScript ❌/✅/⚠️ code examples for all 12 review rules — loaded by `code-reviewer`, `build`, and `review` agents to calibrate finding accuracy.

## Docs Index

| Reference | When to use |
| --- | --- |
| `references/examples.md` | Full 12-rule example set — edit here when updating any rule's examples |

## Skill Architecture

- `SKILL.md` — compact pointer with one inline example; loads `references/examples.md` for full content
- `references/examples.md` — complete 12-rule TypeScript examples with all three tiers per rule
- `user-invocable: false`, `disable-model-invocation: true` — loaded by consumer agents, never invoked directly
- Consumers: `code-reviewer` agent, `build` Phase 6, `review` Phase 2

## Validate After Changes

```bash
npx markdownlint-cli2 "skills/review-examples/**/*.md"
```

## Gotchas

- Three-tier structure (❌ Bad / ✅ Good / ⚠️ Don't Flag) is intentional — the "Don't Flag" tier is what prevents false positives. When updating a rule, all three tiers must be updated together.
- Examples are TypeScript but the rules apply to all stacks — keep examples idiomatic TS (real types, real APIs), not pseudo-code. Reviewers calibrate against concrete patterns.
- Rule numbering in `examples.md` must stay in sync with rule numbering in `review-rules/SKILL.md` — mismatched numbers cause reviewers to cite wrong rule IDs in findings.
- The SKILL.md file contains one inline example (Rule #1) followed by a link to `references/examples.md` — this split is intentional for fast context loading. Do not move all examples into SKILL.md.
- Adding a new rule requires: a new section in `references/examples.md`, updating the rule count reference in consumer skills, and adding a test case to `skills/review-rules/references/checklist.md` if applicable.
