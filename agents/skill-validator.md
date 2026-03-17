---
name: skill-validator
description: "Validates SKILL.md files against best practices. Use proactively after creating or editing a skill, or when asked to validate a skill."
tools: Read, Grep, Glob, Bash
model: sonnet
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

## Output Format

Report findings organized as:

- **Pass**: criteria met
- **Fail**: criteria violated — include what's wrong and how to fix
- **Warning**: not violated but could be improved

End with a score: `X/Y criteria passed` and top 3 recommended fixes.
