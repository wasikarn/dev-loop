---
name: dlc-respond
description: "Respond to PR review comments — reads all open GitHub review threads, fixes each issue, commits, replies to threads, and re-requests review. Use when: you received PR review feedback and need to address reviewer comments. Triggers: respond to review, fix review comments, resolve review threads, address PR feedback, reply to reviewer, /dlc-respond."
argument-hint: "[pr-number] [jira-key?]"
compatibility: "Requires gh CLI, git, CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (degrades gracefully without)"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *)
---

# Team Respond Review — Address PR Review Comments

Invoke as `/dlc-respond [pr-number] [jira-key?]`

---

**PR:** #$0 | **Today:** !`date +%Y-%m-%d`
**Git branch:** !`git branch --show-current`
**Project:** !`bash "${CLAUDE_SKILL_DIR}/../../scripts/detect-project.sh" 2>/dev/null`
**Open threads:** !`gh pr view $0 --json reviews,comments --jq '[.reviews[] | select(.state == "CHANGES_REQUESTED")] | length' 2>/dev/null`
**PR diff stat:** !`gh pr diff $0 --stat 2>/dev/null | tail -5`

**Args:** `$0`=PR# (required) · `$1`=Jira key (optional, for AC context)

Read CLAUDE.md first — auto-loaded, contains project patterns and conventions.

---

## Prerequisite Check

Verify agent teams availability:

```text
If TeamCreate tool is not available → check graceful degradation:
- If Task (subagent) tool is available → "Agent Teams not enabled. Running in subagent mode."
- If neither → "Running in solo mode. Lead handles all fixes sequentially."
```

---

## Phase 0: Triage (Lead Only)

### Step 1: Detect Project

Use the `Project` JSON from the header. Load project-specific Hard Rules from the corresponding `tathep-*-review-pr` skill if `review_skill` is non-empty.

### Step 2: Fetch All Open Threads

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments \
  --jq '[.[] | {id, path, line, body, user: .user.login, created_at, html_url}]'
```

Also fetch review-level comments:

```bash
gh pr view {pr} --json reviews --jq '.reviews[] | select(.state == "CHANGES_REQUESTED") | {id, author: .author.login, body, submittedAt}'
```

### Step 3: Classify Threads

Group into a triage table:

```markdown
## Thread Triage

| # | File | Line | Reviewer | Severity | Issue Summary | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | src/foo.ts | 42 | BIG-TATHEP | 🔴 Critical | ... | Open |
| 2 | src/bar.ts | 15 | ... | 🟡 Important | ... | Open |
```

**Severity inference:**

- 🔴 Critical: Hard Rule violation, security issue, data loss risk, incorrect business logic
- 🟡 Important: Code quality, maintainability, incomplete fix
- 🔵 Suggestion: Style, naming, optional improvement

**GATE:** Triage table complete, count confirmed → present to user and proceed.

---

## Phase 1: Fix Threads

### Iteration Strategy

Fix in severity order: 🔴 Critical first → 🟡 Important → 🔵 Suggestion.

**Agent Teams mode:** Create 1 Fixer teammate per non-overlapping file group.
**Solo/subagent mode:** Lead fixes sequentially.

### Fixer Instructions

For each thread:

1. Read the full file context around the flagged line
2. Understand the reviewer's intent — do not just satisfy the surface complaint
3. Apply the simplest correct fix — no scope creep beyond the thread
4. Run validate command after each fix: `{validate_command}`
5. Commit: `fix(scope): address review comment — {short description}`

**If fix would conflict with another thread:** message lead, fix the higher-severity one first.

**If reviewer's suggestion is incorrect or not applicable:**

- Do NOT blindly implement it
- Document the reason in the reply: "ไม่ได้ implement เพราะ {reason}"

**GATE:** All Critical + Important threads fixed + validate passes → Phase 2.

---

## Phase 2: Reply to Threads

For each fixed thread, post a reply comment on GitHub:

```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -f body="{reply_body}"
```

**Reply format (Thai):**

```text
แก้ไขแล้วครับ — {commit_sha_short}: {one-line description of what changed}
```

**For declined suggestions:**

```text
ขอบคุณสำหรับ suggestion ครับ — ยังไม่ได้แก้เพราะ {reason}
```

**For informational 🔵 threads:**

```text
รับทราบครับ — {acknowledge or note for future}
```

After replying to all threads, post a summary review comment:

```bash
gh pr review {pr} --comment --body "{summary}"
```

**Summary format:**

```markdown
## ตอบ Review Comments ครับ

แก้ไขแล้ว {N} threads:
- 🔴 {count} Critical issues fixed
- 🟡 {count} Important issues fixed
- 🔵 {count} Suggestions acknowledged

Commits: {list of fix commit shas}

**Validate:** {validate_command} ✅
```

**GATE:** All threads replied → Phase 3.

---

## Phase 3: Re-request Review (Lead Only)

```bash
gh pr edit {pr} --add-reviewer {original_reviewer_login}
```

Or if reviewer already assigned:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/requested_reviewers \
  -X POST -f reviewers[]={reviewer_login}
```

### Final Summary

```markdown
## Respond Review Complete

**PR:** #{pr}
**Threads addressed:** {total}
**Commits made:** {count}
**Validate:** ✅ passes
**Re-review requested:** {reviewer_login}
```

---

## Constraints

- **Fix scope = thread scope only** — no refactors beyond what was requested
- **One commit per thread group** (same file/area can share a commit)
- **Validate must pass after every commit** — do not batch fixes without validating
- **Never silently skip a Critical thread** — if unfixable, escalate to user
- **Max 3 fix attempts per thread** — if still failing after 3 tries, escalate to user
- **READ the code before fixing** — do not guess at the reviewer's intent
