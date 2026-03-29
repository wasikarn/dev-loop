# Phase 2: Fix Threads

Fix in severity order: 🔴 Critical → 🟡 Important → 🔵 Suggestion (only if user requested).

**Bootstrap:** Run `devflow-respond-bootstrap` agent (Haiku) with PR #$0 before spawning Fixers. It
pre-reads all affected files and returns a JSON object with `fileContents` and `threadsByFile`.

When building each Fixer's prompt, scope from the JSON bootstrap output:

- Inject only `fileContents[file]` for the files in that Fixer's GROUP assignment
- Inject only `threadsByFile[file]` threads for those same files
- Inject `gitContext` (same for all Fixers)

This eliminates redundant file content in each Fixer prompt — a Fixer handling 1 of 3 files
receives only that file's content, not all 3.

**Bootstrap fallback:** If agent unavailable, lead reads affected files and runs
`git log --oneline -5 -- {affected_files}` inline and injects all content into each Fixer manually.

**Agent Teams mode:** Create 1 Fixer per non-overlapping file group using prompts from [teammate-prompts.md](teammate-prompts.md).
**Solo/subagent mode:** Lead fixes sequentially using the same Fixer rules.

**Lead verification gate (before Phase 3):**

1. Run validate independently: `{validate_command}` — if fails, revert and re-fix
2. Check `git diff --stat` — scope must match thread scope only (scope crept → revert)
3. Run `fix-intent-verifier` agent(s) — verify each fix addresses the reviewer's intent:
   - **1–2 file groups (or solo mode):** Spawn a single `fix-intent-verifier` (Haiku) with the full triage table and PR number.
   - **3+ file groups:** Spawn one `fix-intent-verifier` per group in parallel. Each receives only its group's threads and the diff for those files. Merge ADDRESSED/PARTIAL/MISALIGNED verdicts after all complete.

   For MISALIGNED threads: Fixer re-reads the original thread and re-fixes. For PARTIAL threads: Fixer refines before proceeding.

**GATE:** All Critical+Important fixed + Lead-verified validate passes. (See [phase-gates.md](phase-gates.md) Fix → Reply gate.)
