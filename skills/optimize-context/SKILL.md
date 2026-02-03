---
name: optimize-context
description: |
  Audit, score, and optimize CLAUDE.md files for maximum agent effectiveness. Combines quality assessment with codebase-aligned compression. Use when: (1) CLAUDE.md feels outdated or stale, (2) project codebase has changed significantly, (3) CLAUDE.md is too large or verbose (>15KB), (4) agent keeps making mistakes that better context would prevent, (5) new project needs initial CLAUDE.md setup, (6) checking quality of existing CLAUDE.md files, (7) user asks to "optimize context", "improve claude.md", "audit context", "check CLAUDE.md quality", "setup context", "init claude.md", or "bootstrap claude.md"
---

# /optimize-context

Audit, score, and optimize CLAUDE.md files for maximum agent effectiveness.
Passive context (CLAUDE.md) achieves 100% agent pass rate vs 79% for skills-based approaches,
and well-compressed context (8KB) performs identically to verbose (40KB).
See [Vercel research](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals).

## Workflow

1. **Discovery** — Find all CLAUDE.md files, identify types
2. **Quality Assessment** — Score each file against rubric
3. **Audit** — Check alignment with actual codebase
4. **Generate Update** — Plan changes with size impact
5. **Apply & Verify** — Edit, verify structure, spot-check

> `--dry-run` → run phases 1-3 only, output report, skip phases 4-5.

### 1. Discovery & Classification

Find all CLAUDE.md files in the project:

```bash
find . -name "CLAUDE.md" -o -name ".claude.local.md" -o -name ".claude.md" 2>/dev/null | head -50
```

Identify each file's type:

| Type | Location | Purpose |
| --- | --- | --- |
| Project root | `./CLAUDE.md` | Primary context (shared via git) |
| Local overrides | `./.claude.local.md` | Personal settings (gitignored) |
| Global defaults | `~/.claude/CLAUDE.md` | User-wide defaults |
| Package-specific | `./packages/*/CLAUDE.md` | Module-level in monorepos |

Also list `agent_docs/` and `.claude/rules/` (if any) for deduplication checks.

**Classify context type:**

| Type | Signal | Strategy |
| --- | --- | --- |
| Horizontal | Uses major framework (Next.js, NestJS, etc.) | Prioritize retrieval index + docs pointer |
| Vertical | Custom/internal project | Prioritize workflow docs + architecture |
| Hybrid | Framework + complex domain logic | Both: retrieval index + project-specific workflows |

Detect framework: check `package.json`, `requirements.txt`, `go.mod`, etc. If official docs index tool exists (e.g. `npx @next/codemod@canary agents-md`), recommend it.

**No CLAUDE.md found?** → Create one using the appropriate template from [references/templates.md](references/templates.md), then continue to phase 2.

### 2. Quality Assessment

Score each file using the 100-point rubric. See [references/quality-criteria.md](references/quality-criteria.md) for detailed scoring.

Quick checklist:

| Criterion | Weight | Check |
| --- | --- | --- |
| Commands/workflows | 20 | Build/test/deploy present and copy-paste ready? |
| Architecture clarity | 20 | Can Claude understand codebase structure? |
| Non-obvious patterns | 15 | Gotchas and quirks documented? |
| Conciseness | 15 | No verbose explanations or obvious info? |
| Currency | 15 | Reflects current codebase state? |
| Actionability | 15 | Instructions executable, not vague? |

Grades: A (90-100), B (70-89), C (50-69), D (30-49), F (0-29).

Output per file: `./CLAUDE.md — Score: XX/100 (Grade X) | Size: XX KB | Issues: [list]`

### 3. Audit

Check CLAUDE.md against codebase reality:

| Check | What to look for |
| --- | --- |
| Stale | References to files/patterns that no longer exist |
| Gaps | Codebase conventions not documented |
| Redundant | Duplicated with agent_docs or .claude/rules |
| Outdated | Code examples not matching current codebase |
| Oversized | Verbose sections compressible via tables/one-liners |

Categorize as `Stale (must fix)`, `Gaps (must add)`, `Redundant (can reduce)`, `OK`.

**Gate:** User confirms report before proceeding.

### 4. Generate Update

Apply changes following these priorities:

1. **Fix stale** → update to match actual codebase
2. **Fill gaps** → add missing patterns (compressed format)
3. **Deduplicate** → replace with pointers to agent_docs/rules
4. **Compress** → tables + one-liners over prose

For compression techniques: [references/compression-guide.md](references/compression-guide.md).
For templates by project type: [references/templates.md](references/templates.md).

**Size targets:** <8KB optimal, 8-15KB acceptable, >15KB needs compression.
**Size measurement:** Exclude auto-generated sections (`<claude-mem-context>`, plugin-injected blocks) from byte count — score only human-authored content.

Show each change with reason and size impact before applying.

**Gate:** User reviews preview before applying.

### 5. Apply & Verify

1. Edit CLAUDE.md files using Edit tool
2. Verify size: `wc -c` each file
3. Verify all sections still intact
4. **Eval-based validation:**
   - Run 2-3 commands documented in CLAUDE.md → confirm they still work
   - Verify file paths referenced → `ls` each critical path
   - Check retrieval directive present (if project uses a framework)
   - Confirm wording uses explore-first framing (not absolute "MUST" directives)
5. Re-score to confirm improvement

Report: `Score: XX → XX | Fixed N stale | Added N gaps | Removed N redundant | Size: XX KB → XX KB`

**Example output (phases 2-3):**

```markdown
## Audit Report

### ./CLAUDE.md — Score: 62/100 (Grade C) | Size: 18.2 KB

| Criterion | Score | Issue |
| --- | --- | --- |
| Commands | 15/20 | Missing deploy command |
| Architecture | 10/20 | No module relationships |
| Non-obvious | 12/15 | — |
| Conciseness | 5/15 | 3 verbose sections |
| Currency | 10/15 | `src/legacy/` no longer exists |
| Actionability | 10/15 | Vague "see docs" references |

### Findings

| # | Type | Detail |
| --- | --- | --- |
| 1 | Stale (must fix) | `src/legacy/` removed in v3 |
| 2 | Gaps (must add) | No env setup instructions |
| 3 | Redundant (can reduce) | API docs duplicated in agent_docs/ |
| 4 | Oversized | Architecture section 4KB → compressible to 0.8KB |
```

## Key Rules

- **Evidence-based** — Every change must trace to actual codebase (no guessing)
- **Preserve intent** — Never remove sections user intentionally added
- **Compress, don't delete** — verbose → concise tables, not removal
- **Index over embed** — Point to agent_docs for deep reference, keep CLAUDE.md as quick-ref index
- **Project-specific only** — No generic advice, no obvious info, no standard framework behavior
- **Idempotent** — Running repeatedly must not create duplicates
- **Retrieval over pre-training** — Ensure CLAUDE.md includes retrieval directive for framework projects
- **Explore-first wording** — Use "Prefer X" / "Check project first" over "You MUST" directives
- **Prioritize novel content** — APIs/patterns outside training data get more space than well-known ones
- **Self-invocation** — Recommend adding staleness reminder in CLAUDE.md (e.g. "Run `/optimize-context` when CLAUDE.md feels outdated")
