---
paths:
  - "agents/**"
---

# Devflow Agent Conventions

Agents live at `agents/<name>.md` with YAML frontmatter. Distributed automatically via plugin.

**Required frontmatter fields (in order):** `name` · `description` · `tools` · `model` · `effort` · `color` · `disallowedTools` · `maxTurns` · `skills`

**Rules:**

- `disallowedTools: Edit, Write` on all read-only agents (reviewers, analyzers)
- `model: sonnet` for analysis agents · `model: haiku` for bootstrap/utility agents
- `effort: high` for deep analysis · `effort: low` for mechanical/fast tasks
- `skills:` preload `[review-conventions, review-rules]` for agents that review code
- `memory: user` only for agents that benefit from cross-session learning (e.g. code-reviewer)
- `description:` must include "proactively" if agent should auto-trigger
- Plugin limitation: `hooks`, `mcpServers`, `permissionMode` silently ignored when loaded from plugin

**Model/color conventions:**

| Role | Model | Color |
| --- | --- | --- |
| Deep analysis (reviewer, auditor) | sonnet | blue |
| Bootstrap/summarizer | haiku | green/cyan |
| Challenger/falsifier | sonnet | cyan/yellow |
| Specialist (errors, types) | sonnet | orange/pink |
