#!/usr/bin/env bash
# Generic TaskCompleted gate — blocks tasks without file:line evidence.
# Config via env vars (set in settings.json command):
#   GATE_PATTERN  grep -qi pattern to match task names (e.g. "review|debate|finding")
#   GATE_MSG      feedback message sent back to teammate
# Exit 2 = block completion with feedback; exit 0 = allow.

set -euo pipefail

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_jq
INPUT=$(cat)

IFS=$'\t' read -r TASK_NAME TOOL_OUTPUT < <(jq_fields '.task_name // ""' '.tool_output // ""')

# Require GATE_PATTERN — without it, this hook has no target and should be a no-op
[ -z "${GATE_PATTERN:-}" ] && exit 0

# Skip tasks that don't match this gate's pattern
if ! echo "$TASK_NAME" | grep -qiE "$GATE_PATTERN"; then
  exit 0
fi

# Require at least one file:line reference in the output
if ! has_evidence "$TOOL_OUTPUT"; then
  echo "${GATE_MSG:-}" >&2
  exit 2
fi

exit 0
