---
paths:
  - "hooks/**"
---

# Devflow Hook Conventions

Hooks live at `hooks/`. Registered in `hooks/hooks.json`, distributed automatically via plugin.

**Stdout rules (Claude Code validates strictly):**

- `PreToolUse` / `PostToolUse`: silent `exit 0` or `hookSpecificOutput` JSON with matching `hookEventName`
- `Stop`: silent `exit 0` or `{"ok": true/false}` — `hookSpecificOutput` is INVALID for Stop
- `allow()` = completely silent (`sys.exit(0)`) — never `print("{}")`
- Warnings/messages: use `inject_context()` for Pre/PostToolUse · use stderr for Stop

**Exit codes:**

| Code | Meaning |
| --- | --- |
| 0 | Allow (silent) |
| 2 | Block with message (stderr) |
| Other | Error (logged) |

**Async hooks:** use `async: true` in hooks.json for non-blocking operations (cleanup, logging).

**Matchers:** use `|` alternation for multi-agent matching (e.g. `code-reviewer|test-quality-reviewer`).

**Testing:** all hooks have bats tests at `tests/hooks/`. Run: `bash scripts/qa-check.sh`.

**Common lib:** `hooks/lib/common.sh` — source for shared utilities.
