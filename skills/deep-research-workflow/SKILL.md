---
name: deep-research-workflow
description: |
  Guide for research-heavy feature development using the Research → Plan → Implement pattern.
  Use when: (1) implementing complex features that touch multiple files, (2) user says "research first",
  (3) task requires understanding existing codebase deeply before changing it, (4) feature has multiple
  valid approaches and needs exploration, (5) user wants structured development workflow
---

# /deep-research-workflow

Structured development workflow for complex features. Based on the Research → Plan → Implement pattern where planning is thorough and implementation is mechanical.

**Why this works:** Jumping from prompt to code causes wrong caching assumptions, ignored ORM conventions, duplicated logic, and broken surrounding systems. Research-first catches these before any code is written.

**Key principle:** Implementation should be mechanical, not creative. All creative decisions happen during research and planning.

Copy this checklist and check off items as you complete each phase:

```
Progress:
- [ ] Phase 1: Research
- [ ] Phase 2: Plan (annotation cycles: 0)
- [ ] Phase 3: Implement
```

## Phase 1: Research

Create `research.md` in the working directory using [references/research-template.md](references/research-template.md).

**Deep-read directives** — for each area relevant to the feature:

1. **Trace execution paths** — follow the full request/response cycle, not just the entry point
2. **Map data flow** — how data moves between layers, what transforms happen
3. **Document conventions** — naming, error handling, validation patterns, test structure
4. **Identify reusable code** — existing functions, utilities, abstractions that solve similar problems
5. **Note constraints** — what could break, non-obvious coupling, performance-sensitive paths

Read deeply. Trace the full path from entry to exit. Document intricacies, not just surface patterns. If a function calls 3 other functions, read all 3.

**Tools to use:** Glob, Grep, Read extensively. For indexed projects, use qmd search/vector_search before file reads. Use Task(subagent_type="Explore") for broad codebase exploration.

**Output:** Write structured findings to `research.md`. Every section should cite specific files and line numbers.

Do NOT proceed to Phase 2 until research covers all areas the feature touches.

## Phase 2: Plan

Create `plan.md` from research findings using [references/plan-template.md](references/plan-template.md). Use a custom markdown file — not Claude Code's built-in plan mode — for full editor control, inline annotation capability, and persistence as a project artifact.

**Plan structure:**

1. **Problem statement** — what exactly are we solving, and why now
2. **Approach** — high-level strategy with rationale
3. **File-by-file changes** — what changes in each file and why; include code snippets where helpful
4. **Trade-offs** — what we chose, what we rejected, and why
5. **Test strategy** — how to verify correctness
6. **Task list** — granular, ordered, checkable items

**Reference existing code as specification** — when the codebase already has similar patterns (e.g. another API endpoint, another component), reference that code explicitly as the model to follow. Do not design from scratch when a working example exists.

### Annotation Cycle

Present the plan for user review. The user may:

- Correct assumptions ("use drizzle:generate, not raw SQL")
- Reject sections ("remove this entirely")
- Add constraints ("retry logic is redundant here because...")
- Redirect architecture ("restructure the schema like this instead")

Revise the plan based on annotations. Repeat until the user approves. Track cycle count in the progress checklist.

**Important:** Do not implement during this phase. If the user says "don't implement yet" — continue refining the plan.

## Phase 3: Implement

Execute the approved plan mechanically. Follow the task list in order. Do not stop until all tasks and phases are completed.

**During implementation:**

- Mark tasks complete in `plan.md` as each is done
- Run type checks / linting continuously — do not accumulate errors
- No unnecessary comments, jsdocs, or type annotations beyond what the plan specifies
- No feature creep — if you notice something outside the plan, note it in `plan.md` under a "Future" section, don't implement it
- Protect existing interfaces — do not change function signatures unless the plan explicitly calls for it; callers adapt, not the interface

**Feedback during implementation** — keep it terse. Planning = paragraphs, implementation = single sentences. For visual issues, prefer screenshots over verbal descriptions.

**Scope discipline:**

- Cherry-pick proposals item-by-item — do not batch large changes
- If implementation reveals the plan was wrong → **stop, revert, and re-scope** (return to Phase 2)
- Do NOT incrementally patch a wrong direction — revert cleanly and re-plan
- Terse corrections during execution, not re-planning mid-stream

**When done:** Verify against the test strategy in the plan. Run tests, type checks, and any other validation the plan specifies.

## Anti-patterns

- Jumping from prompt to code without written plan → "falls apart"
- Chat-based steering instead of document-based annotation
- Patching bad approaches incrementally instead of reverting
- Using loose/any types to make things compile quickly
- Adding unnecessary comments or jsdocs to generated code
- Allowing scope creep during implementation phase
- Splitting research, planning, and implementation across separate sessions — single long sessions preserve context better

## Key Rules

- **Persistent artifacts** — `research.md` and `plan.md` anchor context through compression; if context is compacted, re-read these files to resume
- **Plan before code** — all creative decisions happen in research/planning; implementation is execution
- **Revert over patch** — if going wrong, revert and re-scope; incremental patches compound mistakes
- **Scope trimming** — actively cut scope; a smaller correct feature beats a larger broken one
- **Reference existing patterns** — use codebase code as specification, not abstract design
- **Emphatic depth** — surface-level research causes surface-level bugs; read deeply, trace fully
- **Annotation cycles are valuable** — 1-6 rounds of plan review catches more issues than rushing to code
