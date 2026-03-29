# Shared Reviewer Rules

Common rules and output format shared across all reviewer roles. Referenced from each reviewer template to avoid duplication.

## Confidence Thresholds (by role)

| Reviewer role | Threshold | Notes |
| --- | --- | --- |
| Correctness & Security | 75 | Security findings: 70 (false positives acceptable) |
| Architecture & Performance | 80 | |
| DX & Testing | 85 | |

Hard Rule violations bypass all thresholds — always report regardless of confidence.

> **review divergence:** `review/references/teammate-prompts.md` uses a flat threshold of 80 for all teammates (not per-role). This is intentional — review runs adversarial debate to filter noise post-review, so a uniform threshold is sufficient. build has no debate phase, so per-role calibration matters more.

## Structured Evidence Block (Required Before Each Finding)

Before emitting any finding, complete this block — invisible reasoning cannot be checked:

```text
Citation: [file:line — specific location of the problem]
Pre-existing: [yes — existed before this diff at commit HASH | no — introduced in this diff]
Assumption: [one sentence: what I am assuming about context that could be wrong]
Confidence: [C:NN]
```

Emit the finding **only if:**

- **Citation:** filled with a specific file:line (not "somewhere in the file")
- **Pre-existing:** is "no" (pre-existing issues belong in a tech-debt report, not here)
- **Assumption:** is low-risk or verifiable

If `Pre-existing` is unclear, check `git log -p [file]` before claiming diff-introduced.

## Criticality Scaling (1–10)

Every finding includes a criticality score:

| Score | Meaning |
| ------- | --------- |
| 9–10 | Data loss / security vulnerability / breaking API contract |
| 7–8 | Correctness bug — wrong behavior, missing error handling |
| 5–6 | Performance issue / maintainability debt |
| 3–4 | Style inconsistency / minor improvement |
| 1–2 | Optional suggestion |

## Rules (all reviewers)

1. Complete the Structured Evidence Block before each finding
2. Read actual code before flagging — no speculation without file:line evidence
3. Score confidence 0-100 for each finding
4. Only report findings above your role's domain threshold (see Confidence Thresholds table)
5. Hard Rule violations bypass confidence filter — always report
6. Review ONLY changed files — not pre-existing issues
7. If confidence is below threshold due to missing context, send a CONTEXT-REQUEST to team lead before submitting: `CONTEXT-REQUEST: Need [specific file/info] to assess [finding] — should I proceed without it or wait?`

## Risks Found Block (Required Before Verdict)

Before emitting GO/NO-GO or review summary, list ALL concerns — even minor ones:

```markdown
## Risks Found
<!-- List ALL concerns before giving verdict. An empty section is valid IF you justify it.
     Format: - [concern] (file:line evidence)
     If no concerns: "None identified — [brief reason why]" -->
- [concern 1] (evidence)
- [concern 2] (evidence)

## Verdict
GO / NO-GO
Reason: [based on Risks Found above — not independent opinion]
```

Rationale: Listing risks before verdict forces self-consistency. A reviewer that lists 3 risks
and then says GO must resolve that contradiction. "None identified" requires explicit justification.

## Generic Hard Rules (Fallback)

Use these when `.claude/skills/review-rules/hard-rules.md` does not exist in the target project.

1. No secrets or credentials in source code — env vars only
2. No raw SQL string concatenation with user input — use parameterized queries
3. No empty catch blocks — errors must be logged or re-thrown
4. No `as any` without justification comment — use proper typing
5. No missing null checks on external data — validate at system boundaries

## Boundary Contract

If you find an issue outside your primary domain:

- Mark as: `[CROSS-DOMAIN: {domain}]` in the finding
- Set severity to: Warning (never Critical — defer escalation to consolidator)
- Do not drop it — cross-domain findings are valid, just lower confidence
- Consolidator may escalate after seeing full findings set

## Observation Masking

After reading a file and extracting findings:

- Retain: file path, line refs, finding text, reasoning chain
- Discard: full file content from working memory
- Do not re-read a file you have already processed unless Lead explicitly requests it

## Output Format

| # | Sev | File | Line | Confidence | Issue | Fix |
| --- | --- | --- | --- | --- | --- | --- |

Sev values: 🔴 Critical | 🟡 Warning | 🔵 Info

Send findings to team lead when done.
