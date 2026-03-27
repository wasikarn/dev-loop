#!/usr/bin/env bash
# safe-command-approver.sh — PreToolUse hook
# Auto-approves obviously-safe read-only commands to reduce permission friction.
# Strategy: allowlist-only. Unknown commands pass through — no Opus call for unknowns
# (avoids latency on every tool use). Add patterns to SAFE_PATTERNS as confidence grows.
# NOTE: no set -euo pipefail — hook must exit 0 on all failures

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_jq

INPUT=$(cat)
IFS=$'\t' read -r TOOL_NAME COMMAND < <(jq_fields '.tool_name' '.tool_input.command')

# Only intercept Bash tool calls
[ "$TOOL_NAME" = "Bash" ] || exit 0
[ -n "$COMMAND" ] || exit 0

# Safe read-only patterns — approved without Opus (instant, zero latency)
# Add patterns conservatively: only commands that are unambiguously read-only
# and have no destructive variants.
SAFE_PATTERNS=(
  '^git (status|log|diff|show|branch|remote|fetch|tag|describe|stash list)'
  '^gh (pr|issue|repo|run|release) (list|view|status|show|checks)'
  '^(cat|ls|pwd|echo|which|type|command -v|wc|grep|find|head|tail|sed|awk) '
  '^(curl|wget) .*(--silent|-s).*(GET|list|status)'
  '^(jq|yq|python3 -c|node -e) '
  '^bash scripts/(qa-check|artifact-dir|detect-project)\.sh'
  '^(shellcheck|markdownlint-cli2|npx markdownlint)'
  '^bats '
)

for pattern in "${SAFE_PATTERNS[@]}"; do
  if [[ $COMMAND =~ $pattern ]]; then
    jq -n '{"decision":"approve","reason":"safe-command-approver: read-only command on allowlist"}'
    exit 0
  fi
done

# Not on allowlist — pass through (Claude Code handles normally)
exit 0
