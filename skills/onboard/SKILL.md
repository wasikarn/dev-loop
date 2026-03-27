---
name: dlc-onboard
description: "Bootstrap the current project into the dev-loop ecosystem — scaffold hard-rules.md and dlc-build artifact directories. Use once per new project before the first dlc-build or dlc-review invocation. Run this first when starting a new project, setting up dev-loop for the first time, or when hard-rules.md is missing. Triggers: dlc-onboard, onboard project, bootstrap dev-loop, setup dev-loop, first time setup, initialize dev-loop, scaffold hard rules, new project setup."
disable-model-invocation: true
context: fork
agent: project-onboarder
---

## Gotchas

- **Creates a `hard-rules.md` scaffold only** — the file is pre-populated with structure and placeholder examples, but the actual project-specific rules must be filled in manually. An empty scaffold has no effect on dlc-review or dlc-build; populate it before the first review run.
- **Does not install the plugin** — onboarding sets up per-project configuration (`.claude/skills/review-rules/`), not the plugin itself. Run `claude plugin install dev-loop` separately before invoking any dlc-* skill.
- **Run once per project, not per session** — running dlc-onboard again on an already-onboarded project will overwrite or re-scaffold existing files. Check for `.claude/skills/review-rules/hard-rules.md` before invoking to avoid clobbering custom rules.
- **Runs as an isolated subagent (`context: fork`)** — delegated entirely to the `project-onboarder` agent. The agent detects the project root from the working directory. Invoke from within the target project's root, not from the dev-loop plugin directory.
