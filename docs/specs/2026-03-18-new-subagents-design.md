# Design: New Subagents for DLC Skill Suite

**Date:** 2026-03-18
**Status:** Approved

## Problem Statement

The DLC skill suite (dlc-build, dlc-review, dlc-debug) has two workflow gaps:

1. **Review consolidation is duplicated** — dlc-build delegates to an inline unnamed Haiku
   subagent (`consolidation-prompt.md`) while dlc-review makes the main model do the same
   mechanical dedup/sort steps inline. Same logic, two implementations, main model doing
   Haiku-level work.

2. **dlc-debug has no bootstrap agent** — unlike dlc-build (dev-loop-bootstrap) and
   dlc-review (pr-review-bootstrap), dlc-debug makes the lead pre-gather context inline
   (Phase 1 Bootstrap Steps 1–4). Worse: when triggered after dlc-build, the Investigator
   starts with zero knowledge of what was just built — causing redundant file reads in
   the common build→test→debug workflow.

## Solution

Create 2 named Haiku agents that integrate into the existing DLC skill call sites.

---

## Agent 1: `review-consolidator`

### Purpose

Mechanical post-review dedup/sort/signal-check. Offloads the consolidation work from
main model context in both dlc-build (replacing `consolidation-prompt.md`) and dlc-review
(replacing 4 inline steps in Phase 4 Convergence).

### Spec

```yaml
name: review-consolidator
model: haiku
tools: Read
memory: none
```

`Read` is available for future extension; the primary input form is inline text in prompt.

### Input

Both callers (dlc-build and dlc-review) pass raw reviewer findings **inline in the agent
prompt** as concatenated findings tables — the lead collects reviewer outputs and embeds
them directly. No separate per-reviewer files are read.

**Token note:** inline findings for 3 reviewers typically fit within Haiku's context; if a
review is unusually large (>200 findings total), the calling skill should write findings
to a temp file and pass the path instead, using the `Read` tool.

### Process (strictly ordered)

1. **Confidence filter** — drop findings below role threshold (Hard Rule violations bypass):

   | Reviewer role | Threshold |
   | --- | --- |
   | Correctness & Security | 75 |
   | Architecture & Performance | 80 |
   | DX & Testing | 85 |

2. **Dedup** — same file:line → keep highest severity, merge evidence; do not merge
   findings with different root causes even if in the same file
3. **Pattern cap** — same violation in >3 files → consolidate to 1 row + "and N more"
4. **Sort** — Critical → Warning → Info
5. **Signal check** — if (Critical+Warning)/Total < 60% → prepend `⚠ Low signal` to output

### Output

Written to `.claude/dlc-build/review-findings-{iteration}.md` (dlc-build) or returned
inline (dlc-review). Format follows `review-output-format.md` — columns: `#`, `Sev`,
`Rule`, `File`, `Line`, `Consensus`, `Issue`. The `Confidence`, `Reviewer`, and `Fix`
columns from the old `consolidation-prompt.md` format are intentionally dropped
(post-debate consolidation does not need them).

```markdown
**Summary: Critical X / Warning Y / Info Z**

| # | Sev | Rule | File | Line | Consensus | Issue |
|---|-----|------|------|------|-----------|-------|
| 1 | Critical | #2 | `src/foo.ts` | 42 | 3/3 | ... |
```

### Error Handling

- No findings from a reviewer → proceed with remaining reviewers; note `[no findings from reviewer N]`
- Empty total findings → return empty table (not an error)
- **Call-site fallback:** if agent errors, the calling skill lead performs consolidation
  inline (same pattern as other DLC skill fallbacks)

### Integration Points

| Skill | Phase | Change |
| ------- | ------- | -------- |
| dlc-build | Phase 4 iter 1 (3 reviewers only) | Replace "load `consolidation-prompt.md` and delegate" with "run `review-consolidator` agent with raw findings inline" |
| dlc-review | Phase 4 Convergence | Replace 4 inline steps (Dedup/Pattern cap/Sort/Signal check) with "run `review-consolidator` agent with surviving debate findings inline" |

**File retired:** `skills/dlc-build/references/consolidation-prompt.md` — content moves
to agent body.

---

## Agent 2: `dlc-debug-bootstrap`

### Agent Purpose

Pre-gather shared context before dlc-debug Phase 1 spawns Investigator and DX Analyst
teammates. Key differentiator from other bootstrap agents: reads dlc-build artifacts when
present, giving the Investigator full context of what was just built without redundant
reads — critical for the common build→test→debug workflow.

### Agent Spec

```yaml
name: dlc-debug-bootstrap
model: haiku
tools: Read, Glob, Bash, Grep
memory: none
```

**Notes on omitted frontmatter fields:** `argument-hint` and `compatibility` are SKILL.md
fields only — not valid in agent frontmatter. The agent requires `fd` and `ast-grep` in
the environment; if unavailable, it falls back gracefully (see Error Handling).

### Agent Input

Passed by the calling skill inline in the agent prompt:

- `bug_description` — bug description text or Jira key from user's `$ARGUMENTS`
- `project_root` — absolute path to target project root (passed explicitly by dlc-debug lead)

### Agent Process

```text
Step 1: Check for dlc-build artifacts
  Read("{project_root}/.claude/dlc-build/dev-loop-context.md")
  ├─ Found → extract plan items and modified files relevant to bug area
  └─ Not found → skip; omit "Recent Build Context" section from output

Step 2: Map affected files from bug description
  Parse stack trace / error message for file paths (max 5)
  If no stack trace: fd -t f patterns matching area named in description
  If still empty: note "affected files unknown — Investigator must determine"

Step 3: Recent commits in affected area
  git log --oneline -10 -- {affected_files}
  (skip if affected files unknown)

Step 4: Scan file structure (NOT full file content)
  ast-grep for function signatures in affected files
  Collect key class/interface names only
  Fallback: grep -n "^export\|^class\|^function" if ast-grep unavailable

Step 5: Append ## Shared Context to debug-context.md
```

### Output Written to `debug-context.md`

The agent appends this section. If `debug-context.md` does not yet exist, the agent
creates a minimal skeleton (`# Debug Context\n**Bug:** {description}\n`) before appending.

```markdown
## Shared Context
**Gathered:** {timestamp}

### Recent Build Context (from dlc-build)
(section present only when dlc-build artifacts found and relevant to bug area)
{plan items related to affected area — file:line format}
{modified files from recent build}

### Affected Files
- {file:line-range} — {one-line description of relevant section}

### Recent Commits
{git log --oneline -10 output for affected files}

### Code Structure Notes
{function signatures and key class/interface names in affected area}
```

All sub-sections are required except "Recent Build Context" (conditional) and
"Code Structure Notes" (omit if no meaningful structure found in max 5 files).

### Agent Error Handling

- `debug-context.md` not yet created → create skeleton then append
- `ast-grep` unavailable → fallback to grep for function signatures; note in output
- `fd` unavailable → fallback to Glob for file mapping
- dlc-build artifacts found but unrelated to bug area → omit Recent Build Context section
- **Call-site fallback:** if agent errors, dlc-debug lead executes Phase 1 Bootstrap
  Steps 1–4 inline (original behavior)

### Integration Point

| Skill | Phase | Change |
| ------- | ------- | -------- |
| dlc-debug | Phase 1 Bootstrap Steps 1–4 | Replace inline Steps 1–4 with "run `dlc-debug-bootstrap` agent; pass `project_root` and `bug_description` in prompt" |

**Calling convention:** dlc-debug lead passes both values inline in the agent invocation
prompt — no argument parsing needed. The agent reads `project_root` from the prompt text
and uses it as the base path for all file operations.

---

## Files Changed

| File | Action | Notes |
| ------ | -------- | ------- |
| `agents/review-consolidator.md` | Create | ~70 lines |
| `agents/dlc-debug-bootstrap.md` | Create | ~90 lines |
| `skills/dlc-build/references/phase-4-review.md` | Edit | Replace "load consolidation-prompt.md" instruction |
| `skills/dlc-build/SKILL.md` | Edit | Add `review-consolidator` agent row to reference table |
| `skills/dlc-review/SKILL.md` | Edit | Replace Phase 4 Convergence inline steps |
| `skills/dlc-debug/SKILL.md` | Edit | Replace Phase 1 Bootstrap Steps 1–4 with agent call |
| `skills/dlc-build/references/consolidation-prompt.md` | Delete | Content moves to agent |

## Non-Goals

- Jira context agent — each skill uses Jira differently by design; a shared agent
  would either oversimplify or need per-skill configuration, adding complexity without gain
- dlc-respond bootstrap — thread-fetch pattern is simple and skill-specific; not worth extracting
- Agent Teams teammate extraction — teammates stay inline per DLC skill design intent;
  named agents and teammates serve different purposes

## Success Criteria

- `review-consolidator` produces consolidated findings with correct dedup, pattern-cap,
  sort order, and signal-check — verified against a known set of raw reviewer findings
- `dlc-debug-bootstrap` writes a `## Shared Context` section containing all required
  sub-sections (Affected Files, Recent Commits, Code Structure Notes) as defined in
  the output schema above; Recent Build Context present when dlc-build artifacts exist
- Both agents degrade gracefully (call-site fallback) when they error
- All 3 DLC skills pass `npx markdownlint-cli2` after edits
- Symlinks for both agents created via `bash scripts/link-skill.sh`
