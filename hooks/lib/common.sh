#!/usr/bin/env bash
# hooks/lib/common.sh — Shared utilities for dev-loop hook scripts.
# Source this file at the top of each hook (after your own set -euo pipefail):
#
#   # shellcheck source=lib/common.sh
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#
# NOTE: This lib does NOT set -euo pipefail — inherits caller's shell options.

# require_jq — exit 0 (skip hook) if jq is not installed.
# Uses exit, not return — terminates the entire hook process.
# Must be called BEFORE INPUT=$(cat) to avoid consuming stdin unnecessarily.
require_jq() { command -v jq > /dev/null 2>&1 || exit 0; }

# has_evidence TEXT — returns 0 if TEXT contains a file:line reference.
# Pattern: file.ext:NNN (intentionally loose — matches source citations).
# Usage: if has_evidence "$SOME_VAR"; then ...
has_evidence() { printf '%s\n' "$1" | grep -qE '[a-zA-Z0-9_/.-]+\.[a-zA-Z]+:[0-9]+'; }

# jq_fields FILTER... — parse multiple fields from $INPUT in one jq call.
# Precondition: $INPUT must be set (via INPUT=$(cat)) before calling.
# Requires at least one filter argument.
# Returns: TSV line to stdout — one value per filter, empty string for null/missing.
# Usage: IFS=$'\t' read -r FIELD1 FIELD2 < <(jq_fields '.foo' '.bar')
jq_fields() {
  [ "$#" -gt 0 ] || { echo "jq_fields: requires at least one filter" >&2; return 1; }
  local filters=("$@")
  local expr
  expr=$(printf '%s, ' "${filters[@]}")
  expr="${expr%, }"
  echo "$INPUT" | jq -r "[${expr}] | map(. // \"\") | @tsv"
}
