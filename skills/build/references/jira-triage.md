# Jira Triage (Phase 1 — Jira Key Present)

Loaded by [phase-1-triage.md](phase-1-triage.md) Steps 2c/2d/2e and Step 4 when `$ARGUMENTS` contains a Jira key.

---

## Step 2c — Fetch Jira Context

Follow [jira-integration](../../jira-integration/SKILL.md) §build:

1. Use `issue-bootstrap` (atlassian-pm) or `mcp__mcp-atlassian__jira_get_issue` (direct MCP) — record which path succeeded; Step 4 uses it.
2. Extract: status, AC items, subtasks, assignee.
3. AC items become plan task constraints (Phase 3).
4. Stage full Jira context for `devflow-context.md` (Step 6).

---

## Step 2d — Duplicate Detection

If `jira-search` agent (atlassian-pm plugin) is available, search for similar in-progress work:

```text
jira-search: "status = 'In Progress' AND summary ~ '{task keywords}' AND key != '{JIRA-KEY}'"
```

- Match found → Call AskUserQuestion:
  question: "{MATCH-KEY} ({assignee}) is already working on a similar task: '{match summary}'. Continue anyway?"
  header: "Possible Duplicate"
  options: [{ label: "Continue" }, { label: "Switch to existing" }]
- No match or jira-search unavailable → proceed silently.

---

## Step 2e — AC Quality Check

For each AC item fetched in Step 2c, flag if:

- ❌ **No measurable outcome** — vague improvement without a testable condition
  (e.g. "ระบบต้องเร็วขึ้น" with no threshold, "improve error handling" with no criterion)
- ❌ **Unbounded scope** — no explicit boundary on what is NOT included
  (e.g. "handle all edge cases" — edge cases of what, exactly?)
- ❌ **Contradicts another AC** — mutually exclusive conditions in same ticket

Output an AC quality table before proceeding to Step 3:

| AC | Status | Issue |
| --- | --- | --- |
| AC1 | ✅ Testable | — |
| AC2 | ⚠️ Ambiguous | No success threshold defined |

If **2 or more ACs are flagged**: Call AskUserQuestion before proceeding:

- question: "{N} ACs have quality issues (see table above). Proceed with ambiguous ACs or clarify first?"
- header: "AC Quality Warning"
- options: [{ label: "Proceed as-is" }, { label: "Clarify now" }]
- If "Clarify now" → capture clarification, update AC items in-memory, then proceed.
- If 0–1 ACs flagged → proceed silently.

---

## Step 4 — Auto-Transition to In Progress

**Run only if:** Jira key present AND at least one Jira integration reachable (detected in Step 2c).
**Skip silently** if no Jira key or Jira unreachable — never blocks the workflow.

**Detect path** (priority order):

| Path | Condition | Extra behavior |
| ------ | ----------- | ---------------- |
| **atlassian-pm** | `issue-bootstrap` succeeded in Step 2c | WIP gate fires automatically; call `cache_invalidate` after transition (HR6) |
| **mcp-atlassian** | `mcp__mcp-atlassian__jira_transition_issue` available | No WIP hook, no cache; transition only |
| **Skip** | Neither available | Proceed silently |

Use ticket status already fetched in Step 2c (no re-fetch needed).

| Current Status | Action |
| ---------------- | -------- |
| To Do / Backlog / Open | Transition to In Progress |
| In Progress / Reopened | Skip — note: `{JIRA-KEY} already In Progress — skipping` |
| Done / Closed / Cancelled | Ask user (see below) |

**If transition needed:**

1. Call `jira_get_transitions(issue_key)` → find transition whose name contains "In Progress" (case-insensitive)
2. Call `jira_transition_issue(issue_key, transition_name)`
   - **atlassian-pm path only:** `pre_wip_limit_check` fires automatically
     - If WIP blocked AND count ≥ wip_max → **STOP**: "WIP limit reached for In Progress ({count}/{wip_max}). Finish an existing item first."
3. **atlassian-pm path only:** Call `cache_invalidate(issue_key)` (HR6)
4. Output: `{JIRA-KEY} → In Progress [OK]`

**If Done / Closed / Cancelled:** Call AskUserQuestion:

```text
question: "Ticket {JIRA-KEY} is already {status}. Proceed anyway?"
header: "Ticket Status Warning"
options: [{ label: "Proceed" }, { label: "Stop" }]
```

→ Stop: exit skill. → Proceed: continue without transitioning.
