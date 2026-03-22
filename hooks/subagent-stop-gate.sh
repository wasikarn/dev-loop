#!/usr/bin/env bash
# SubagentStop gate — blocks review agents that finish without file:line evidence.
# Config via env vars:
#   GATE_PATTERN  grep -qiE pattern to match agent_type (e.g. "code-reviewer|silent-failure")
#   GATE_MSG      feedback message sent back when blocking
# Output: JSON decision block (SubagentStop protocol)

set -euo pipefail

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_jq
INPUT=$(cat)

IFS=$'\t' read -r AGENT_TYPE LAST_MSG < <(jq_fields '.agent_type // ""' '.last_assistant_message // ""')

# Fail-safe: empty GATE_PATTERN means no filtering — pass through
[ -z "${GATE_PATTERN:-}" ] && exit 0

# Skip agents that don't match this gate's pattern
if ! echo "$AGENT_TYPE" | grep -qiE "${GATE_PATTERN:-}"; then
  exit 0
fi

# Require at least one file:line reference
if ! has_evidence "$LAST_MSG"; then
  jq -n --arg reason "${GATE_MSG:-Your output must include file:line evidence. Re-examine the code and cite specific locations.}" \
    '{"decision": "block", "reason": $reason}'
  exit 0
fi

exit 0
