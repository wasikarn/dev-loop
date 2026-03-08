# Analyze Claude Features

Read and analyze each documentation source below, then assess what can be concretely applied or improved in this project.

**Goal:** Score how well this project uses Claude Code features relative to what's applicable. 100/100 means all relevant features are properly adopted — not that every feature is used. A simple script repo shouldn't need agent-teams to score 100.

**Sources — cache-first loading:**

Local cache: `~/.claude/docs/claude-code/` — read files from here first using the Read tool.
If a cached file is missing, fetch from the fallback URL instead.
If `~/.claude/docs/claude-code/.last-sync` is older than 14 days, warn: "Docs cache is stale. Run `bash scripts/sync-docs.sh` to refresh."
If no cache exists at all, fetch all URLs below directly.

Extensibility:

- `features-overview.md` — <https://code.claude.com/docs/en/features-overview.md>
- `skills.md` — <https://code.claude.com/docs/en/skills.md>
- `sub-agents.md` — <https://code.claude.com/docs/en/sub-agents.md>
- `output-styles.md` — <https://code.claude.com/docs/en/output-styles.md>

Memory & Rules:

- `memory.md` — <https://code.claude.com/docs/en/memory.md>

Configuration:

- `settings.md` — <https://code.claude.com/docs/en/settings.md>
- `permissions.md` — <https://code.claude.com/docs/en/permissions.md>

Automation:

- `hooks-guide.md` — <https://code.claude.com/docs/en/hooks-guide.md>
- `hooks.md` — <https://code.claude.com/docs/en/hooks.md>
- `scheduled-tasks.md` — <https://code.claude.com/docs/en/scheduled-tasks.md>

Distribution:

- `plugins.md` — <https://code.claude.com/docs/en/plugins.md>
- `mcp.md` — <https://code.claude.com/docs/en/mcp.md>

Coordination:

- `agent-teams.md` — <https://code.claude.com/docs/en/agent-teams.md>

Best Practices:

- `skill-creation-guide.md` — <https://www.notion.so/Skill-Claude-BestPractice-31cff5ab8d4680429ecbc56504c6293c>

---

## Scoring

Two scores are produced: **Analysis Quality** (how rigorous was this analysis) and **Project Coverage** (how well the project uses Claude Code features).

### Analysis Quality (100 points)

| Criterion | Weight | Min |
| --- | --- | --- |
| Source coverage | 15 | 10 |
| Context verification | 15 | 10 |
| Gap analysis depth | 15 | 10 |
| Decision matrix accuracy | 15 | 10 |
| Traceability | 15 | — |
| Actionability | 15 | — |
| Prioritization quality | 10 | — |

Grades: A (90-100), B (70-89), C (50-69), D (30-49), F (0-29).

Score breakdown:

- **Source coverage 15/15:** All 14 sources read, key concepts extracted, no source skipped
- **10/15:** ≥12 sources, minor gaps. **5/15:** <10 sources or superficial extraction
- **Context verification 15/15:** All dirs/files/configs verified via tool output, zero assumptions
- **10/15:** Most verified, 1-2 assumptions noted. **5/15:** Multiple unverified claims
- **Gap analysis depth 15/15:** Every source checked against project, evidence-linked, false negatives caught
- **10/15:** Most sources checked, some shallow. **5/15:** Surface-level comparison only
- **Decision matrix accuracy 15/15:** Every config correctly classified, misplacements caught and flagged
- **10/15:** Matrix applied but 1-2 items unchecked. **5/15:** Matrix not systematically applied
- **Traceability 15/15:** Every recommendation chains: Source → Gap → Opportunity → Recommendation
- **10/15:** Most chain, some orphaned. **5/15:** Recommendations without clear source linkage
- **Actionability 15/15:** Every recommendation has specific files, commands, or config changes
- **10/15:** Mostly concrete, some vague. **5/15:** Generic suggestions without file paths
- **Prioritization quality 10/10:** Impact×Effort scored, quick wins separated, dependencies mapped
- **7/10:** Scored but dependencies unclear. **3/10:** Subjective ranking without criteria

Critical minimum thresholds — any criterion below its min → must fix before final score:

| Criterion | Min |
| --- | --- |
| Source coverage | 10/15 |
| Context verification | 10/15 |
| Gap analysis depth | 10/15 |
| Decision matrix accuracy | 10/15 |

### Project Coverage (100 points)

Measures how well the project adopts Claude Code features **relative to what's applicable**. A project only loses points for features it should use but doesn't — never for features that don't apply.

**Step 1 — Relevance Assessment:** For each feature category, determine applicability:

| Category | Applicable When | Not Applicable When |
| --- | --- | --- |
| CLAUDE.md | Always | — |
| `.claude/rules/` | Project has path-specific conventions | Single-purpose project, no path variance |
| Skills | Repeatable workflows exist | No repeatable workflows |
| Subagents | Tasks benefit from delegation | Simple project, no delegation needs |
| Output styles | Consistent tone/format needed | Default output sufficient |
| Hooks | Deterministic automation needed | No automation benefits |
| Permissions | Security-sensitive operations | Personal project, all tools trusted |
| Settings | Custom env vars or config needed | Defaults work fine |
| Scheduled tasks | Recurring monitoring needed | No recurring needs |
| Plugins | Distribution to others needed | Personal/single-project use |
| MCP | External tool integration needed | No external tools |
| Agent teams | Complex parallel coordination needed | Sequential or simple tasks |

**Step 2 — Score applicable features only:**

For each applicable category, score adoption (0-3):

- **3 — Fully adopted:** Feature used correctly, follows best practices, no gaps
- **2 — Partially adopted:** Feature used but with gaps or misconfigurations
- **1 — Minimal:** Feature exists but underutilized or poorly configured
- **0 — Missing:** Applicable feature not used at all

**Step 3 — Calculate:**

```text
Project Coverage = (sum of scores / (applicable categories × 3)) × 100
```

Example: 8 applicable categories, scores sum to 22 → 22/24 × 100 = 92/100

**Step 4 — Output format:**

```markdown
| Category | Applicable? | Score | Evidence |
| --- | --- | --- | --- |
| CLAUDE.md | ✅ | 3/3 | Well-structured, <200 lines, imports used |
| .claude/rules/ | ✅ | 2/3 | Exists but missing path for X |
| Skills | ✅ | 3/3 | Proper frontmatter, descriptions trigger-complete |
| Subagents | ❌ N/A | — | No delegation needs |
| ... | ... | ... | ... |

Project Coverage: XX/100
```

Grades: A (90-100), B (70-89), C (50-69), D (30-49), F (0-29). Target: **100/100** (all applicable features fully adopted).

---

## Thinking Process (follow in order)

**Step 1 — Comprehend Sources**
For each source, extract: core concept, key capabilities, and intended use cases.

Checklist:

- [ ] features-overview.md — decision matrix, feature comparison, context costs
- [ ] skills.md — frontmatter fields, substitutions, bundled skills, `context: fork`
- [ ] sub-agents.md — configuration, tools, memory, hooks, isolation
- [ ] output-styles.md — frontmatter, `keep-coding-instructions`, built-in styles
- [ ] memory.md — CLAUDE.md scoping, `.claude/rules/`, `@import`, auto memory, `claudeMdExcludes`
- [ ] settings.md — settings hierarchy, all fields, environment variables
- [ ] permissions.md — allow/deny/ask rules, tool-specific syntax, managed settings
- [ ] hooks-guide.md — hook types, lifecycle events, patterns
- [ ] hooks.md — all event schemas, input/output formats, exit codes
- [ ] scheduled-tasks.md — `/loop`, cron scheduling
- [ ] plugins.md — plugin manifest, packaging, distribution, marketplaces
- [ ] mcp.md — MCP server config, tool search, scope hierarchy
- [ ] agent-teams.md — team coordination, shared tasks, messaging
- [ ] Notion BestPractice — 5 golden rules, skill brief template, anti-patterns

---

**Step 2 — Audit Project Structure (carefully)**
Do NOT assume or infer structure. Verify everything.

Checklist:

- [ ] Read CLAUDE.md — architecture, conventions, declared constraints
- [ ] Verify top-level directory structure via listing
- [ ] Confirm tech stack from package.json / config files (not assumption)
- [ ] Locate and review existing scripts, hooks, automation files
- [ ] Check `.claude/settings.json` — existing hooks, permissions, env vars
- [ ] Check for `.claude/rules/` directory — path-specific rules
- [ ] Check for CI/CD config files (.github/, Jenkinsfile, etc.)
- [ ] Note anything unconfirmed as [UNVERIFIED]

---

**Step 3 — Identify Confirmed Context**
Before gap analysis, explicitly state only what is verified:

Checklist:

- [ ] Tech stack confirmed (language, framework, runtime versions)
- [ ] Project structure mapped (key directories and their roles)
- [ ] Existing workflows identified (scripts, hooks, CI/CD)
- [ ] Known pain points captured (from CLAUDE.md, README, or comments)
- [ ] All [UNVERIFIED] items listed with reason

---

**Quality Gate 1 — Context Completeness**
Do NOT proceed to gap analysis until all checks pass:

| Check | Pass Criteria |
| --- | --- |
| Sources fetched | ≥12 of 14 sources successfully read |
| CLAUDE.md read | Full file read (not skimmed) |
| Directory verified | `tree` or `ls` output captured |
| Settings checked | `.claude/settings.json` content confirmed |
| Unverified items | All listed with reason |

Gate: PASS ✅ or FAIL ❌ — resolve failures before continuing.

---

**Step 4 — Gap Analysis**
Compare each source's capabilities against confirmed context only.
Do NOT propose improvements based on assumed or unverified state.

Checklist:

- [ ] features-overview — is the right feature used for each concern? (CLAUDE.md vs rules vs skills)
- [ ] skills — frontmatter fields, substitutions, bundled skills adoption
- [ ] sub-agents — agent configuration, memory, hooks, isolation
- [ ] output-styles — styles coverage, `keep-coding-instructions` usage
- [ ] memory & rules — `.claude/rules/` for path-specific instructions, `@import` syntax, `CLAUDE.local.md`
- [ ] settings — env vars, config fields not yet used
- [ ] permissions — allow/deny/ask rules in settings.json
- [ ] hooks — all event types vs. currently configured hooks
- [ ] scheduled-tasks — recurring workflows that could use `/loop`
- [ ] plugins — packaging opportunity for distribution
- [ ] mcp — external tool integration gaps
- [ ] agent-teams — coordination needs (experimental — note stability)
- [ ] BestPractice — skill quality, description triggers

---

**Step 5 — Decision Matrix Validation**
For each existing configuration, verify it uses the right feature type:

| Content Type | Should Be | Not |
| --- | --- | --- |
| "Always do X" rules | CLAUDE.md | skill |
| Path-specific guidelines | `.claude/rules/` with `paths` | CLAUDE.md (bloat) |
| Reference docs loaded sometimes | skill | CLAUDE.md (always loaded) |
| Repeatable workflows | skill with `disable-model-invocation` | CLAUDE.md |
| Deterministic automation | hook | skill or agent |
| External service access | MCP | bash scripts |

Flag any misplacement found.

---

**Step 6 — Opportunity Mapping**
For each confirmed gap, define: what to change, add, or automate — and which files/areas it affects.

Checklist:

- [ ] Each opportunity linked to a specific confirmed gap
- [ ] Affected files or areas identified
- [ ] No opportunity from [UNVERIFIED] context without conditional flag

---

**Quality Gate 2 — Opportunity Validity**
Verify each opportunity before prioritizing:

| Check | Pass Criteria |
| --- | --- |
| Evidence-linked | Every opportunity traces to a specific gap |
| No duplicates | No two opportunities address the same gap |
| Feasibility | Affected files/paths confirmed to exist |
| Not already done | Feature not already implemented |
| Conditional flagged | [UNVERIFIED]-based opportunities marked |

Remove or merge opportunities that fail. Gate: PASS ✅ or FAIL ❌.

---

**Step 7 — Prioritize**
Score each opportunity: Impact (H/M/L) × Effort (H/M/L) → rank and justify.

Checklist:

- [ ] Every opportunity scored on Impact and Effort
- [ ] Final ranking justified with reasoning
- [ ] Quick wins (Low Effort / High Impact) highlighted separately

---

**Step 8 — Recommend**
Propose a sequenced adoption plan: what to implement first, why, and what it unlocks next.
Flag any recommendation that depends on [UNVERIFIED] context as conditional.

Checklist:

- [ ] Adoption sequence with clear ordering rationale
- [ ] Dependencies between recommendations explicit
- [ ] Conditional recommendations flagged
- [ ] Quick wins highlighted separately

---

**Step 9 — Verify & Score**
Validate the final output, then produce both scores.

Verification checklist:

- [ ] **Source coverage** — every source appears in gap analysis or has "no gap found" note
- [ ] **Traceability** — each recommendation chains: Source → Gap → Opportunity → Recommendation
- [ ] **No phantom features** — all referenced files/paths verified to exist (or marked "to create")
- [ ] **Decision matrix consistent** — no recommendation contradicts Step 5
- [ ] **No stale references** — URLs, file paths, config keys all current
- [ ] **Completeness** — no source silently dropped between steps

**9a — Analysis Quality Score** (mandatory output format):

```markdown
| Criterion | Score | Status | Notes |
| --- | --- | --- | --- |
| Source coverage | XX/15 | ✅ or ⚠️ CRITICAL (if <10) | ... |
| Context verification | XX/15 | ✅ or ⚠️ CRITICAL (if <10) | ... |
| Gap analysis depth | XX/15 | ✅ or ⚠️ CRITICAL (if <10) | ... |
| Decision matrix accuracy | XX/15 | ✅ or ⚠️ CRITICAL (if <10) | ... |
| Traceability | XX/15 | ✅ | ... |
| Actionability | XX/15 | ✅ | ... |
| Prioritization quality | XX/10 | ✅ | ... |

Analysis Quality: XX/100 (Grade X)
Critical check: PASS ✅ — all criteria above minimums
```

If FAIL → go back to the failing step and fix before re-scoring.

**9b — Project Coverage Score** (mandatory output format):

Run the Project Coverage scoring from the Scoring section:

1. Assess each category's applicability based on project context
2. Score each applicable category 0-3
3. Calculate percentage
4. Output the coverage table with evidence

```markdown
| Category | Applicable? | Score | Evidence |
| --- | --- | --- | --- |
| CLAUDE.md | ✅/❌ | X/3 | ... |
| ... | ... | ... | ... |

Project Coverage: XX/100 (Grade X)
Applicable: X/12 categories
```

If project coverage < target → list specific gaps that need fixing to reach target.

---

## Output

Per-source summary (Step 1), gap analysis table (Step 4), decision matrix validation (Step 5), top improvements with rationale, recommended adoption sequence with dependencies, and two scores (Step 9):

1. **Analysis Quality:** XX/100 — how thorough was this analysis
2. **Project Coverage:** XX/100 — how well the project uses applicable Claude Code features

When `$ARGUMENTS` includes "expect coverage project score 100/100": list every gap preventing 100/100 and provide concrete steps to close each one.
