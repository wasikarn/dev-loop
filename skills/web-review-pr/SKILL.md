---
name: web-review-pr
description: "PR review skill for tathep-website (Next.js 14 Pages Router + Chakra UI + React Query v3). Dispatches 7 parallel specialized agents, verifies Jira AC, then fixes issues (Author) or submits inline comments (Reviewer). Triggers: review PR, check PR, code review, /web-review-pr."
argument-hint: "[pr-number] [jira-key?] [Author|Reviewer]"
context: fork
disable-model-invocation: true
---

# PR Review — tathep-website

**PR:** #$0 | **Jira:** $1 | **Mode:** $2 (default: Author)
**Today:** !`date +%Y-%m-%d`
**Diff:** !`git diff develop...HEAD --stat 2>/dev/null | tail -10`

**Args:** `$0`=PR# (required) · `$1`=Jira key or Author/Reviewer · `$2`=Author/Reviewer
**Modes:** Author = fix code · Reviewer = comment only (in Thai)
**Role:** Tech Lead — review from an architectural, mentoring, and team-standards perspective

Read CLAUDE.md first — auto-loaded, contains full project patterns and conventions.
For 12-point checklist details → [references/checklist.md](references/checklist.md)

---

## Phase 1: Ticket Understanding 🟢 AUTO

If `$1` matches Jira key format (BEP-XXXX) →

- Fetch via MCP `jira_get_issue`: description, AC, subtasks, parent
- Summarize: **Problem** · **Value** · **Scope**
- Show **AC Checklist** (each AC as checkbox)

If no Jira → skip to Phase 3.

---

## Phase 2: AC Verification 🟡 REVIEW (only if Jira)

Map each AC to file(s) in `git diff develop...HEAD`:

- Code not found → 🔴 `[#1 Critical] AC not implemented`
- Code incomplete → 🔴 `[#1 Critical] AC partially implemented`
- No test → 🔴 `[#11 Critical] Missing test for AC`

---

## Phase 3: 12-Point Review 🟢 AUTO

**Scope:** `git diff develop...HEAD` — changed files only.

Dispatch 7 agents in **foreground parallel** (all READ-ONLY). Pass each agent: AC context from Phase 2 + checklist from [references/checklist.md](references/checklist.md).

| Agent | Aspects |
|-------|---------|
| `pr-review-toolkit:code-reviewer` | #1, #2, #3, #4, #7, #13 |
| `pr-review-toolkit:comment-analyzer` | #9 |
| `pr-review-toolkit:pr-test-analyzer` | #11 |
| `pr-review-toolkit:silent-failure-hunter` | #1, #12 |
| `pr-review-toolkit:type-design-analyzer` | #10 |
| `pr-review-toolkit:code-simplifier` | #4, #5, #6, #7, #8 |
| `feature-dev:code-reviewer` | #1, #4, #5, #6, #7, #8, #10 (confidence ≥80 only) |

`feature-dev:code-reviewer` applies TypeScript advanced type principles (generics, branded types, discriminated unions, type guards — NO `as any`) and Clean Code principles (SRP, early returns, naming intent, function size). Confidence scoring maps: 90–100 → 🔴, 80–89 → 🟡.

**⛔ CHECKPOINT** — collect ALL 7 results before proceeding. Do NOT fix until all complete.

| Agent | Result |
|-------|--------|
| code-reviewer | [ ] |
| comment-analyzer | [ ] |
| pr-test-analyzer | [ ] |
| silent-failure-hunter | [ ] |
| type-design-analyzer | [ ] |
| code-simplifier | [ ] |
| feature-dev:code-reviewer | [ ] |

Deduplicate → verify severity → remove false positives → proceed.

---

## Phase 4: By Mode

### Author Mode

1. Fix AC issues first (🔴 not implemented / partial)
2. Fix: 🔴 → 🟡 → 🔵
3. `npm run ts-check && npm run lint:fix && npm test` — if fails → fix and re-validate
4. Write `review-report.md`

### Reviewer Mode

As **Tech Lead**: focus on architecture, patterns, team standards, and mentoring — not syntax nitpicks.
For each issue, explain *why* it matters, not just *what* to change.

1. Show **AC Checklist** (✅/🔴) first (if Jira)
2. Collect all findings: file path + line number + comment body
3. Submit to GitHub (see below)
4. Show: AC Checklist · Strengths · all findings

**Comment language:** Thai mixed with English technical terms — as natural as possible, like a Thai dev writing to teammates on Slack/PR. Short, direct, no stiff formal phrases.
Examples: "อันนี้ควร extract เป็น hook แยกไว้ครับ", "ใช้ ROUTE_PATHS ด้วยนะ ไม่งั้น hardcode", "ตรงนี้ re-render ทุกครั้งเพราะ inline object ลอง useMemo ดูครับ"

#### Submit to GitHub

**Step 1 — get line numbers from diff:**

```bash
gh pr diff $0 --repo 100-Stars-Co/bluedragon-eye-website
```

Use the diff output to map each finding to the correct `path` and `line` (right-side line number in the file).

**Step 2 — submit all comments + decision in ONE call:**

If 🔴 exists → Request Changes:

```bash
gh api repos/100-Stars-Co/bluedragon-eye-website/pulls/$0/reviews \
  --method POST --input - <<'JSON'
{
  "body": "<overall summary in Thai>",
  "event": "REQUEST_CHANGES",
  "comments": [
    {"path": "src/modules/foo/foo.component.tsx", "line": 42, "side": "RIGHT", "body": "..."},
    {"path": "src/pages/bar.page.tsx", "line": 15, "side": "RIGHT", "body": "..."}
  ]
}
JSON
```

If no 🔴 → Approve:

```bash
gh pr review $0 --repo 100-Stars-Co/bluedragon-eye-website \
  --approve --body "<summary in Thai>"
```

---

## Constraints

- Investigate: read files before making claims. Never speculate about code you haven't opened.
- Flag changed files <80% coverage (🔴 Critical)
- #13 React/Next.js performance rules are embedded in checklist — see `references/checklist.md` #13 section
- Pages Router project — App Router patterns (RSC, Server Components, `React.cache()`) do NOT apply
- Reviewer comment style: see "Comment language" in Reviewer Mode above

## Success Criteria

- [ ] CHECKPOINT: all 7 agent results collected
- [ ] Phase 1-2 complete (if Jira provided)
- [ ] 🔴 issues: zero (Author) or documented (Reviewer)
- [ ] Author: `npm run ts-check && npm run lint:fix && npm test` pass
- [ ] Reviewer: review submitted
- [ ] AC Checklist shown in output (if Jira)
