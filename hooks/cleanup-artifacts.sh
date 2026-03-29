#!/usr/bin/env bash
# cleanup-artifacts.sh — SessionStart hook (async)
# Auto-removes artifact files older than DEVFLOW_ARTIFACT_TTL_DAYS (default: 7).
# Silent if nothing to clean. Safe to run on every session start.

TTL_DAYS="${DEVFLOW_ARTIFACT_TTL_DAYS:-${ANVIL_ARTIFACT_TTL_DAYS:-${DEV_LOOP_ARTIFACT_TTL_DAYS:-7}}}"
# CLAUDE_PLUGIN_DATA: stable per-plugin folder set by Claude Code plugin runtime.
# Falls back to the conventional path for local dev (symlinked, not installed).
BASE_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/devflow-devflow}"

[ -d "$BASE_DIR" ] || exit 0

DELETED=0
while IFS= read -r -d '' file; do
  rm -f "$file"
  DELETED=$((DELETED + 1))
done < <(find "$BASE_DIR" -type f -name "*.md" -mtime "+${TTL_DAYS}" -print0 2>/dev/null)

if [ "$DELETED" -gt 0 ]; then
  echo "devflow: removed $DELETED artifact file(s) older than ${TTL_DAYS}d from $BASE_DIR/"
fi
