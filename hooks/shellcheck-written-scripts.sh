#!/usr/bin/env bash
# PostToolUse(Write) hook — runs shellcheck on written .sh files
# Runs shellcheck on .sh files that Claude creates/writes.
# Returns additionalContext so Claude sees warnings immediately.

set -euo pipefail

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_jq
command -v shellcheck > /dev/null 2>&1 || exit 0

INPUT=$(cat)

read -r FILE_PATH < <(jq_fields '.tool_input.file_path // ""')

# Only check shell scripts
case "$FILE_PATH" in
  *.sh|*.bash) ;;
  *) exit 0 ;;
esac

# Skip if file doesn't exist (shouldn't happen in PostToolUse, but safety)
[ -f "$FILE_PATH" ] || exit 0

# Run shellcheck — -f gcc gives compact parseable output
SC_OUTPUT=$(shellcheck -f gcc "$FILE_PATH" 2>&1) || :

if [ -z "$SC_OUTPUT" ]; then
  exit 0
fi

ERRORS=$(echo "$SC_OUTPUT" | grep -c ':.*error:' || :)
WARNINGS=$(echo "$SC_OUTPUT" | grep -c ':.*warning:' || :)
SC_TRUNCATED=$(echo "$SC_OUTPUT" | head -30)

jq -nc --arg ctx "shellcheck found ${ERRORS} error(s), ${WARNINGS} warning(s) in ${FILE_PATH}:
${SC_TRUNCATED}" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'

exit 0
