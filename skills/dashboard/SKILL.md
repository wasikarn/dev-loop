---
name: dashboard
description: "Show devflow metrics dashboard — session summary, anomaly alerts, reviewer calibration accuracy, and skill usage frequency. Triggers: metrics, dashboard, session summary, workflow health, iteration count, regression trends."
argument-hint: ""
effort: low
allowed-tools: Bash
---

# Devflow Dashboard

Display a terminal-friendly metrics summary from all devflow tracking files with anomaly detection.

## Metrics Categories

| Category | Source | Description |
|----------|--------|-------------|
| **Session Summary** | `devflow-metrics.jsonl` | Total sessions, iteration counts, average findings per cycle |
| **Anomaly Alerts** | `devflow-metrics.jsonl` | Sessions with >3 iterations, >10 findings, or >30min cycle time |
| **Reviewer Calibration** | `devflow-metrics.jsonl` | False positive rate, severity distribution per reviewer |
| **Skill Usage** | `devflow-metrics.jsonl` | Most-used skills, frequency distribution |
| **Hard Rule Candidates** | `devflow-metrics.jsonl` | Patterns detected across sessions (potential Hard Rules) |

## Output Format

```text
📊 Devflow Dashboard — 2024-01-15

Sessions: 23 total
├─ Build: 15 sessions (avg 2.1 iterations)
├─ Review: 8 sessions (avg 1.3 iterations)
└─ Debug: 3 sessions (avg 1.0 iterations)

⚠️  Anomalies (3)
├─ Build session #42: 5 iterations (threshold: 3)
├─ Review session #38: 15 findings (threshold: 10)
└─ Debug session #45: 45min cycle (threshold: 30min)

🎯 Reviewer Calibration
├─ Correctness: 23% false positive rate
├─ Architecture: 12% false positive rate
└─ DX: 8% false positive rate

📈 Skill Usage (Top 5)
├─ build: 15 uses
├─ review: 8 uses
├─ debug: 3 uses
├─ respond: 2 uses
└─ generate-tests: 1 use

💡 Hard Rule Candidates (2)
├─ "All API tests must hit real database" (detected 3 times)
└─ "Never use not.toThrow() without assertion" (detected 5 times)
```

## Anomaly Thresholds

| Metric | Threshold | Reason |
|--------|-----------|--------|
| Iterations | >3 | Design problem or scope creep |
| Findings | >10 | Review scope too large |
| Cycle time | >30min | Potential stuck state |
| False positive rate | >25% | Reviewer needs calibration |

## Use Cases

- **Pre-standup check**: See what's been done overnight
- **Sprint retrospective**: Identify regression trends
- **Reviewer calibration**: Check false positive rates
- **Coaching opportunities**: Spot patterns in Hard Rule candidates

## Execution

Run the dashboard script:

```bash
bash "${CLAUDE_SKILL_DIR}/../../scripts/dashboard.sh"
```

## Gotchas

- Requires `~/.claude/devflow-metrics.jsonl` to exist (created by build/review/debug sessions)
- Shows last 30 days by default
- Anomaly thresholds are configurable in `~/.claude/devflow-config.json`

## Token Overview

If `devflow-metrics.jsonl` contains v1.1 entries:

| Period | Input | Output | Total |
|--------|-------|--------|-------|
| Today | 150,000 | 40,000 | 190,000 |
| This Week | 850,000 | 220,000 | 1,070,000 |
| All Time | 2,100,000 | 550,000 | 2,650,000 |

**Trend:** +15% from last week
