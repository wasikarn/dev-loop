# CLAUDE.md Quality Criteria

## Scoring Rubric (100 points)

| Criterion | Weight | What to check |
| --- | --- | --- |
| Commands/workflows | 15 | Build, test, lint, deploy commands present and copy-paste ready |
| Architecture clarity | 15 | Key directories, module relationships, entry points documented |
| Retrieval readiness | 15 | Retrieval directive present, docs index for framework projects, explore-first wording |
| Conciseness | 15 | No filler, no obvious info, no noise, each line adds value |
| Non-obvious patterns | 10 | Gotchas, quirks, workarounds, "why we do it this way" |
| Novel content coverage | 10 | Post-cutoff APIs documented in detail, well-known patterns compressed/removed |
| Currency | 10 | Commands work, file references accurate, tech stack current |
| Actionability | 10 | Instructions executable, paths real, steps concrete |

## Score Breakdown

**15/15 Commands:** All essential commands with context, dev workflow clear
**10/15:** Most commands present, some missing context
**5/15:** Basic commands only, no workflow
**0/15:** No commands

**15/15 Architecture:** Key dirs explained, module relationships, entry points, data flow
**10/15:** Good overview, minor gaps
**5/15:** Basic directory listing only
**0/15:** No architecture info

**15/15 Retrieval readiness:** Has retrieval directive ("Prefer retrieval-led reasoning..."), docs index pointing to retrievable files, explore-first wording throughout
**10/15:** Has retrieval directive but no docs index, or uses some "MUST" directives
**5/15:** Partial retrieval guidance, mostly invoke-first wording
**0/15:** No retrieval guidance, full docs embedded inline, or absolute directives only

**15/15 Conciseness:** Dense valuable content, no noise, no redundancy (exclude auto-generated sections like `<claude-mem-context>` from size measurement)
**10/15:** Mostly concise, some padding or noise
**5/15:** Verbose in places, generic advice present
**0/15:** Mostly filler or noise

**10/10 Non-obvious:** Gotchas captured, workarounds, edge cases, unusual pattern reasons
**7/10:** Some patterns documented
**3/10:** Minimal
**0/10:** None

**10/10 Novel content:** Post-cutoff APIs documented in detail with examples, well-known patterns compressed or removed. Custom/internal APIs thoroughly documented
**7/10:** Some novel content identified, but incomplete coverage
**3/10:** Treats all content equally regardless of novelty
**0/10:** Only documents well-known patterns, misses post-cutoff or custom APIs

**10/10 Currency:** Reflects current codebase, commands work, refs accurate
**7/10:** Mostly current, minor staleness
**3/10:** Several outdated references
**0/10:** Severely outdated

**10/10 Actionability:** Copy-paste ready, concrete steps, real paths
**7/10:** Mostly actionable
**3/10:** Some vague instructions
**0/10:** Theoretical

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

## Vercel-Aligned Quick Checks

These patterns are now scored within the main rubric (Retrieval readiness + Novel content criteria). Use this as a quick pass/fail checklist:

| Check | Pass | Fail |
| --- | --- | --- |
| Retrieval directive | Has "Prefer retrieval-led reasoning" or equivalent | No retrieval guidance |
| Wording style | Explore-first / "Prefer X" framing | Absolute "MUST" → causes tunnel vision |
| Novel content | Post-cutoff APIs detailed, known patterns compressed | Equal space for all content |
| Docs index | Pointer to retrievable docs (if framework project) | Full docs embedded inline |
| Self-invocation | Reminder to run `/optimize-context` when stale | No maintenance guidance |
| Noise-free | No generic advice, no obvious patterns | Filler content that may distract agent |

## Assessment Process

1. Read CLAUDE.md completely
2. Detect framework + version, identify post-cutoff APIs
3. Cross-reference with actual codebase (check files exist, commands work)
4. Score each criterion (100-point rubric — Vercel patterns integrated)
5. Run quick checks (retrieval, wording, noise, docs index)
6. **Eval-based validation:** Run 2-3 commands, verify paths, test docs index retrievability
7. Calculate total, assign grade
8. List specific issues with improvement suggestions
