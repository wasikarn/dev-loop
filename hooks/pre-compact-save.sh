#!/usr/bin/env bash
# pre-compact-save.sh — PreCompact hook
# Saves critical DLC session context before compaction truncates conversation history.
# If an active artifact dir is found, writes a compact summary to preserve phase state.

# NOTE: no set -euo pipefail — hook must exit 0 on all failures

ARTIFACT_DIR=$(bash "$(dirname "${BASH_SOURCE[0]}")/../scripts/artifact-dir.sh" dlc-build 2>/dev/null || true)

[ -n "$ARTIFACT_DIR" ] || exit 0
[ -d "$ARTIFACT_DIR" ] || exit 0

# Check for active DLC session artifacts
CONTEXT_FILE="$ARTIFACT_DIR/anvil-context.md"
[ -f "$CONTEXT_FILE" ] || exit 0

# Output a reminder about active session — injected into post-compact context
PHASE=$(grep -m1 '^Phase:' "$CONTEXT_FILE" 2>/dev/null | awk '{print $2}' || echo "unknown")

cat <<EOF
<anvil-pre-compact>
Active DLC session detected before compaction.
Artifact dir: $ARTIFACT_DIR
Current phase: $PHASE
Context file preserved at: $CONTEXT_FILE
After compaction: check artifact files to resume — /dlc-status for current state.
</anvil-pre-compact>
EOF

exit 0
