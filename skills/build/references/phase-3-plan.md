# Phase 3: Plan (Lead Only)

## Step 1: Write Plan

Write `{artifacts_dir}/{date}-{task-slug}/plan.md` directly — do NOT use `EnterPlanMode` or `~/.claude/plans/`. Lead writes this file inline using the Write tool.

**Source material by mode:**

| Mode | Plan source |
| ------ | ------------ |
| Micro | Task description only |
| Quick | Task description + research.md WHAT/WHY |
| Full | Task description + research.md (ADDED/MODIFIED/REMOVED + clarifications) |
| Hotfix | Broken code path only — minimal scope |

## Plan Structure

All modes produce a plan.md with these sections:

```markdown
## must_haves

### Truths
- [ ] [observable behavior]
      verify: [run test X | call endpoint Y | check output Z]
      behavioral?: [yes — 1 sentence: what a user/caller observes, not what function runs]

<!-- verify: behavioral methods only. Prohibited: "read the code", "check the logic".
     Permitted: "run test", "call endpoint", "check output", "observe response".
     behavioral?: must confirm external observable behavior — not function calls / variables. -->

### Key Links ("where is this most likely to break?")
- [ComponentA] → [ComponentB] via [mechanism]: [why this is critical]

## Tasks
<!-- TDD ordering enforced: test task precedes impl task for same story -->
- [P] Test: write failing test for Truth 1     ← [P] = parallel-safe
- [P] Test: write failing test for Truth 2
- [ ] Impl: implement minimal feature
- [ ] Impl: make Truth 1 pass
- [ ] Impl: make Truth 2 pass
- [P] Verify: run full test suite

## Readiness Verdict
READY / NEEDS WORK / NOT READY
[Issues if not READY: specific items with file:line]
```

**Truth count by mode:** Micro=1, Quick=2–3, Full=3–5, Hotfix=1–2.

**Truth quality rules:**

- Observable from user/API perspective (not implementation detail)
- Verifiable: can be checked by running a test or calling an endpoint
- Behavioral: "would fail if behavior changes unexpectedly"

**Plan quality rules:**

1. Problem statement with rationale
2. Approach with file-by-line changes
3. Simplicity check — is this the simplest approach? Flag speculative features or abstractions not required by task. "Can a junior understand this in 5 minutes?" test.
4. Trade-offs
5. TDD task ordering — test task must precede impl task for each truth
6. Task granularity — each task must specify: exact file(s), what to change (specific), expected behavior after change, how to verify. Each task completable in one worker turn — split if needed.

Update `plan_file:` in `{artifacts_dir}/dev-loop-context.md` to `{artifacts_dir}/{date}-{task-slug}/plan.md`.

---

## Step 2: Plan-Challenger (Full Mode Only)

**Micro and Quick:** Skip plan-challenger entirely. Proceed to Step 3.

**Full mode only:** Immediately spawn `plan-challenger` agent with the plan file path + `{artifacts_dir}/research.md`. Do **not** wait — continue to Step 3 (readiness gate) while plan-challenger runs.

Plan-challenger uses **dual-lens** challenge (see [agents/plan-challenger.md](../../../../agents/plan-challenger.md)):

- **Minimal-lens:** "What can be removed and still satisfy ALL must_haves.truths?" — ≥2 findings required
- **Clean-lens:** "What should be refactored BEFORE implementing to avoid accruing debt?" — ≥1 finding required

---

## Step 3: Readiness Gate

**PhaseVerdict** per [workflow-modes.md](workflow-modes.md).

**Micro / Quick:** No gate. Proceed to Phase 4 automatically.

**Full mode:**

1. Present plan summary to user while plan-challenger runs
2. Collect plan-challenger result (wait if still running)
3. Apply challenger findings: remove YAGNI/scope-creep tasks, add missing tasks, correct ordering
4. If user requests plan changes: apply edits directly to `plan.md`, re-spawn plan-challenger against revised plan
5. If all CHALLENGED items are SUSTAINED or user overrides with explicit justification → proceed

**GATE (Full mode):** plan-challenger addressed + user approves final plan → proceed to Phase 4.

Emit Readiness Verdict in plan.md `## Readiness Verdict` section. If NEEDS WORK or NOT READY, do not proceed without explicit user decision.
