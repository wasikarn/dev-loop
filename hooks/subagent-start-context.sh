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

# ── tech stack detection (single-pass, ~1ms) ─────────────────────────────────
STACK=""
if [ -f "$PROJECT_ROOT/package.json" ]; then
  FRAMEWORK=$(python3 -c "
import json, sys
try:
  d = json.load(open('$PROJECT_ROOT/package.json'))
  deps = {**d.get('dependencies',{}), **d.get('devDependencies',{})}
  tags = []
  if 'next' in deps: tags.append('Next.js')
  elif 'react' in deps: tags.append('React')
  if 'typescript' in deps or '@types/node' in deps: tags.append('TypeScript')
  if 'nestjs' in deps or '@nestjs/core' in deps: tags.append('NestJS')
  if '@adonisjs/core' in deps: tags.append('AdonisJS')
  if 'prisma' in deps or '@prisma/client' in deps: tags.append('Prisma')
  print(', '.join(tags) if tags else 'Node.js')
except: print('Node.js')
" 2>/dev/null || echo "Node.js")
  STACK="Node.js / $FRAMEWORK"
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
<anvil-agent-context>
Project root: $PROJECT_ROOT
Git branch: $BRANCH${STACK:+
Tech stack: $STACK}${GIT_LOG:+
Recent commits:
$GIT_LOG}
</anvil-agent-context>${HARD_RULES_BLOCK}
EOF

exit 0
