#!/usr/bin/env bash
# cleanup-artifacts.sh — SessionStart hook (async)
# Auto-removes artifact files older than DEVFLOW_ARTIFACT_TTL_DAYS (default: 7).
# Silent if nothing to clean. Safe to run on every session start.

TTL_DAYS="${DEVFLOW_ARTIFACT_TTL_DAYS:-${ANVIL_ARTIFACT_TTL_DAYS:-${DEV_LOOP_ARTIFACT_TTL_DAYS:-7}}}"
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
BASE_DIR="$(plugin_data_dir)"

[ -d "$BASE_DIR" ] || exit 0

DELETED=0
while IFS= read -r -d '' file; do
  rm -f "$file"
  DELETED=$((DELETED + 1))
done < <(find "$BASE_DIR" -type f -name "*.md" -mtime "+${TTL_DAYS}" -print0 2>/dev/null)

if [ "$DELETED" -gt 0 ]; then
  echo "devflow: removed $DELETED artifact file(s) older than ${TTL_DAYS}d from $BASE_DIR/"
fi
