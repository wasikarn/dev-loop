# optimize-context audit report — 2026-03-03

## Files

| File | Size | Score | Grade |
| --- | --- | --- | --- |
| ./CLAUDE.md | 3.0 KB | 78/100 | B |
| skills/admin-review-pr/CLAUDE.md | 1.5 KB | 79/100 | B |
| skills/api-review-pr/CLAUDE.md | 1.4 KB | 77/100 | B |
| skills/web-review-pr/CLAUDE.md | 1.4 KB | 78/100 | B |
| skills/deep-research-workflow/CLAUDE.md | 1.3 KB | 73/100 | B |
| skills/optimize-context/CLAUDE.md | 1.1 KB | 77/100 | B |
| skills/spec-kit/CLAUDE.md | 1.5 KB | 79/100 | B |

## Findings

| # | Type | File | Detail |
| --- | --- | --- | --- |
| 1 | Gaps (must add) | root | No retrieval directive or docs index table |
| 2 | Gaps (must add) | root | No repo-level lint command |
| 3 | Gaps (must add) | root | No Repo Commands reference table |
| 4 | Gaps (must add) | root | SKILL.md vs CLAUDE.md role not distinguished in layout |
| 5 | Gaps (must add) | root | `context:fork` caveat undocumented |
| 6 | Gaps (must add) | root | Pre-commit hook behavior undocumented |
| 7 | Gaps (must add) | root | No self-invocation reminder |
| 8 | Gaps (must add) | all skills | No retrieval directive + no docs index |
| 9 | Gaps (must add) | all skills | No skill architecture explanation |
| 10 | OK | all | Accurate, current, concise |

## Proposed Changes

| # | Finding | Action | Size Impact |
| --- | --- | --- | --- |
| 1 | No retrieval directive/docs index | Add ## Docs Index section (table + directive) | +280 bytes |
| 2 | No repo-level lint | Add to Adding a New Skill step 7 | +90 bytes |
| 3 | No Repo Commands table | Add ## Repo Commands table (4 rows) | +170 bytes |
| 4 | SKILL.md/CLAUDE.md role | Annotate skill structure layout | +80 bytes |
| 5 | context:fork caveat | Add to ## Gotchas section | +120 bytes |
| 6 | Pre-commit hook | Add to ## Gotchas section | +120 bytes |
| 7 | No self-invocation | Add to ## Gotchas section | +50 bytes |
| 8 | Skill files: retrieval | Add ## Docs Index to each skill CLAUDE.md | +100 bytes each |
| 9 | Skill files: architecture | Add ## Skill Architecture to review-pr files | +150 bytes each |

Projected root: 78/100 → 100/100 | Size: 3.0 KB → ~3.9 KB
Projected skill files: 73–79/100 → 88–92/100 | Size: +250 bytes each
