# CLAUDE.md Quality Criteria

## Scoring Rubric (100 points)

| Criterion | Weight | What to check |
| --- | --- | --- |
| Commands/workflows | 20 | Build, test, lint, deploy commands present and copy-paste ready |
| Architecture clarity | 20 | Key directories, module relationships, entry points documented |
| Non-obvious patterns | 15 | Gotchas, quirks, workarounds, "why we do it this way" |
| Conciseness | 15 | No filler, no obvious info, each line adds value |
| Currency | 15 | Commands work, file references accurate, tech stack current |
| Actionability | 15 | Instructions executable, paths real, steps concrete |

## Score Breakdown

**20/20 Commands:** All essential commands with context, dev workflow clear
**15/20:** Most commands present, some missing context
**10/20:** Basic commands only, no workflow
**5/20:** Few commands, many missing
**0/20:** No commands

**20/20 Architecture:** Key dirs explained, module relationships, entry points, data flow
**15/20:** Good overview, minor gaps
**10/20:** Basic directory listing only
**0/20:** No architecture info

**15/15 Non-obvious:** Gotchas captured, workarounds, edge cases, unusual pattern reasons
**10/15:** Some patterns documented
**5/15:** Minimal
**0/15:** None

**15/15 Conciseness:** Dense valuable content, no redundancy with code (exclude auto-generated sections like `<claude-mem-context>` from size measurement)
**10/15:** Mostly concise, some padding
**5/15:** Verbose in places
**0/15:** Mostly filler

**15/15 Currency:** Reflects current codebase, commands work, refs accurate
**10/15:** Mostly current, minor staleness
**5/15:** Several outdated references
**0/15:** Severely outdated

**15/15 Actionability:** Copy-paste ready, concrete steps, real paths
**10/15:** Mostly actionable
**5/15:** Some vague instructions
**0/15:** Theoretical

## Grades

| Grade | Score | Meaning |
| --- | --- | --- |
| A | 90–100 | Comprehensive, current, actionable |
| B | 70–89 | Good coverage, minor gaps |
| C | 50–69 | Basic info, missing key sections |
| D | 30–49 | Sparse or outdated |
| F | 0–29 | Missing or severely outdated |

## Red Flags

- Commands that would fail (wrong paths, missing deps)
- References to deleted files/folders
- Outdated tech versions
- Copy-paste from templates without customization
- Generic advice not specific to the project
- "TODO" items never completed
- Duplicate info across multiple CLAUDE.md files

## Vercel-Aligned Checks

In addition to the rubric, verify these patterns from Vercel research:

| Check | Pass | Fail |
| --- | --- | --- |
| Retrieval directive | Has "Prefer retrieval-led reasoning" or equivalent for framework projects | No retrieval guidance |
| Wording style | Uses explore-first / "Prefer X" framing | Uses absolute "MUST" directives that cause tunnel vision |
| Novel content priority | Post-training-cutoff APIs documented in detail | Equal space for obvious and novel content |
| Self-invocation hint | Has reminder to run `/optimize-context` when stale | No maintenance guidance |
| Framework docs index | Has pointer to docs/ or retrieval index (if framework project) | Full docs embedded inline |

These checks don't add to the 100-point score but are reported as bonus flags: `✅ Vercel-aligned` or `⚠️ Missing Vercel patterns`.

## Assessment Process

1. Read CLAUDE.md completely
2. Cross-reference with actual codebase (check files exist, commands work)
3. Score each criterion (100-point rubric)
4. Run Vercel-aligned checks (bonus flags)
5. **Eval-based validation:** Run 2-3 documented commands, verify file paths exist
6. Calculate total, assign grade
7. List specific issues + Vercel alignment status
8. Propose concrete improvements
