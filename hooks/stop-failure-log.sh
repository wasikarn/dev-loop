#!/usr/bin/env bash
# StopFailure hook — log API errors to session log.
# Non-blocking: exit code and output are ignored by Claude Code.
# Env vars:
#   LOG=1     enable session log writing to $HOME/.claude/session-logs/ (opt-in)
#   NOTIFY=1  enable macOS notification (personal use, macOS only)

command -v jq > /dev/null 2>&1 || exit 0

INPUT=$(cat)

ERROR=$(echo "$INPUT" | jq -r '.error // "unknown"' 2>/dev/null || true)
ERROR_DETAILS=$(echo "$INPUT" | jq -r '.error_details // ""' 2>/dev/null || true)

# Log to session log (opt-in via LOG=1)
if [ "${LOG:-0}" = "1" ]; then
  LOG_DIR="$HOME/.claude/session-logs"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
  {
    echo "---"
    echo "time: $(date '+%H:%M:%S')"
    echo "event: StopFailure"
    echo "error: $ERROR"
    [ -n "$ERROR_DETAILS" ] && echo "details: $ERROR_DETAILS"
  } >> "$LOG_FILE"
fi

# Sanitize for AppleScript string interpolation (strip double-quotes and backslashes)
SAFE_ERROR=$(echo "$ERROR" | tr -d '"\\' | tr -d '\n')

# macOS notification (opt-in via NOTIFY=1)
if [ "${NOTIFY:-0}" = "1" ] && command -v osascript > /dev/null 2>&1; then
  osascript -e "display notification \"Session stopped: $SAFE_ERROR\" with title \"Claude Code\" subtitle \"API Error\"" 2>/dev/null || true
fi

exit 0
