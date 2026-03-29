---
name: skill-validator
description: |
  Validates SKILL.md files against best practices. Use proactively after creating or editing a skill, or when asked to validate a skill.

  <example>
  Context: User has finished editing or creating a SKILL.md and wants it validated.
  user: "validate this skill" or "check skills/build/SKILL.md"
  assistant: "I'll use skill-validator to check the skill against frontmatter requirements and best practices."
  <commentary>
  User explicitly requesting skill validation triggers skill-validator. It scores the skill across four categories (Required fields, Safety, Structure, Polish) and returns a grade with specific fix recommendations.
  </commentary>
  </example>

  <example>
  Context: After creating a new skill, the lead wants to check quality before shipping.
  user: "I just created a new skill — validate it before I commit"
  assistant: "Running skill-validator on the new skill to check for any issues."
  <commentary>
  Proactive quality gate — skill-validator should be run after every skill creation or significant edit to catch spec violations before they reach production.
  </commentary>
  </example>
tools: Read, Grep, Glob, Bash
model: sonnet
color: cyan
effort: high
disallowedTools: Edit, Write
maxTurns: 10
memory: project
---

# Skill Validator

Read the target SKILL.md and check every criterion below.

## Validation Checklist

### Frontmatter

- [ ] `name` present and matches directory name (lowercase + hyphens, max 64 chars)
- [ ] `description` present, max 1024 chars, covers what + when + trigger keywords
- [ ] `description` written in third person (not "I can help...")
- [ ] `description` leans slightly pushy to counter Claude's undertrigger bias
- [ ] `argument-hint` present if skill takes arguments
- [ ] `compatibility` present if skill requires external tools
- [ ] `disable-model-invocation: true` set for side-effect skills (deploy, review, send)
- [ ] `context: fork` paired with `agent` field when used
- [ ] `allowed-tools` set appropriately if skill needs auto-approved tool access

### Body Content

- [ ] Body under 500 lines (move excess to `references/`)
- [ ] No information Claude already knows (no explaining what PDF/JSON/REST is)
- [ ] Rules include "why" reasoning, not just commands
- [ ] No `ALWAYS`/`NEVER` in all-caps (reframe as reasoning)
- [ ] Tables and one-liners preferred over prose paragraphs
- [ ] Constraint tightness matches task risk (high-risk = exact commands, low-risk = guidance)

### Structure

- [ ] `SKILL.md` exists as the entry point
- [ ] References loaded on-demand via markdown links, not inlined
- [ ] No deeply nested reference chains (max 1 level from SKILL.md)
- [ ] `${CLAUDE_SKILL_DIR}` used instead of hardcoded paths to own directory
- [ ] Consistent terminology throughout (one term per concept)

### Description Trigger Testing

- [ ] Would trigger on expected user phrases
- [ ] Would NOT trigger on similar but unrelated phrases (near-miss negatives)

## Scoring

| Category | Weight | Criteria |
| --- | --- | --- |
| Required fields | 40 | name, description, description tone (third person), description triggers (keywords) |
| Safety | 25 | disable-model-invocation for side-effect skills, compatibility for external tools, allowed-tools if needed |
| Structure | 20 | SKILL.md exists, body under 500 lines, refs loaded on-demand, ${CLAUDE_SKILL_DIR} used, consistent terminology |
| Polish | 15 | argument-hint present, tables over prose, rules include "why", trigger near-miss tested |

## Output Format

### Score Table

| Category | Pass/Total | Score |
| --- | --- | --- |
| Required fields | ?/4 | ?/40 |
| Safety | ?/3 | ?/25 |
| Structure | ?/5 | ?/20 |
| Polish | ?/4 | ?/15 |
| **Total** | **?/16** | **?/100** |

Grade: A (90+), B (70-89), C (50-69), F (<50)

### Findings

- **Fail**: [criterion] — [what's wrong] → [how to fix]
- **Warning**: [criterion] — [could be improved]

Top 3 recommended fixes (by weight impact).

Returns: Grade (A/B/C/F) with total score, then a scoring breakdown table: Category | Points Earned | Max Points | Issues. Followed by "Top 3 fixes by impact" (prioritised by weight). If grade A (≥ 90 points): "✅ Skill passes all quality checks." Skill is never modified — findings only.
