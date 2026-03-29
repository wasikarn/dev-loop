---
name: metrics
description: "Run a retrospective report from devflow-metrics.jsonl — iteration counts, finding categories, recurrent issues, and improvement recommendations. Use when: reviewing devflow workflow patterns, identifying recurring issues, surfacing Hard Rule candidates, measuring team velocity, or analyzing why certain issues keep appearing across multiple builds. Triggers: metrics, metrics report, retrospective, show metrics, workflow analysis, iteration report, how many iterations, recurring findings, what keeps failing."
disable-model-invocation: true
context: fork
agent: metrics-analyst
---

## What It Produces

The metrics-analyst agent reads `~/.claude/devflow-metrics.jsonl` and generates a structured report:

| Section | Contents |
| --- | --- |
| **Iteration Summary** | Total builds/debugs, average iterations per session, sessions that exceeded 2 iterations |
| **Finding Categories** | Breakdown of review findings by category (correctness, security, performance, DX, etc.) |
| **Recurrent Issues** | Patterns that appear across 3+ sessions — prime Hard Rule candidates |
| **Improvement Trend** | Whether iteration counts are decreasing over time (proxy for skill improvement) |
| **Hard Rule Candidates** | Auto-detected candidates written to `.claude/skills/review-rules/candidate-rules.md` for review via `/promote-hard-rule` |

## Minimum Data

Meaningful analysis requires at least **3 completed build or debug sessions**. With fewer entries:

- Recurrent issue detection has insufficient signal
- Hard Rule candidates will be empty or unreliable
- Improvement trend cannot be computed

Run `/build` or `/debug` sessions to populate `~/.claude/devflow-metrics.jsonl` before running metrics.

## Gotchas

- **Requires `~/.claude/devflow-metrics.jsonl` to exist** — the file is created automatically by build and debug at Phase end. If no build or debug runs have completed, the file won't exist and the report will be empty (not an error). Run at least one full build session first.
- **Only covers build and debug runs** — ad-hoc coding sessions, manual fixes, and review-only workflows do not append to the metrics file. The report reflects structured devflow usage, not total Claude Code activity.
- **Runs as an isolated subagent (`context: fork`)** — delegated entirely to the `metrics-analyst` agent (Haiku). No lead context is available. The agent reads `~/.claude/devflow-metrics.jsonl` directly; ensure the path is accessible from the subagent's environment.
- **JSONL entries are append-only** — there is no deduplication. If a session crashes and is re-run, the same task may appear twice. Treat iteration counts as approximate, especially for sessions that were restarted.
