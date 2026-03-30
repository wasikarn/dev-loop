#!/usr/bin/env bash
# Migrate legacy anvil-* data files to devflow-* equivalents
# Safe to run multiple times — sentinel file prevents re-running
set -euo pipefail

SENTINEL="$HOME/.claude/.devflow-migrated"
if [ -f "$SENTINEL" ]; then
  exit 0
fi

CLAUDE_DIR="$HOME/.claude"
MIGRATED=0

migrate_file() {
  local old="$1" new="$2"
  if [ ! -f "$old" ]; then return; fi
  if [ -f "$new" ]; then
    cat "$old" >> "$new"
    mv "$old" "${old}.bak"
    echo "Merged: $old → $new (original backed up as .bak)" >&2
  else
    mv "$old" "$new"
    echo "Renamed: $old → $new" >&2
  fi
  MIGRATED=$((MIGRATED + 1))
}

migrate_file "$CLAUDE_DIR/anvil-metrics.jsonl" "$CLAUDE_DIR/devflow-metrics.jsonl"
migrate_file "$CLAUDE_DIR/anvil-reviewer-calibration.jsonl" "$CLAUDE_DIR/devflow-reviewer-calibration.jsonl"

touch "$SENTINEL"
if [ "$MIGRATED" -gt 0 ]; then
  echo "Migration complete: $MIGRATED file(s) migrated." >&2
fi
