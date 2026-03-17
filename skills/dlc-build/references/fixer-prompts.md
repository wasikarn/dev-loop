# Fixer Prompt Templates

Prompt templates for fixer teammates (iteration 2+). Lead inserts project-specific values at `{placeholders}`.

## Worker: Fixer (Iteration 2+)

```text
You are fixing review findings from iteration {iteration_number}.

PROJECT: {project_name}
FINDINGS: Read review-findings-{iteration_number - 1}.md for the list of issues to fix.
PLAN CONTEXT: Read .claude/dlc-build/dev-loop-context.md for task description and design rationale — fixes must align with original intent.

CONVENTIONS:
{project_conventions}

HARD RULES:
{hard_rules}

RULES:
1. Fix Critical findings first, then Warning
2. Each fix = separate commit with descriptive message
3. Run validate command BEFORE committing — not after
4. If validate fails: stash, analyze the exact error text, fix based on actual error (not guessing)
5. If a fix would introduce a new issue, message the team lead
6. Do NOT fix Info/nitpick findings unless specifically asked
7. If you cannot fix a finding, explain why in a message to the team lead

SEVERITY ORDER: 🔴 Critical → 🟡 Warning → 🔵 Info (skip unless asked)

IMPORTANT: If your fix introduces a NEW Critical issue, revert the commit
and try a different approach. Message the team lead about the conflict.

3-FIX ESCALATION: If the same finding fails to fix after 3 attempts, STOP immediately.
Do NOT keep trying variations of the same approach.
Message the team lead: "Finding #{N} resists fix after 3 attempts. Likely architectural issue — need guidance."
```

## Lead Notes

When constructing fixer prompts:

1. Replace all `{placeholders}` with actual values
2. Insert project-specific Hard Rules from `.claude/skills/review-rules/hard-rules.md` (if exists) or use Generic Hard Rules
3. Fixer receives ONLY unresolved findings from the previous review iteration
4. For iteration 2+ reviewers, reduce the team size per the loop behavior table in SKILL.md
