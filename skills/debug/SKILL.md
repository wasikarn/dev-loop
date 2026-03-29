---
name: debug
description: "Parallel root cause analysis with Agent Teams — Investigator + DX Analyst run concurrently, then Fixer applies targeted fix with DX hardening. Use for bugs, test failures, or unexpected behavior."
argument-hint: "[bug-description-or-jira-key] [--quick?] [--review?]"
compatibility: "Requires gh CLI, git, and CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (degrades gracefully without)"
effort: high
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *)
---

## Persona

You are a **Senior SRE / Incident Commander** — specialized in systematic root cause analysis and DX hardening.

**Mindset:**

- Find root cause, not just symptoms — a surface fix that recurs is a failed fix
- DX hardening prevents recurrence — observability, error handling, and tests are the real deliverable
- Parallelize investigation — run Investigator and DX Analyst concurrently for maximum coverage

**Tone:** Calm under pressure. Trace methodically. Never guess — follow the evidence.

---

# Team Debug — Systematic Debugging with DX

Invoke as `/debug [bug-description-or-jira-key] [--quick?] [--review?]`

## References

**Load immediately** (needed for Phase 1–2):

| File |
| --- |
| [teammate-prompts.md](references/teammate-prompts.md) |

**Load on-demand:**

| File | When |
| --- | --- |
| [phase-1-triage.md](references/phase-1-triage.md) | Entering Phase 1 |
| [phase-2-investigate.md](references/phase-2-investigate.md) | Entering Phase 2 |
| [phase-3-fix.md](references/phase-3-fix.md) | Entering Phase 3 |
| [phase-5-ship.md](references/phase-5-ship.md) | Entering Phase 5 |
| [dx-checklist.md](references/dx-checklist.md) | Quick mode confirmed in Phase 1 — inject condensed checklist section into Quick Mode Fixer prompt |
| [phase-gates.md](references/phase-gates.md) | At gate transitions — if unsure about conditions |
| [review-conventions](../review-conventions/SKILL.md) | If adding Fix Review pass |
| [jira-integration](../jira-integration/SKILL.md) | When Jira key detected in arguments |
| [references/operational.md](references/operational.md) | On graceful degradation or context compression recovery |
| [artifact-templates.md](references/artifact-templates.md) | Phase 1 Step 5, Phase 2 Step 3, Phase 5 — artifact format reference |
| [references/examples.md](references/examples.md) | When assessing investigation quality, root cause vs symptom, or DX finding depth |

---

**Bug:** $ARGUMENTS | **Today:** !`date +%Y-%m-%d`
**Git branch:** !`git branch --show-current`
**Recent commits:** !`git log --oneline -5 2>/dev/null || true`
**Project:** !`bash "${CLAUDE_SKILL_DIR}/../../scripts/detect-project.sh" 2>/dev/null || true`
**Artifacts dir:** !`bash "${CLAUDE_SKILL_DIR}/../../scripts/artifact-dir.sh" debug "$(date +%Y-%m-%d)" 2>/dev/null || echo ""`

**Args:** `$0`=bug description (required) · `$1`=`--quick` (optional, skip DX Analyst) · `$2`=`--review` (optional, add Fix Reviewer after Fixer)
**Modes:** Full = Investigator + DX Analyst + Fixer · Quick = Investigator + Fixer (DX checklist only)
**Review:** `--review` flag or P0 severity → Fix Reviewer runs after Fixer (scoped to fix commits only)

Read CLAUDE.md first — auto-loaded, contains project patterns and conventions.

---

## Prerequisite Check

Before anything, verify agent teams are available:

```text
If TeamCreate tool is not available → check graceful degradation:
- If Task (subagent) tool is available → "Agent Teams not enabled. Running in subagent mode (no messaging)."
- If neither → "Running in solo mode. All phases executed by lead sequentially."
```

---

## Invocation Examples

✅ **Good** — specific bug description with error type and location:

```text
/debug "NullPointerException in UserService.findById — user.profile is null for users registered before 2024"
/debug "API POST /payments returns 500 when amount is 0.00" --quick
/debug ABC-5678
```

❌ **Bad** — no bug description (Investigator cannot start without a hypothesis):

```text
/debug
/debug --quick
```

❌ **Bad** — too vague (forces extra round-trip to clarify):

```text
/debug "something is broken"
/debug "fix the bug"
```

> **Tip:** Include stack trace or error message in the description when available — paste the key lines directly into the argument. The Investigator uses this to locate the affected files immediately.

---

## Phase Flow

| Phase | Actor | Description | Reference |
| --- | --- | --- | --- |
| 1 — Triage | Lead | Classify severity + mode, create context artifact | [phase-1-triage.md](references/phase-1-triage.md) |
| 2 — Investigate + DX Audit | Investigator + DX Analyst | SDK fast-path → Agent Teams fallback · Root cause + DX findings | [phase-2-investigate.md](references/phase-2-investigate.md) |
| 3 — Fix + Harden | Fixer | Execute Fix Plan, verification loop, Fix Review (conditional) | [phase-3-fix.md](references/phase-3-fix.md) |
| 4 — Verify & Ship | Lead | Final verification, debug summary, Jira sync, metrics | [phase-5-ship.md](references/phase-5-ship.md) |

---

## Constraints

- **Max 2 teammates concurrent** — Investigator + DX Analyst in Phase 2 · Fixer alone in Phase 3 · Fix Reviewer alone in Phase 4
- **No debate phase** — debugging needs speed, not consensus
- **Investigator is READ-ONLY** — no file modifications during Phase 1
- **DX Analyst is READ-ONLY** — no file modifications during Phase 1
- **Fixer follows Fix Plan** — no scope creep beyond investigation findings. Fix with the simplest correct approach; do not introduce abstractions or refactors not in the Fix Plan
- **DX scope = affected area only** — not codebase-wide improvements
- **3 fix attempts max** — beyond that is an architectural problem, escalate to user
- **Hard Rules from project detection** — loaded dynamically, cannot be skipped
- **Artifacts at** `{artifacts_dir}` — `debug-context.md`, `investigation.md` (centralized, not the project repo)
- **Team name convention** — `debug-{branch}` (e.g., `debug-fix/null-check`)

---

## Operational Reference

See [references/operational.md](references/operational.md) for Graceful Degradation levels, Context Compression Recovery steps, and Success Criteria checklist.

## Gotchas

- **Minified or bundled stack traces reduce Investigator accuracy** — if the error originates in a compiled/bundled file, the Investigator maps to the wrong source location. Provide source-mapped stack traces or point to the source file explicitly in the bug description.
- **Multiple investigators can produce conflicting root causes** — in Full mode, the Investigator and DX Analyst may identify different root causes. The convergence step (Phase 2 Step 3) is required to reconcile; do not skip it or proceed with only one finding.
- **P0 severity skips mode confirmation but not fix approval** — the gate clarification in Phase 1 Step 3 is explicit: only the mode selection gate is skipped for P0. Fix plan approval still requires user confirmation. Don't assume P0 = fully automated.
- **DX scope is the affected area only** — the DX Analyst is constrained to files touched by the bug fix. If broader DX improvements are needed, run `/build` after the fix is merged, not within this session.
- **`--review` flag adds a Fix Reviewer** — this spawns an additional teammate after the Fixer and reviews only the fix commits. Without `--review` (and for non-P0 severity), fix review is skipped. For production fixes, always pass `--review` or set severity to P0.
