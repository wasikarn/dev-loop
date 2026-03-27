---
name: dlc-metrics
description: "Run a retrospective report from anvil-metrics.jsonl — iteration counts, finding categories, recurrent issues, and improvement recommendations. Use when: reviewing dev-loop workflow patterns, identifying recurring issues, surfacing Hard Rule candidates, measuring team velocity, or analyzing why certain issues keep appearing across multiple builds. Triggers: dlc-metrics, metrics report, retrospective, show metrics, workflow analysis, iteration report, how many iterations, recurring findings, what keeps failing."
disable-model-invocation: true
context: fork
agent: metrics-analyst
---

## Gotchas

- **Requires `~/.claude/anvil-metrics.jsonl` to exist** — the file is created automatically by dlc-build and dlc-debug at Phase end. If no dlc-build or dlc-debug runs have completed, the file won't exist and the report will be empty (not an error). Run at least one full dlc-build session first.
- **Only covers dlc-build and dlc-debug runs** — ad-hoc coding sessions, manual fixes, and dlc-review-only workflows do not append to the metrics file. The report reflects structured dev-loop usage, not total Claude Code activity.
- **Runs as an isolated subagent (`context: fork`)** — delegated entirely to the `metrics-analyst` agent (Haiku). No lead context is available. The agent reads `~/.claude/anvil-metrics.jsonl` directly; ensure the path is accessible from the subagent's environment.
- **JSONL entries are append-only** — there is no deduplication. If a session crashes and is re-run, the same task may appear twice. Treat iteration counts as approximate, especially for sessions that were restarted.
