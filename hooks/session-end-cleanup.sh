#!/usr/bin/env bash
# session-end-cleanup.sh — SessionEnd hook (async)
# Cleans up temporary session files on session end.
# Preserves artifact .md files (they survive across sessions for recovery).
# Only removes .tmp and .lock files that may have been left behind.

# NOTE: no set -euo pipefail — hook must exit 0 on all failures

PLUGIN_DATA_BASE="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/devflow-devflow}"

[ -d "$PLUGIN_DATA_BASE" ] || exit 0

DELETED=0
while IFS= read -r -d '' file; do
  rm -f "$file"
  DELETED=$((DELETED + 1))
done < <(find "$PLUGIN_DATA_BASE" -type f \( -name "*.tmp" -o -name "*.lock" \) -print0 2>/dev/null)

if [ "$DELETED" -gt 0 ]; then
  echo "devflow: session-end cleaned up $DELETED temp file(s) from $PLUGIN_DATA_BASE/"
fi

exit 0
