#!/bin/bash
# bash-blockers.sh — Block bash commands that have dedicated Claude tools

cmd=$(jq -re '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -z "$cmd" ] && exit 0

deny() {
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
    exit 0
}

# find/fd → Glob tool
echo "$cmd" | awk '/^[[:space:]]*(find|fd)[[:space:]]/{found=1} END{exit !found}' && \
    deny "Use the Glob tool instead of bash find/fd — faster, respects .gitignore, structured output."

# cat/head/tail → Read tool
is_cat=$(echo "$cmd" | awk '/^[[:space:]]*cat[[:space:]]+[^|>&]+$/{print 1}')
is_head=$(echo "$cmd" | awk '/^[[:space:]]*head[[:space:]]/{print 1}')
is_tail=$(echo "$cmd" | awk '/^[[:space:]]*tail[[:space:]]/{print 1}')
has_follow=$(echo "$cmd" | awk '/-f[[:space:]]|--follow/{print 1}')

if [ -n "$is_cat" ] || [ -n "$is_head" ] || ([ -n "$is_tail" ] && [ -z "$has_follow" ]); then
    deny "Use the Read tool instead of bash cat/head/tail — supports line offset, limit, and structured output."
fi
