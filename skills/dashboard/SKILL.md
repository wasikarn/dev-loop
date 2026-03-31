---
name: dashboard
description: "Show devflow metrics dashboard — session summary, anomaly alerts, reviewer calibration accuracy, and skill usage frequency. Use to check workflow health, spot regression trends, or identify coaching opportunities. Reads ~/.claude/devflow-metrics.jsonl."
argument-hint: ""
effort: low
allowed-tools: Bash
---

# Devflow Dashboard

Run the dashboard script and display the output:

```bash
bash "${CLAUDE_SKILL_DIR}/../../scripts/dashboard.sh"
```
