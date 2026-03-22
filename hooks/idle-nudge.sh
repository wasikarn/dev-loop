#!/usr/bin/env bash
# Generic TeammateIdle nudge — keeps idle teammates on task.
# Config via env vars (set in settings.json command):
#   NUDGE_PATTERN      grep -qi pattern to match team names (e.g. "review-pr")
#   NUDGE_MSG          feedback message sent back to teammate
#   NUDGE_CHECK_TASKS  set to "1" to check ~/.claude/tasks/ for pending work first
#                      (omit or "0" for unconditional block)
# Exit 2 = block with nudge; exit 0 = allow.

set -euo pipefail

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_jq
INPUT=$(cat)

read -r TEAM_NAME < <(jq_fields '.team_name // ""')

# Require NUDGE_PATTERN — without it, this hook has no target and should be a no-op
[ -z "${NUDGE_PATTERN:-}" ] && exit 0

# Skip teams that don't match this nudge's pattern
if ! echo "$TEAM_NAME" | grep -qiE "$NUDGE_PATTERN"; then
  exit 0
fi

# Optionally check for pending tasks before nudging
if [ "${NUDGE_CHECK_TASKS:-0}" = "1" ]; then
  TASKS_DIR="$HOME/.claude/tasks/$TEAM_NAME"
  if [ -d "$TASKS_DIR" ]; then
    PENDING=$(find "$TASKS_DIR" -name "*.json" -exec grep -l '"status":"pending"' {} \; 2>/dev/null | head -1)
    if [ -n "$PENDING" ]; then
      echo "${NUDGE_MSG:-}" >&2
      exit 2
    fi
  fi
  exit 0
fi

# Unconditional nudge
echo "${NUDGE_MSG:-}" >&2
exit 2
