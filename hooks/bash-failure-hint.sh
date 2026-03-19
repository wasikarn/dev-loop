#!/usr/bin/env bash
# PostToolUseFailure hook — inject diagnostic context after Bash command failures.
# Reads error from hook payload and outputs additionalContext JSON.
# Non-blocking: Claude sees the context alongside the original error.

set -euo pipefail

command -v jq > /dev/null 2>&1 || exit 0

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
ERROR=$(echo "$INPUT" | jq -r '.error // empty' 2>/dev/null || true)
IS_INTERRUPT=$(echo "$INPUT" | jq -r '.is_interrupt // false' 2>/dev/null || true)

# Don't inject context for user-interrupted commands
if [ "$IS_INTERRUPT" = "true" ]; then
  exit 0
fi

# Build diagnostic hint based on error patterns
HINT=""

if echo "$ERROR" | grep -qi "command not found"; then
  # Try to extract the missing command name from error text
  # "sudo: foobar: command not found" → take second-to-last field before "not found"
  CMD_NAME=$(echo "$ERROR" | sed 's/: command not found.*//' | awk -F': ' '{print $NF}' 2>/dev/null || true)
  [ -z "$CMD_NAME" ] && CMD_NAME=$(echo "$COMMAND" | awk '{print $1}')
  HINT="Command '$CMD_NAME' not found. Check if it's installed (run: which $CMD_NAME) or use an alternative tool."
elif echo "$ERROR" | grep -qi "permission denied"; then
  HINT="Permission denied. Check file permissions (ls -la) or if sudo is needed."
elif echo "$ERROR" | grep -qi "no such file or directory"; then
  HINT="File or directory not found. Verify the path exists before retrying."
elif echo "$ERROR" | grep -qi "port.*already in use\|address already in use"; then
  HINT="Port already in use. Find and stop the process: lsof -ti :PORT | xargs kill"
elif echo "$COMMAND" | grep -qiE "^(npm|yarn|pnpm|bun) " && echo "$ERROR" | grep -qiE "error|failed|not found|ERR!"; then
  HINT="Package manager error. Try: remove node_modules and lock file, then reinstall."
elif echo "$ERROR" | grep -qi "syntax error"; then
  HINT="Shell syntax error in command. Check for unmatched quotes, brackets, or missing semicolons."
fi

if [ -n "$HINT" ]; then
  jq -n --arg hint "Diagnostic hint: $HINT" \
    '{"hookSpecificOutput": {"hookEventName": "PostToolUseFailure", "additionalContext": $hint}}'
fi

exit 0
