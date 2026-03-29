# systems-thinking skill

Deep Systems Thinking analysis using Causal Loop Diagrams for architecture decisions.

## Docs Index

| Reference | When to use |
| --- | --- |
| `SKILL.md` | Full workflow: 5 steps + output template |

## Skill Architecture

- `SKILL.md` — 5-step workflow: Map System → Find Feedback Loops → Predict Bottleneck Shifts → Critical Thinking → Find Leverage Points
- Output template with System Map, CLD notation, Health Assessment (4 dimensions scored 1-5)
- Key Principles section at end of SKILL.md is the concise cheat sheet

## Validate After Changes

```bash
# Lint
npx markdownlint-cli2 "skills/systems-thinking/**/*.md"

# Verify symlink
ls -la ~/.claude/skills/systems-thinking
```

## Gotchas

- No external tool dependencies — runs purely on Claude's reasoning
- Output template uses ASCII diagrams for CLD — Mermaid is an option but not required
- Key Principles section at the end is the "cheat sheet" — keep concise
- No `references/` directory — SKILL.md at 163 lines is self-contained; add one if the skill grows past ~250 lines
