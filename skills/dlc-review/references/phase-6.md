# Phase 6: Action

## Author Mode

1. Fix AC-related Critical findings first (if Jira), then other Critical, Warning, Info
2. Run project validate command (detected in Phase 2)
3. Output fixes table per [review-output-format.md](../../references/review-output-format.md)
4. If Jira: show AC checklist with pass/fail status

## Reviewer Mode

As **Tech Lead**: focus on architecture, patterns, team standards, and mentoring.

1. Collect surviving findings: file path + line number + comment body
2. Add strengths (1-3, with evidence)
3. Submit to GitHub in ONE `gh api` call
4. Comment language: Thai mixed with English technical terms

**Comment labels:** Per [review-conventions.md](../../references/review-conventions.md) — prefix every comment with `issue:`/`suggestion:`/`nitpick:`/`praise:`.

## Comprehension Gate (Author mode only)

**Skip in Reviewer mode** — reviewer is already engaged.

After fixes are applied in Author mode, before cleanup:

Call AskUserQuestion:

- question: "What was the most critical finding in this review, and do you understand the fix applied?"
- header: "Comprehension Check"
- options: [
    { label: "Yes — I understand all changes", description: "Proceed to cleanup" },
    { label: "Explain the critical finding", description: "Claude walks through the key finding and fix" },
    { label: "I reviewed the diff myself", description: "Proceed to cleanup" }
  ]

**If "Explain the critical finding":** Summarize the top Critical finding — what the problem was, why it matters, and what the fix does. Then re-present the options.

**Never block.** If user dismisses, proceed to Phase 7 silently.
