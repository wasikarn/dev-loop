# Debate Protocol

Rules for the adversarial debate phase in team-review-pr. Teammates challenge each other's findings to reduce false positives and produce higher-confidence results.

## Debate Structure

### Round-Robin Assignment

After all teammates complete independent review (Phase 2), the lead creates debate tasks:

| Reviewer | Reviews findings from |
| --- | --- |
| Correctness & Security | Architecture & Performance |
| Architecture & Performance | DX & Testing |
| DX & Testing | Correctness & Security |

Each reviewer examines the other's findings and responds with one of:

- **Agree** — "+1, confirmed. [optional: additional evidence]"
- **Challenge** — "False positive because [evidence]. The code at `file:line` shows [reason]."
- **Escalate** — "This is actually more severe than reported because [evidence]."

### Round Limits

- **Max 2 rounds** of debate. Lead enforces.
- Round 1: full review of all findings from assigned teammate.
- Round 2 (if needed): targeted — only unresolved disagreements from Round 1.
- If still unresolved after Round 2 → lead decides based on evidence.

### Response Requirements

Every challenge MUST include:

1. **Evidence** — file:line reference to actual code
2. **Reasoning** — why the finding is wrong or why severity should change
3. **Verdict** — "drop", "keep", or "change severity to X"

Challenges without evidence are ignored.

## Consensus Rules

| Outcome | Action |
| --- | --- |
| 3/3 agree | Keep finding at reported severity |
| 2/3 agree, 1 challenges | Keep finding; note the challenge in debate summary |
| 1/3 raised, 2 challenge | Drop finding |
| Split (no majority) | Lead decides — reads code, picks based on evidence quality |

## Hard Rule Exception

Hard Rule violations (defined in project-specific SKILL.md) **cannot be dropped** via debate. They can only be:

- **Confirmed** (agree)
- **Reclassified** (if the pattern doesn't actually match the Hard Rule definition)

A teammate challenging a Hard Rule finding must prove the code does NOT match the pattern — e.g., "this `as any` is inside a type guard, not a bare cast."

## Debate Summary Output

After convergence, the lead outputs:

```markdown
### Phase 3: Debate Summary

| # | Finding | Raised By | Challenged By | Outcome |
| --- | --- | --- | --- | --- |
| 1 | `as any` at `foo.ts:42` | Correctness | — | Consensus (3/3) |
| 2 | Missing null check `bar.ts:88` | Correctness | Architecture ("guarded by caller at line 45") | Dropped |
| 3 | N+1 in loop `baz.ts:15` | Architecture | — | Consensus (3/3) |
| 4 | No unit test for edge case | DX | Correctness ("covered by e2e at test/foo.spec.ts:22") | Lead decided: keep as nitpick |
```

## Anti-Patterns

- **Rubber-stamping** — agreeing with everything without reading code. Each agreement should reference specific code if the finding is non-trivial.
- **Scope creep** — raising new findings during debate. Debate is for validating existing findings only. New issues go back to the lead.
- **Authority fallback** — "I'm the security reviewer so I'm right." Evidence wins, not role.
- **Infinite debate** — max 2 rounds. After that, lead decides. No exceptions.
