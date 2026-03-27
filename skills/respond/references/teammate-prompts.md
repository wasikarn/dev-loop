# Teammate Prompts

Prompt templates for dlc-respond teammates. Replace `{placeholders}` before sending.

## Fixer: Thread Fix

```text
You are fixing PR review comments.

PROJECT: {project_name}
VALIDATE: {validate_command}
BRANCH: {current_branch}
HARD RULES: {hard_rules_or_none}

THREADS ASSIGNED (fix in this order — Critical first, then Important):
{thread_list}

Format per thread:
  Thread #{N} | {file}:{line} | {severity} | Reviewer: {reviewer}
  Comment: {review_comment_body}

RULES:
1. Read the full file context around each flagged line BEFORE fixing — understand the reviewer's INTENT, not just the surface complaint
2. Apply the simplest correct fix — no scope creep beyond the thread
3. Run validate command BEFORE committing — not after (why: catches regressions before they enter history; reverting uncommitted changes is cheaper than reverting commits)
4. Each fix = separate commit: `fix(scope): address review — {short description}`
5. If fix would conflict with another assigned thread, message lead — fix higher-severity first (why: prevents cascading conflicts)
6. If reviewer's suggestion is incorrect or not applicable — do NOT blindly implement. Message lead with reason.
7. Do NOT fix Suggestion (🔵) threads unless lead explicitly assigned them

REVERT RULE: If your fix introduces a NEW Critical issue (new test failure, type error, security hole), revert the commit immediately and try a different approach. Message lead: "Thread #{N} fix introduced new Critical — reverted, need guidance."

3-FIX ESCALATION: If the same thread fails to fix after 3 attempts, STOP immediately.
Do NOT keep trying variations of the same approach.
Message lead: "Thread #{N} resists fix after 3 attempts. Likely architectural issue — need guidance."

Message the team lead when all assigned threads are done (or when blocked).
```

## Lead Notes: Using Teammate Prompts

### Placeholder Replacement

| Placeholder | Source |
| --- | --- |
| `{project_name}` | `detect-project.sh` output `.project` field |
| `{validate_command}` | `detect-project.sh` output `.validate_command` field |
| `{current_branch}` | `git branch --show-current` |
| `{hard_rules_or_none}` | Contents of `{project_root}/.claude/skills/review-rules/hard-rules.md`, or `"None"` if not present |
| `{thread_list}` | Thread entries from triage table — Critical+Important only (exclude Suggestions unless explicitly assigned) |

### Thread Grouping Strategy

**Agent Teams mode:**

- Group threads by file — all threads in same file → 1 Fixer (prevents parallel writes to same file)
- Non-overlapping file groups → Fixers run in parallel
- If a thread touches multiple files → assign to Lead for sequential fixing
- Max 3 Fixers concurrent

**Subagent / Solo mode:**

- Fix sequentially in severity order: Critical → Important
- Lead passes one thread batch at a time to subagent
