---
name: df-refactor
description: "Refactor code for clarity, maintainability, or structure. Modes: --simplify (clean up changed code, delegates to code-simplifier agent), --extract (extract functions/classes to reduce duplication), --restructure (reorganize code across files). Runs tests before and after to ensure safety. Use when code works but needs improvement."
argument-hint: "[file-or-area] [--simplify|--extract|--restructure]"
effort: high
allowed-tools: Read, Grep, Glob, Bash, Edit, Agent
---

# Refactor

**Target:** $ARGUMENTS | **Branch:** !`git branch --show-current 2>/dev/null || echo "unknown"`

## Step 1 — Read Target

Read the file(s) specified in `$ARGUMENTS`. Understand:

- Current structure, exports, and responsibilities
- Code patterns that need improvement (duplication, complexity, poor naming, large functions)

If no target specified: check `git diff HEAD --name-only` for recently changed files and use those.

## Step 2 — Baseline Tests

Run the existing test suite for the target area before touching anything:

```bash
# Detect test runner from package.json, then run tests related to the target file
npx vitest run --related <file>   # vitest
npx jest --findRelatedTests <file>  # jest
bun test <file>                    # bun
```

Record: pass count, fail count. If baseline is already failing, **stop and report** — refactoring a broken codebase is out of scope.

## Step 3 — Select Mode

Parse `$ARGUMENTS` for `--simplify`, `--extract`, or `--restructure`.

If no flag given: analyze the code and select the most appropriate mode based on the primary issue:

- Inconsistent style / verbose logic / dead code → `--simplify`
- Repeated code blocks (3+ occurrences, same pattern) → `--extract`
- Files doing too many things / tangled imports → `--restructure`

Announce the chosen mode and reason before proceeding.

## Step 4 — Execute Refactor

### --simplify

Delegate to `code-simplifier` agent:

```text
Agent: code-simplifier
Task: Review and simplify the following file(s) for reuse, quality, and efficiency: <file paths>
```

Wait for the agent to complete. Review its changes before proceeding to Step 5.

### --extract

1. Identify duplicated blocks — same logic appearing 3+ times or large functions (>40 lines) doing multiple things
2. Propose extracted names (functions/classes) inline — names should describe *what*, not *how*
3. Extract: move shared logic to the most appropriate location (same file, shared module, or utility file)
4. Update all call sites
5. Verify imports are correct

### --restructure

1. Map current file responsibilities and their dependencies
2. Propose the target structure — show what moves where
3. **Pause for user confirmation** before making changes: "Proposed reorganization: [plan]. Proceed?"
4. After confirmation: execute moves using Edit, update all import paths
5. Verify no circular imports were introduced

## Step 5 — Run Tests Again

Run the same test command from Step 2:

- All previously passing tests must still pass
- If any tests regressed: read the error, fix the regression, re-run
- Repeat up to 3 times. If still failing: revert the change (`git checkout -- <file>`) and report what failed

## Step 6 — Show Diff Summary

```bash
git diff --stat HEAD
```

Report:

- Files changed (added/modified/deleted)
- Test result before → after (e.g. "47 pass → 47 pass")
- Key changes made (2–4 bullet points)
