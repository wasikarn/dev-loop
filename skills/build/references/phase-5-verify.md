# Phase 5: Verify

Runs after all Phase 4 workers complete, before Phase 6 review.
Lead agent runs this phase directly — no new subagent needed.

Update `phase: verify` in `{artifacts_dir}/anvil-context.md`.

## Mode Behavior

Per [workflow-modes.md](workflow-modes.md):

| Mode | Phase 5 behavior |
| ------ | ------------------- |
| Micro | Lightweight: verify the 1 truth passes (run test / check output). No loop. On fail → escalate immediately. |
| Quick | Full verification. 1 re-entry loop allowed. On STILL FAILING → escalate. |
| Full | Full verification. 1 re-entry loop allowed. On STILL FAILING → escalate with 3 options. |

Micro never loops back to Phase 4 — surface failure immediately.

---

## Verification Process

For each truth in `must_haves.truths`:

1. State: `"Verifying Truth N: [description]"`
2. Verify using (preference order): run tests → call endpoint → check output → read code
   Note: "read code" is weakest — use only if no test exists. Always prefer executable verification.
3. Record: ✅ PASS with evidence | ❌ FAIL with specific reason

**Test meaningfulness check** (when truth is verified via test run):
Read the test file. Does the test contain at least one behavioral assertion?

- ✅ MEANINGFUL: has `expect`/`assert` on output/response/side-effect
- ❌ SHALLOW: only checks mock call counts, or has zero assertions

A SHALLOW test that passes does NOT count as a truth PASS:
`"Test passes but only asserts mock calls / zero assertions — truth not verified"` → log as ❌ FAIL.

For each `key_link`:

1. Verify the connection exists in actual code (cite file:line)
2. Verify error case is handled at the link

---

## Verdict and Escalation

**ALL PASS:** Update checkboxes in plan.md truths → proceed to Phase 6.

**ANY FAIL — Quick/Full:**

- Targeted re-entry to Phase 4:
  - Identify which plan.md tasks cover the failed truths
  - Spawn workers for ONLY those tasks — do NOT re-spawn workers for passing truths
  - This counts as 1 loop (max 1 Phase 5-triggered re-entry)
  - **Also increments the shared `iteration_count`** (max 3 total) — a Phase 5 failure IS a Phase 4 failure

**ANY FAIL — Micro:**

- Escalate immediately: `"Truth N failed: [reason]. Fix now or continue to review?"`
- Wait for user decision — do NOT loop

**STILL FAILING after loop (Quick/Full):**

Escalate with options:

```text
"Truths [N, M] still failing after targeted re-entry.
(a) Continue to review with known gaps
(b) Redesign — go back to Phase 3 (plan revision)
(c) Abort"
```

→ REQUIRE explicit user choice. Do not auto-advance.

---

## Redesign Path (option b)

When user picks (b) — go back to Phase 3:

**Prerequisite:** `redesign_count` must be < 1. If `redesign_count ≥ 1`, offer only (a) or (c).

**Artifact handling:**

- `research.md` → regenerate (Phase 4 changed the code; research may be stale)
- `plan.md` → regenerate (truths may need revision)
- `verify-results.md` → preserve (contains failure evidence for re-planning)
- Code changes from failed attempt → lead decides: revert or keep as scaffolding

**Truth audit before re-planning:** Lead must confirm each failing truth is still the correct behavioral requirement. A truth that consistently fails verification may be incorrectly specified — not just wrong implementation. Truths may be revised but only with explicit reasoning.

**Counter updates:**

- Increment `redesign_count` in anvil-context.md
- Reset `iteration_count` for the new planning cycle
- Archive prior artifacts with date suffix: `plan-attempt-1.md`, `research-attempt-1.md`

---

## Output

Write `{artifacts_dir}/verify-results.md`:

```markdown
## Phase 5 Verification Results

### Truth 1: [description]
Status: ✅ PASS
Evidence: tests/auth.test.ts:42 — behavioral assertion confirmed

### Truth 2: [description]
Status: ❌ FAIL
Reason: POST /api/messages returns 500 when body is empty (expected 400)
Evidence: curl -X POST /api/messages → HTTP 500

### Key Links
- AuthMiddleware → UserService.findById: ✅ null guard at middleware.ts:67

### Verdict
ALL PASS | FAIL (N of M truths failing) | STILL FAILING
```

Also post summary to conversation and update progress tracker checkboxes.
