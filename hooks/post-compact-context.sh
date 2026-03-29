#!/usr/bin/env bash
# Re-inject critical context after context compaction.
# Output goes to stdout → injected into Claude's context.
# Keeps only dynamic state — conventions live in CLAUDE.md (auto-loaded).

set -euo pipefail

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_jq
INPUT=$(cat)

read -r COMPACT_SUMMARY < <(jq_fields '.compact_summary // ""')

# Show compact summary if available
if [ -n "$COMPACT_SUMMARY" ]; then
  echo "## Compaction Summary"
  echo "$COMPACT_SUMMARY"
  echo ""
fi

echo "## Post-Compaction Context"
echo "- Todo list: check for in-progress tasks (CLAUDE.md auto-loaded)"

# Dynamic: current git state
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || :
if [ -n "$BRANCH" ]; then
  echo ""
  echo "### Git State"
  echo "- Branch: \`$BRANCH\`"
  DIRTY=$(git status --porcelain 2>/dev/null | head -5) || :
  if [ -n "$DIRTY" ]; then
    echo "- Uncommitted changes:"
    while IFS= read -r line; do echo "  - $line"; done <<< "$DIRTY"
  fi
fi

# Re-inject last artifact state (top 5 lines of most recently modified devflow artifact)
PLUGIN_DATA="${HOME}/.claude/plugins/data/devflow-devflow"
if [ -d "$PLUGIN_DATA" ]; then
  # Find most recently modified .md file (macOS-compatible: ls -t on find output)
  # shellcheck disable=SC2012,SC2038
  LAST_ARTIFACT=$(find "$PLUGIN_DATA" -maxdepth 5 -name "*.md" 2>/dev/null \
    | xargs ls -t1 2>/dev/null | head -1 || true)
  if [ -n "$LAST_ARTIFACT" ] && [ -f "$LAST_ARTIFACT" ]; then
    # Only show if artifact is fresh (< 2 hours old)
    _now=$(date +%s)
    _mtime=$(stat -f%m "$LAST_ARTIFACT" 2>/dev/null || stat -c%Y "$LAST_ARTIFACT" 2>/dev/null || echo 0)
    if [ $(( _now - _mtime )) -lt 7200 ]; then
      echo ""
      echo "### Last Artifact ($(basename "$LAST_ARTIFACT"))"
      ARTIFACT_NAME=$(basename "$LAST_ARTIFACT")
      if [[ "$ARTIFACT_NAME" == "devflow-context.md" ]]; then
        # Extract task and phase from YAML frontmatter
        TASK=$(grep '^task:' "$LAST_ARTIFACT" 2>/dev/null | head -1 | sed 's/^task: *//')
        PHASE=$(grep '^phase:' "$LAST_ARTIFACT" 2>/dev/null | head -1 | sed 's/^phase: *//')
        [ -n "$TASK" ] && echo "Task: $TASK"
        [ -n "$PHASE" ] && echo "Phase: $PHASE"
      else
        head -5 "$LAST_ARTIFACT"
      fi
    fi
  fi
fi
