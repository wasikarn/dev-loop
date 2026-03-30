---
paths:
  - "skills/review/**"
  - "skills/review-*/**"
---

# Devflow Review Skills

`review` uses 3 Agent Teams teammates with adversarial debate.

- **Args:** `[pr-number] [jira-key?] [--quick?] [--full?] [--focused area?] [Author|Reviewer]`
- **Phases:** Worktree setup → Jira AC → 3 reviewers → debate → consolidation → action
- **Review modes:** --quick = fast SDK-only (no debate) · --full = force 3-reviewer Agent Teams · --focused [area] = spawn specialist only (errors/types/tests/api/migrations) · default = auto (SDK first, Agent Teams fallback)
- **Reviewer language:** Thai mixed with English technical terms
- **Shared conventions:** `skills/review-conventions/SKILL.md` — comment labels, dedup, strengths, PR size, reviewer focus areas
