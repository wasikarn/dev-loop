---
name: df-analyze
description: "Audit project against all official Claude Code features and score adoption coverage. Triggers: feature coverage, adoption score, feature audit, Claude features, feature adoption, check features. Reports used, unused, and partially-used features with recommendations."
effort: medium
---

# Analyze Claude Features

Read and analyze each documentation source below, then assess what can be concretely applied or improved in this project.

**Goal:** Score how well this project uses Claude Code features relative to what's applicable. 100/100 means all relevant features are properly adopted — not that every feature is used. A simple script repo shouldn't need agent-teams to score 100.

**Sources — fetch directly from URLs using WebFetch:**

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

Coordination:

- `agent-teams.md` — <https://code.claude.com/docs/en/agent-teams.md>

Best Practices:

- `skill-creation-guide.md` — Read `${CLAUDE_SKILL_DIR}/../../docs/references/skill-creation-guide.md`

---

## Scoring

Two scores: **Analysis Quality** (how rigorous was this analysis, 100 pts, 7 criteria) and **Project Coverage** (how well the project adopts applicable features, 100 pts, 0-3 per category).

See [references/quality-rubric.md](references/quality-rubric.md) for full rubric, critical minimums, applicability table, score formula, and output format templates.

---

## Thinking Process (follow in order)

**Step 1 — Comprehend Sources:** Extract core concept, capabilities, and use cases from each of the 13 sources.

**Step 2 — Audit Project Structure:** Read CLAUDE.md, verify directory structure, confirm tech stack, locate hooks/scripts/settings. Do NOT assume — mark unknowns as [UNVERIFIED].

**Step 3 — Identify Confirmed Context:** State only what is verified: tech stack, structure, workflows, pain points, and all [UNVERIFIED] items.

**Quality Gate 1 — Context Completeness:** ≥12/13 sources fetched, CLAUDE.md fully read, directory verified, settings checked, unverified items listed. PASS ✅ or FAIL ❌ — resolve before continuing.

**Step 4 — Gap Analysis:** Compare each source's capabilities against confirmed context only. No proposals from unverified state.

**Step 5 — Decision Matrix Validation:** For each existing configuration, verify it uses the right feature type (CLAUDE.md vs `.claude/rules/` vs skill vs hook). Flag misplacements.

| Content Type | Should Be | Not |
| --- | --- | --- |
| "Always do X" rules | CLAUDE.md | skill |
| Path-specific guidelines | `.claude/rules/` with `paths` | CLAUDE.md (bloat) |
| Reference docs loaded sometimes | skill | CLAUDE.md (always loaded) |
| Repeatable workflows | skill | CLAUDE.md |
| Deterministic automation | hook | skill or agent |

**Step 6 — Opportunity Mapping:** For each confirmed gap, define what to change/add/automate and which files are affected. No opportunities from [UNVERIFIED] context without conditional flag.

**Quality Gate 2 — Opportunity Validity:** Every opportunity evidence-linked, no duplicates, feasibility confirmed, not already done, conditional items flagged. PASS ✅ or FAIL ❌.

**Step 7 — Prioritize:** Score each opportunity: Impact (H/M/L) × Effort (H/M/L). Highlight quick wins (Low Effort / High Impact) separately.

**Step 8 — Recommend:** Sequenced adoption plan with ordering rationale, explicit dependencies, and conditional flags for [UNVERIFIED]-based items.

**Step 9 — Verify & Score:** Run verification checklist, then produce both scores using the mandatory output formats in [references/quality-rubric.md](references/quality-rubric.md).

See [references/analysis-checklist.md](references/analysis-checklist.md) for complete per-step checklists.

---

## Output

Per-source summary (Step 1), gap analysis (Step 4), decision matrix validation (Step 5), adoption sequence, and two scores (Step 9).

If `$ARGUMENTS` includes "expect coverage project score 100/100": list every gap preventing 100/100 with concrete steps.
