#!/usr/bin/env bash
# subagent-start-context.sh — SubagentStart hook
# Injects session context for reviewer and build-phase agents at spawn time.
# Matcher: code-reviewer|test-quality-reviewer|migration-reviewer|api-contract-auditor|
#          falsification-agent|plan-challenger|comment-analyzer|code-simplifier

# NOTE: no set -euo pipefail — hook must exit 0 on all failures
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh" 2>/dev/null || true

INPUT=$(cat)
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // empty' 2>/dev/null)

# Only inject for known agents (fallback filter if matcher doesn't work)
case "$AGENT_NAME" in
  code-reviewer|test-quality-reviewer|migration-reviewer|api-contract-auditor|\
  falsification-agent|plan-challenger|comment-analyzer|code-simplifier) ;;
  *) exit 0 ;;
esac

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# ── tech stack detection (cached per project, 1hr TTL) ────────────────────────
STACK=""
if [ -f "$PROJECT_ROOT/package.json" ]; then
  CACHE_KEY=$(printf '%s' "$PROJECT_ROOT" | md5 2>/dev/null || printf '%s' "$PROJECT_ROOT" | md5sum 2>/dev/null | cut -d' ' -f1)
  CACHE_FILE="/tmp/devflow-stack-${CACHE_KEY}"

  # Use cache if fresh (< 1 hour)
  _mtime=$(stat -f%m "$CACHE_FILE" 2>/dev/null || stat -c%Y "$CACHE_FILE" 2>/dev/null || echo 0)
  _now=$(date +%s)
  if [ -f "$CACHE_FILE" ] && [ "$(( _now - _mtime ))" -lt 3600 ]; then
    STACK=$(cat "$CACHE_FILE")
  else
    FRAMEWORK=$(jq -r '
      [(.dependencies // {}), (.devDependencies // {})] | add // {} | keys |
      if any(. == "@adonisjs/core") then "AdonisJS"
      elif any(. == "@nestjs/core") then "NestJS"
      elif any(. == "next") then "Next.js"
      elif any(. == "react") then "React"
      else "Node.js" end
    ' "$PROJECT_ROOT/package.json" 2>/dev/null || echo "Node.js")

    TS=$(jq -r 'if (.dependencies // {} | has("typescript")) or (.devDependencies // {} | has("typescript")) or (.devDependencies // {} | has("@types/node")) then ", TypeScript" else "" end' "$PROJECT_ROOT/package.json" 2>/dev/null || echo "")

    PRISMA=$(jq -r 'if (.dependencies // {} | has("prisma")) or (.dependencies // {} | has("@prisma/client")) then ", Prisma" else "" end' "$PROJECT_ROOT/package.json" 2>/dev/null || echo "")

    STACK="Node.js / ${FRAMEWORK}${TS}${PRISMA}"
    printf '%s' "$STACK" > "$CACHE_FILE" 2>/dev/null || true
  fi
elif [ -f "$PROJECT_ROOT/go.mod" ]; then
  STACK="Go $(grep '^go ' "$PROJECT_ROOT/go.mod" 2>/dev/null | awk '{print $2}')"
elif [ -f "$PROJECT_ROOT/requirements.txt" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
  STACK="Python"
elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
  STACK="Rust"
fi

# ── recent git log (last 5 commits) ──────────────────────────────────────────
GIT_LOG=$(git log --oneline -5 2>/dev/null || echo "")

# ── project hard rules (first 60 lines if present) ───────────────────────────
HARD_RULES_PATH="$PROJECT_ROOT/.claude/skills/review-rules/hard-rules.md"
HARD_RULES_BLOCK=""
if [ -f "$HARD_RULES_PATH" ]; then
  HARD_RULES_CONTENT=$(awk 'NR<=60' "$HARD_RULES_PATH" 2>/dev/null || true)
  if [ -n "$HARD_RULES_CONTENT" ]; then
    HARD_RULES_BLOCK="
<project-hard-rules>
$HARD_RULES_CONTENT
</project-hard-rules>"
  fi
fi

cat <<EOF
<devflow-agent-context>
Project root: $PROJECT_ROOT
Git branch: $BRANCH${STACK:+
Tech stack: $STACK}${GIT_LOG:+
Recent commits:
$GIT_LOG}
</devflow-agent-context>${HARD_RULES_BLOCK}
EOF

exit 0
