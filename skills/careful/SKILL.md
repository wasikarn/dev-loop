---
name: careful
description: >
  Activate safe-mode for the current session. Blocks destructive bash commands:
  rm -rf, DROP TABLE, git push --force, truncate, git reset --hard on committed work.
  Use when working near production data, shared branches, or irreversible operations.
  Triggers: /careful, "be careful", "safe mode", "don't delete anything"
disable-model-invocation: true
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: |
            INPUT=$(cat)
            CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
            if echo "$CMD" | grep -qiE 'rm\s+-rf|DROP\s+TABLE|push\s+--force|truncate\s+|reset\s+--hard'; then
              echo '{"decision":"block","reason":"🛑 /careful is active — destructive command blocked. Remove /careful or confirm intent explicitly."}'
            fi
---

# /careful — Safe Mode Activated

Safe mode is now active for this session.

**Blocked commands:**

- `rm -rf` — recursive delete
- `DROP TABLE` — database destructive DDL
- `git push --force` — force push (overwrites remote history)
- `truncate` — wipe table data
- `git reset --hard` (on committed work)

To proceed with a blocked command, explicitly confirm: "I understand the risk, run `<command>` anyway."

To deactivate: start a new session or use `/uncareful` (if installed).

## Gotchas

- **Session-scoped only** — the hook activates for this session only; start a new session to deactivate.
- **Pattern matching is regex-based** — commands with unusual spacing or quoting may bypass the block.
  Use `/careful` as a reminder layer, not a security boundary.
- **`disable-model-invocation: true`** — this skill produces no model output; it only registers the hook.
  Claude will not summarize or explain the activation unless the hook itself returns a message.
