#!/usr/bin/env bash
# classify-env-gaps.sh — Cross-reference env vars across code, schema, and .env.example.
# Usage: bash classify-env-gaps.sh [project-root] [schema-file] [example-file]
# Output: {"schema_vars":[...],"example_vars":[...],"code_vars":[...],"gaps":{...},"gap_count":N}
#
# Extends scan-env-refs.sh by adding schema + example parsing and gap analysis.
# Compatible with bash 3.x (macOS default).

set -euo pipefail

PROJECT_ROOT="${1:-.}"
SCHEMA_FILE="${2:-env.ts}"
EXAMPLE_FILE="${3:-.env.example}"

# Resolve paths
SCHEMA_PATH="$PROJECT_ROOT/$SCHEMA_FILE"
EXAMPLE_PATH="$PROJECT_ROOT/$EXAMPLE_FILE"

# --- Phase 1: Scan code for env var references ---
EXCLUDE_DIRS="node_modules|dist|build|\.next"
CODE_TMPFILE=$(mktemp)
trap 'rm -f "$CODE_TMPFILE" "$SCHEMA_TMPFILE" "$EXAMPLE_TMPFILE"' EXIT

# Pattern 1: process.env.VAR_NAME
grep -rn 'process\.env\.\w\+' "$PROJECT_ROOT" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' 2>/dev/null \
  | grep -vE "$EXCLUDE_DIRS" \
  | sed 's/.*process\.env\.\([A-Za-z_][A-Za-z0-9_]*\).*/\1/' \
  >> "$CODE_TMPFILE" || true

# Pattern 2: Env.get('VAR_NAME')
grep -rn "Env\.get(" "$PROJECT_ROOT" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' 2>/dev/null \
  | grep -vE "$EXCLUDE_DIRS" \
  | sed "s/.*Env\.get(['\"][[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\).*/\1/" \
  >> "$CODE_TMPFILE" || true

# Pattern 3: env('VAR_NAME')
grep -rn "env(" "$PROJECT_ROOT" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' 2>/dev/null \
  | grep -vE "$EXCLUDE_DIRS" \
  | grep -v "Env\.get" \
  | sed "s/.*env(['\"][[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\).*/\1/" \
  >> "$CODE_TMPFILE" || true

CODE_VARS=$(sort -u "$CODE_TMPFILE" | grep -E '^[A-Z_][A-Z0-9_]*$' || true)

# --- Phase 2: Parse schema file ---
SCHEMA_TMPFILE=$(mktemp)
if [ -f "$SCHEMA_PATH" ]; then
  grep -oE "['\"]?[A-Z_][A-Z0-9_]*['\"]?\s*:" "$SCHEMA_PATH" 2>/dev/null \
    | sed "s/['\": ]//g" \
    | grep -E '^[A-Z_][A-Z0-9_]*$' \
    | sort -u >> "$SCHEMA_TMPFILE" || true
fi
SCHEMA_VARS=$(cat "$SCHEMA_TMPFILE")

# --- Phase 3: Parse .env.example ---
EXAMPLE_TMPFILE=$(mktemp)
if [ -f "$EXAMPLE_PATH" ]; then
  grep -E '^[A-Z_][A-Z0-9_]*=' "$EXAMPLE_PATH" 2>/dev/null \
    | sed 's/=.*//' \
    | sort -u >> "$EXAMPLE_TMPFILE" || true
fi
EXAMPLE_VARS=$(cat "$EXAMPLE_TMPFILE")

# --- Phase 4: Compute gaps using comm (O(N+M) vs O(N*M) fork-per-call) ---
# comm -23: lines only in file1 (not file2); both inputs must be sorted
sorted_lines() { echo "$1" | grep -v '^$' | sort; }

IN_CODE_NOT_SCHEMA=$(comm -23 <(sorted_lines "$CODE_VARS") <(sorted_lines "$SCHEMA_VARS") 2>/dev/null || true)
IN_CODE_NOT_EXAMPLE=$(comm -23 <(sorted_lines "$CODE_VARS") <(sorted_lines "$EXAMPLE_VARS") 2>/dev/null || true)
IN_SCHEMA_NOT_CODE=$(comm -23 <(sorted_lines "$SCHEMA_VARS") <(sorted_lines "$CODE_VARS") 2>/dev/null || true)
IN_EXAMPLE_NOT_CODE=$(comm -23 <(sorted_lines "$EXAMPLE_VARS") <(sorted_lines "$CODE_VARS") 2>/dev/null || true)

count_lines() { echo "$1" | grep -c '.' 2>/dev/null || echo 0; }
GAP_COUNT=$(( $(count_lines "$IN_CODE_NOT_SCHEMA") + $(count_lines "$IN_CODE_NOT_EXAMPLE") + $(count_lines "$IN_SCHEMA_NOT_CODE") + $(count_lines "$IN_EXAMPLE_NOT_CODE") ))

# --- Build JSON arrays ---
build_json_array() {
  local vars="$1"
  if [ -z "$vars" ]; then echo "[]"; return; fi
  echo "$vars" | grep -v '^$' | jq -R -s 'split("\n") | map(select(. != ""))'
}
gaps_array_from() {
  local vars="$1"
  if [ -z "$vars" ]; then echo "[]"; return; fi
  echo "$vars" | grep -v '^$' | jq -R -s 'split("\n") | map(select(. != ""))'
}

SCHEMA_JSON=$(build_json_array "$SCHEMA_VARS")
EXAMPLE_JSON=$(build_json_array "$EXAMPLE_VARS")
CODE_JSON=$(build_json_array "$CODE_VARS")
GAPS_CODE_SCHEMA=$(gaps_array_from "$IN_CODE_NOT_SCHEMA")
GAPS_CODE_EXAMPLE=$(gaps_array_from "$IN_CODE_NOT_EXAMPLE")
GAPS_SCHEMA_CODE=$(gaps_array_from "$IN_SCHEMA_NOT_CODE")
GAPS_EXAMPLE_CODE=$(gaps_array_from "$IN_EXAMPLE_NOT_CODE")

# --- Output ---
jq -n \
  --argjson schema_vars "$SCHEMA_JSON" \
  --argjson example_vars "$EXAMPLE_JSON" \
  --argjson code_vars "$CODE_JSON" \
  --argjson in_code_not_schema "$GAPS_CODE_SCHEMA" \
  --argjson in_code_not_example "$GAPS_CODE_EXAMPLE" \
  --argjson in_schema_not_code "$GAPS_SCHEMA_CODE" \
  --argjson in_example_not_code "$GAPS_EXAMPLE_CODE" \
  --argjson gap_count "$GAP_COUNT" \
  '{schema_vars:$schema_vars,example_vars:$example_vars,code_vars:$code_vars,gaps:{in_code_not_schema:$in_code_not_schema,in_code_not_example:$in_code_not_example,in_schema_not_code:$in_schema_not_code,in_example_not_code:$in_example_not_code},gap_count:$gap_count}'
