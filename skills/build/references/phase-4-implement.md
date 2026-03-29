# Phase 4: Implement

Before starting each iteration: `git tag devflow-checkpoint-iter-{N}` — enables instant rollback via `git checkout devflow-checkpoint-iter-{N}`.

## WorkerContext Schema

The worker contract is bidirectional. Lead uses these schemas when spawning workers.

**Lead → Worker (spawn):**

```text
<worker_context>
  wave_number: N
  assigned_tasks: [task 3, task 4]    ← tasks for THIS worker only
  completed_tasks: [task 1 ✅, task 2 ✅]
  must_haves: [truth 1, truth 2]      ← full list — worker must not regress passing truths
  key_links: [A→B, C→D]
  mode: micro|quick|full
  tdd_required: true|false
  files_to_read: [plan.md, research.md, src/...]
</worker_context>
```

**Worker → Lead (completion — required fields):**

```text
<worker_completion>
  assigned_tasks_status:
    - task 3: DONE | PARTIAL | BLOCKED
    - task 4: DONE | PARTIAL | BLOCKED
  files_modified: [src/auth.ts, tests/auth.test.ts]
  TDD_SEQUENCE:
    - first-test-write: [file:line] "[test description]"
    - first-test-run-FAIL: yes|no
    - first-impl-write: [file:line]
    - test-run-PASS: [file:line]
  TDD_COMPLIANCE: FOLLOWED | VIOLATED
  blocker: [reason if BLOCKED, else null]
</worker_completion>
```

Lead reads `assigned_tasks_status` to update `completed_tasks[]` for the next wave.
PARTIAL or BLOCKED tasks are re-queued as sequential (no [P] marker).
Lead infers TDD compliance from the SEQUENCE ORDER — not from the label alone.
If VIOLATED: log in `devflow-context.md` under `tdd_violations[]`; surface to user at Phase 8 summary (informational, not a blocker).

---

## Iteration 1: Full Implementation

Load [worker-prompts.md](worker-prompts.md) now. Worker count by mode:

- **Micro:** 1 worker, sequential tasks only
- **Quick/Full `[S]` tasks only:** 1 worker, sequential
- **Quick/Full `[P]` tasks exist:** 2 workers with non-overlapping file assignments

**Effort by mode:** Micro=`effort: low`, Quick=`effort: medium`, Full=`effort: high`.

Lead provides full WorkerContext (spawn schema above). Workers follow TDD: failing test → verify it fails for right reason → minimal impl → pass → commit. After each commit, worker sends `<worker_completion>` message; lead updates `tasks_completed:` in devflow-context.md.

**Per-commit spot-check (async):** Worker continues to next task immediately after sending completion — do NOT wait for lead acknowledgement. Lead processes asynchronously: run `git show {commit_hash} --stat` to verify file scope matches task. If unintended files found: SendMessage to worker to revert and re-implement scoped to assigned files. If worker already moved on: lead reverts via `git revert {hash}` and re-queues the task.

**`<files_to_read>` pattern:** Pass file paths to workers, not file contents:

```text
<files_to_read>
Read these files at the start of your task:
- {artifacts_dir}/{date}-{task-slug}/plan.md    (your assigned tasks)
- {artifacts_dir}/research.md                   (context and delta markers, if exists)
- {relevant_source_files}                       (files you will modify)
- .claude/skills/review-rules/hard-rules.md     (project rules)
</files_to_read>
```

On validate failure: see Checkpoint Recovery in [operational.md](operational.md).

---

## Iteration 2+: Fix Findings

Load [fixer-prompts.md](fixer-prompts.md) now. Create 1 fixer. Fixer receives ONLY failed must_haves.truths (from Phase 5) or unresolved Critical/Warning findings (from Phase 6) — targeted re-entry, not full re-implementation.

Fix order: Critical → Warning. Each fix = separate commit.

If fixer introduces a NEW Critical: revert + message lead.
If same finding fails 3× → see 3-Fix Rule in [operational.md](operational.md).

---

## Worker Shutdown (before Phase 5)

Verify all workers sent final `<worker_completion>` messages. Shut down worker team. Workers and reviewers must never be alive simultaneously.

**GATE:** All tasks done + validate passes + all workers shut down → proceed to **Phase 5: Verify**.

---

## Phase 4 Output

When all tasks complete and validate passes:

```markdown
### Phase 4: Implement Complete
| Task | Status | Commit | TDD |
|---|---|---|---|
| {task name} | ✅ | {short sha} | FOLLOWED |
| {task name} | ✅ | {short sha} | FOLLOWED |
→ Validate passes · Workers shut down · Proceeding to Phase 5 (Verify)
```
