#!/usr/bin/env bash
# subagent-start-context.sh — SubagentStart hook
# Injects session context for reviewer agents at spawn time.
# Runs for: code-reviewer, test-quality-reviewer, migration-reviewer, api-contract-auditor
# Matcher: "code-reviewer|test-quality-reviewer|migration-reviewer|api-contract-auditor"

# NOTE: no set -euo pipefail — hook must exit 0 on all failures
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh" 2>/dev/null || true

INPUT=$(cat)
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // empty' 2>/dev/null)

# Only inject for reviewer agents (fallback filter if matcher doesn't work)
case "$AGENT_NAME" in
  code-reviewer|test-quality-reviewer|migration-reviewer|api-contract-auditor) ;;
  *) exit 0 ;;
esac

# Output context injection — tells the agent what project it's in
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

cat <<EOF
<anvil-reviewer-context>
Project root: $PROJECT_ROOT
Git branch: $BRANCH
Skills preloaded: review-conventions, review-rules (see agent frontmatter)
</anvil-reviewer-context>
EOF

exit 0
