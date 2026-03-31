#!/usr/bin/env bats
# Tests for protect-files.sh — blocks edits to sensitive config files.

HOOK="$BATS_TEST_DIRNAME/../../hooks/protect-files.sh"

run_hook() {
  echo "$1" | bash "$HOOK"
}

@test "protected path .claude/settings.json: exits 2 with error message" {
  run run_hook '{"tool_input":{"file_path":"/home/user/.claude/settings.json"}}'
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Blocked" ]]
}

@test "non-protected path: exits 0 with no output" {
  run run_hook '{"tool_input":{"file_path":"/home/user/project/src/index.ts"}}'
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "empty input: exits 0 gracefully" {
  run run_hook '{}'
  [ "$status" -eq 0 ]
}

@test "protected path .claude/settings.local.json: exits 2 with error message" {
  run run_hook '{"tool_input":{"file_path":"/home/user/.claude/settings.local.json"}}'
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Blocked" ]]
}

@test "nested protected path inside project: exits 2" {
  run run_hook '{"tool_input":{"file_path":"/project/repo/.claude/settings.json"}}'
  [ "$status" -eq 2 ]
  [[ "$output" =~ "settings.json" ]]
}
