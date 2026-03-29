---
name: onboard
description: "Bootstrap the current project into the devflow ecosystem — scaffold hard-rules.md and build artifact directories. Use once per new project before the first build or review invocation. Run this first when starting a new project, setting up devflow for the first time, or when hard-rules.md is missing. Triggers: onboard, onboard project, bootstrap devflow, setup devflow, first time setup, initialize devflow, scaffold hard rules, new project setup."
disable-model-invocation: true
context: fork
agent: project-onboarder
---

## What It Does

Bootstraps the current project into the devflow ecosystem:

1. **Detects** project root, framework, and directory structure
2. **Creates** `.claude/skills/review-rules/hard-rules.md` — pre-populated scaffold with structure and placeholder examples
3. **Creates** build artifact directories used by `/build` and `/debug`
4. **Reports** what was created and any manual steps needed

## Prerequisites

- Run from within the target project's root directory (not the devflow plugin directory)
- Plugin must already be installed: `claude plugin install devflow`
- Check for `.claude/skills/review-rules/hard-rules.md` before running — running twice overwrites existing rules

## Expected Output

```text
✅ Created: .claude/skills/review-rules/hard-rules.md
✅ Created: .claude/artifacts/ (build/debug artifact storage)
⚠️  Action needed: Populate hard-rules.md with project-specific rules before first /build or /review run
```

## Gotchas

- **Creates a `hard-rules.md` scaffold only** — the file is pre-populated with structure and placeholder examples, but the actual project-specific rules must be filled in manually. An empty scaffold has no effect on review or build; populate it before the first review run.
- **Does not install the plugin** — onboarding sets up per-project configuration (`.claude/skills/review-rules/`), not the plugin itself. Run `claude plugin install devflow` separately before invoking any devflow skill.
- **Run once per project, not per session** — running onboard again on an already-onboarded project will overwrite or re-scaffold existing files. Check for `.claude/skills/review-rules/hard-rules.md` before invoking to avoid clobbering custom rules.
- **Runs as an isolated subagent (`context: fork`)** — delegated entirely to the `project-onboarder` agent. The agent detects the project root from the working directory. Invoke from within the target project's root, not from the devflow plugin directory.
