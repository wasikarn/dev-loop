# Phase 1: Triage (Lead Only)

```text
Phase 1 Flow:
Step 1: Resume check ──→ existing context? ──→ Yes: ask to resume / No: proceed
    ↓
Step 2: Parallel triage (all concurrent)
  2a: Detect project + domain lenses
  2b: Check pending PRs
  2c: Fetch Jira context (if Jira key)
  2d: Duplicate detection
  2e: AC quality check
    ↓
Step 3: Classify mode (decision tree → Full/Quick/Hotfix)
GATE: User confirms mode ──────────────────────────────────────────┐
    ↓                                                              │
Step 4: Auto-Transition to In Progress (atlassian-pm, if avail.)   │
    ↓                                                              │
Step 5: Load Mode File                                             │
    ↓                                                              │
Step 6: Create devflow-context.md artifact                        │
    ↓                                                              │
Step 7: Initialize progress tracker ←─────────────────────────────┘
```

## Step 1: Resume Check

Check if `{artifacts_dir}/devflow-context.md` exists:

```text
{artifacts_dir}/devflow-context.md exists AND Phase != "complete"?
├→ Yes: Show context summary → AskUserQuestion:
│   question: "Resume from Phase {N} — {task_description}?"
│   header: "Resume" · options: [{ label: "Resume" }, { label: "Start fresh" }]
│   ├→ Resume: Re-read artifacts in order:
│   │       1. {artifacts_dir}/devflow-context.md
│   │       2. Plan file: read plan_file: from YAML; fallback to {artifacts_dir}/{date}-{task-slug}/plan.md
│   │       3. {artifacts_dir}/review-findings-*.md (if exists)
│   └→ Start fresh: Overwrite context file with new task.
└→ No: Proceed with triage normally.
```

## Step 2: Parallel Triage

Run steps 2a, 2b, 2c concurrently — all are read-only and independent:

**2a — Detect Project:** Use the `Project` JSON from the header (output of `detect-project.sh`). It contains: `project`, `repo`, `validate`, `base_branch`, `branch`.

After detecting the project, also **detect domain lenses** from the task description and file extensions: if task mentions auth/API/security → load [review-lenses/security.md](review-lenses/security.md); SQL/DB/migration → [review-lenses/database.md](review-lenses/database.md); React/Next.js/frontend → [review-lenses/frontend.md](review-lenses/frontend.md); performance/bundle/query → [review-lenses/performance.md](review-lenses/performance.md); TypeScript types → [review-lenses/typescript.md](review-lenses/typescript.md). Multiple lenses can stack. Inject into `{domain_lenses}` placeholder in reviewer prompts at Phase 6.

- If `validate` is empty → add to confirmation prompt: "No validate command detected. What should I run to verify? (e.g. `npm test`)"
- Check for project-specific Hard Rules at `{project_root}/.claude/skills/review-rules/hard-rules.md`:
  - Exists → load it + note checklist.md and examples.md paths
  - Not exists → use Generic Hard Rules (as defined in review Phase 2)

**2b — Pending PRs Check:**

```bash
gh pr list --author @me --state open --json number,title,headRefName,createdAt \
  --jq '.[] | "#\(.number) \(.headRefName) — \(.title)"'
```

- If Jira key in `$ARGUMENTS` (e.g. `ABC-1234`) → check if any open PR branch contains that key
  - Match found: AskUserQuestion — question: "PR #1941 already targets ABC-1234. Switch to that PR?",
    header: "Existing PR", options: [{ label: "Switch to PR #1941" }, { label: "Continue new task" }]
    → Switch: stop. → Continue: proceed.
- No match / no Jira key: list open PRs briefly, ask if user wants to switch to one
- No open PRs → proceed silently

**2c — Jira Context:** If Jira key in $ARGUMENTS — read [jira-triage.md](jira-triage.md) for fetch, duplicate detection, and AC quality check steps.

## Step 3: Classify Mode

Per [workflow-modes.md](workflow-modes.md) — blast-radius auto-scoring:

**`--hotfix` flag** → Hotfix mode immediately. Skip scoring. Skip to Step 4.

**All other tasks:** Score 5 blast-radius factors (score 1 = yes, 0 = no):

| Factor | Score 1 if… |
| -------- | ------------- |
| **Scope** | Task touches >1 module or service boundary |
| **Risk** | Task involves auth / payment / DB migration / public API |
| **Novelty** | Pattern doesn't exist in codebase (new abstraction, new dependency) |
| **Dependencies** | Code being changed has known downstream consumers |
| **Ambiguity** | Task description is underspecified or has unclear AC. Tie-break: uncertain → score 1. |

**Score → suggested mode:**

| Score | Suggested mode |
| ------- | --------------- |
| 0–2 | Micro |
| 3 | Quick |
| 4–5 | Full |

If a mode flag (`--micro`/`--quick`/`--full`) was passed **and is lower than the score** → **downgrade protection** (see workflow-modes.md §Flag vs. Score Precedence). Lead lists scoring factors and requires "yes" before proceeding with lower mode.

**GATE:** Call AskUserQuestion to confirm mode:

- question: "Task scored {X}/5 → suggesting {mode}{validate_suffix}. Confirm or override?"
  (append " — and validate command?" if validate is empty)
- header: "Mode"
- options: [{ label: "Micro" }, { label: "Quick" }, { label: "Full" }, { label: "Hotfix" }]
  (pre-select the scored mode as first option)

Set `mode_source`:

- `auto` if user confirms the scored suggestion
- `flag` if user passed an explicit mode flag
- `override` if user selects a different mode than scored

If validate is empty, follow up with a second AskUserQuestion or free-text prompt.
→ proceed.

**Step 4 — Auto-Transition:** If Jira key present — read [jira-triage.md](jira-triage.md) Step 4.

---

## Step 5: Load Mode File

After mode is confirmed, load the corresponding mode file:

- Micro → [references/modes/micro.md](modes/micro.md)
- Full → [references/modes/feature.md](modes/feature.md)
- Quick → [references/modes/quick.md](modes/quick.md)
- Hotfix → [references/modes/hotfix.md](modes/hotfix.md)

The mode file contains branch strategy and mode-specific phase pre-steps. Read it in full before proceeding. Branch setup is defined inside the mode file — `workflow-modes.md §Branch Setup` no longer exists.

## Step 6: Create Context Artifact

Write `{artifacts_dir}/devflow-context.md` with YAML frontmatter + Markdown body:

```yaml
---
task: "{task_description}"
mode: micro|quick|full|hotfix
blast_radius_score: 0-5
mode_source: auto|flag|override
phase: triage
iteration: 0
branch: "{branch_name}"
project: "{project_name}"
validate: "{validate_command}"
started: "{YYYY-MM-DD}"
jira: "{JIRA-KEY-or-empty}"
plan_file: ""
tasks_completed: []
---
```

Markdown body below frontmatter: Hard Rules summary, Jira context (AC items). Update `phase:` field at every gate transition. **Lead is sole writer of this file** — update `tasks_completed:` when workers send completion messages (prevents YAML race from parallel workers). Update `plan_file:` with the plan path immediately after Phase 3 creates the plan file.

## Step 7: Initialize Progress Tracker

Post a checkbox list in conversation: Phase 1 (done), Phase 2 (Full/Quick only), Phase 3, Loop iterations 1-3 with nested Phase 4/5/6/7/8, Phase 9. Update checkboxes as each phase completes.

Write metrics entry to `{artifacts_dir}/devflow-metrics.jsonl` (append, create if missing):

```json
{"ts":"<ISO8601>","phase":"triage","mode":"<mode>","mode_source":"<auto|flag|override>","blast_radius":N,"task_slug":"<slug>"}
```

Lead writes this directly — not via hook (metrics data not available at hook time).
