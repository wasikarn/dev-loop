# Workflow Modes

Auto-classification via blast-radius scoring (Phase 1). User can confirm or override.
All phase files reference this matrix — do not redefine mode behavior inline.

---

## Blast-Radius Scoring

Lead evaluates 5 factors from task description + live context:

| Factor | Score 1 if… |
| -------- | ------------- |
| **Scope** | Task touches >1 module or service boundary |
| **Risk** | Task involves auth / payment / DB migration / public API |
| **Novelty** | Pattern doesn't exist in codebase (new abstraction, new dependency) |
| **Dependencies** | Code being changed has known downstream consumers |
| **Ambiguity** | Task description is underspecified or has unclear acceptance criteria. Tie-break: if uncertain → score 1. |

**Score → Mode:**

| Score | Mode |
| ------- | ------ |
| 0–2 | **Micro** |
| 3 | **Quick** |
| 4–5 | **Full** |
| `--hotfix` flag | **Hotfix** (bypasses scoring entirely) |

Lead presents result: `"Task scored X/5 → suggesting [mode]. Proceed or override?"`

---

## Flag vs. Score Precedence

| Situation | Result |
| ----------- | -------- |
| `--hotfix` passed | Always Hotfix — no scoring, no override prompt |
| `--micro` / `--quick` / `--full` AND matches score | Use flag mode silently |
| Flag is **lower** than score | Downgrade protection (see below) |
| Flag is **higher** than score | Use flag — over-ceremony is safe |
| No flag | Use blast-radius score |

**Downgrade protection:** If user overrides toward lower ceremony, lead responds:

```text
"Overriding to [lower mode]. The following blast-radius factors scored 1:
  • [list each factor with brief explanation]

These increase the risk of rework or missed requirements.
Confirm override? (yes / no)"
```

Require explicit "yes" before proceeding. Gates hold harder under urgency, not softer.

---

## Mode Capability Matrix

Single source of truth for per-phase behavior. Phase files reference by phase name.

| Phase | Micro | Quick | Full | Hotfix |
| ------- | ------- | ------- | ------ | ------- |
| 1: Triage | Blast-radius → Micro auto | Blast-radius → confirm | Blast-radius → confirm | --hotfix bypasses scoring |
| 2: Research | **Skip** | **Lite** (WHAT/WHY, ~250 lines, 1 explorer) | **Deep** (delta markers + [NEEDS CLARIFICATION] + GO/NO-GO, 1–2 explorers) | Skip |
| 3: Plan | 1 truth, no gate | 2–3 truths, no user gate | 3–5 truths, user gate | 1–2 truths, no gate |
| 3: Plan-challenger | **Skip** | **Skip** | **Run** (dual-lens) | Skip |
| 4: Implement workers | 1 worker, `effort: low` | 1–2 waves, `effort: medium` | Multi-wave, `effort: high` | 1 worker, `effort: high` |
| 5: Verify | Lightweight (1 truth, escalate on fail — no loop) | Full (1 re-entry loop) | Full (1 re-entry loop) | Lightweight |
| 6: Review Stage 1 | Run | Run | Run | Run |
| 6: Review Stage 2 | 1 reviewer (self-review ≤50 lines) | 1–2 reviewers (see diff scale) | 3 reviewers + debate | 2 reviewers max (no DX) |
| 7: Simplify (optional sub-step) | **Skip** | Optional (Critical=0 required) | Default (Critical=0 required) | Skip |
| 8: metrics-analyst | **Skip** | **Skip** | Run if ≥5 entries | Skip |

---

## PhaseVerdict Schema

Three phases emit a PhaseVerdict: Phase 2 (GO/NO-GO), Phase 3 (readiness), Phase 5 (verify).
All use the same schema and escalation contract. Reference by name; do not redefine inline.

```text
PhaseVerdict:
  state: READY | NEEDS WORK | NOT READY
  evidence: [file:line citations — required for NEEDS WORK and NOT READY]
  escalation:
    READY:      proceed automatically
    NEEDS WORK: present to user, wait for decision (proceed / address first)
    NOT READY:  present blocking list, require explicit choice (a/b/c)
```

---

## Review Scale (Phase 4, Stage 2)

Reviewer count is determined by diff size, subject to Mode Capability Matrix caps above.

| Diff size | Reviewers | Debate | Notes |
| --- | --- | --- | --- |
| ≤50 lines | 1 (lead self-review) | None | Use Solo Self-Review Checklist in operational.md |
| 51–200 | 2 (Correctness + Architecture) | 1 round | Skip DX reviewer |
| 201–400 | 3 (full set) | Full (2 rounds max) | Standard review |
| 400+ | 3 (full set) | Full (2 rounds max) | Flag PR size to user |

**Quick mode override:** For diffs ≤100 lines in Quick mode, use lead self-review only (no teammates).

**Hotfix mode cap:** Always 2 reviewers max (Correctness + Architecture) — overrides diff scale.

**Iteration narrowing:** Each review iteration narrows scope:

- Iteration 1: full reviewer count per scale above
- Iteration 2: one fewer reviewer, focused on previous findings only
- Iteration 3: spot-check by lead only

---

## Hotfix Mode

`--hotfix` bypasses Phase 1 triage. Not affected by blast-radius scoring or downgrade protection.

- Branch from `main` (not `develop`) — `git checkout main && git pull`
- Scope is the broken code path **only** — no refactoring, no unrelated improvements
- Review: 2 reviewers max (Correctness + Architecture, skip DX)
- After merge to `main`: mandatory backport PR to `develop`
- Backport via cherry-pick; if conflicts → note in PR, assign to author

---

## Effort per Mode

Set in subagent spawn calls (not SKILL.md frontmatter — which is static):

- Micro workers → `effort: low`
- Quick workers → `effort: medium`
- Full workers → `effort: high`
- Lead (dlc-build itself) → always `effort: high`
