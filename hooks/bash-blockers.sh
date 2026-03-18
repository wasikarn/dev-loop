#!/bin/bash
# bash-blockers.sh — Block bash commands that have dedicated Claude tools

cmd=$(jq -re '.tool_input.command // empty' 2>/dev/null) || exit 0
[[ -z "$cmd" ]] && exit 0

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"
    exit 0
}

# find/fd → Glob tool
[[ "$cmd" =~ ^[[:space:]]*(find|fd)[[:space:]] ]] && \
    deny "Use the Glob tool instead of bash find/fd — faster, respects .gitignore, structured output."

# cat (no pipe/redirect) → Read tool
[[ "$cmd" =~ ^[[:space:]]*cat[[:space:]] ]] && [[ ! "$cmd" =~ [|>\&] ]] && \
    deny "Use the Read tool instead of bash cat/head/tail — supports line offset, limit, and structured output."

# head → Read tool
[[ "$cmd" =~ ^[[:space:]]*head[[:space:]] ]] && \
    deny "Use the Read tool instead of bash cat/head/tail — supports line offset, limit, and structured output."

# tail (without -f/--follow) → Read tool
[[ "$cmd" =~ ^[[:space:]]*tail[[:space:]] ]] && [[ ! "$cmd" =~ -(f[[:space:]]|-follow) ]] && \
    deny "Use the Read tool instead of bash cat/head/tail — supports line offset, limit, and structured output."
