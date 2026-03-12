#!/usr/bin/env bash
# scan-env-refs.sh — Scan codebase for env var references and output JSON.
# Usage: bash scan-env-refs.sh [project-root]
# Output: {"vars": ["VAR1", "VAR2", ...], "count": N}
#
# Compatible with bash 3.x (macOS default).
# No declare -A, no mapfile, no associative arrays.

set -euo pipefail

PROJECT_ROOT="${1:-.}"

# Validate directory exists
if [ ! -d "$PROJECT_ROOT" ]; then
  echo '{"vars": [], "count": 0, "error": "Directory not found: '"$PROJECT_ROOT"'"}' >&2
  exit 1
fi

EXCLUDE_DIRS="node_modules|dist|build|\.next"

# Collect all env var names into a temp file (one per line, may have duplicates)
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# Pattern 1: process.env.VAR_NAME
grep -rn 'process\.env\.\w\+' "$PROJECT_ROOT" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' 2>/dev/null \
  | grep -vE "$EXCLUDE_DIRS" \
  | sed 's/.*process\.env\.\([A-Za-z_][A-Za-z0-9_]*\).*/\1/' \
  >> "$TMPFILE" || true

# Pattern 2: Env.get('VAR_NAME') or Env.get("VAR_NAME")
grep -rn "Env\.get(" "$PROJECT_ROOT" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' 2>/dev/null \
  | grep -vE "$EXCLUDE_DIRS" \
  | sed "s/.*Env\.get(['\"][[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\).*/\1/" \
  >> "$TMPFILE" || true

# Pattern 3: env('VAR_NAME') or env("VAR_NAME")
grep -rn "env(" "$PROJECT_ROOT" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' 2>/dev/null \
  | grep -vE "$EXCLUDE_DIRS" \
  | grep -v "Env\.get" \
  | sed "s/.*env(['\"][[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\).*/\1/" \
  >> "$TMPFILE" || true

# Sort, deduplicate, filter out lines that don't look like var names
VARS=$(sort -u "$TMPFILE" | grep -E '^[A-Z_][A-Z0-9_]*$' || true)

if [ -z "$VARS" ]; then
  COUNT=0
else
  COUNT=$(echo "$VARS" | wc -l | tr -d ' ')
fi

# Build JSON array manually (no jq dependency)
JSON_ARRAY=""
while IFS= read -r var; do
  [ -z "$var" ] && continue
  if [ -n "$JSON_ARRAY" ]; then
    JSON_ARRAY="${JSON_ARRAY}, \"${var}\""
  else
    JSON_ARRAY="\"${var}\""
  fi
done <<EOF
$VARS
EOF

echo "{\"vars\": [${JSON_ARRAY}], \"count\": ${COUNT}}"
