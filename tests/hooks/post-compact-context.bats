#!/usr/bin/env bats
# Tests for post-compact-context.sh — re-injects context after compaction.

HOOK="$BATS_TEST_DIRNAME/../../hooks/post-compact-context.sh"

setup() {
  # Create a temp dir with a git repo so git commands succeed
  TMPDIR_GIT=$(mktemp -d)
  git -C "$TMPDIR_GIT" init -q
  git -C "$TMPDIR_GIT" commit --allow-empty -q -m "init" \
    --author="Test <test@test.com>" 2>/dev/null || true
  export TMPDIR_GIT
}

teardown() {
  [ -n "${TMPDIR_GIT:-}" ] && rm -rf "$TMPDIR_GIT"
}

run_hook() {
  # Run from the temp git repo so git commands resolve correctly
  echo "$1" | (cd "$TMPDIR_GIT" && bash "$HOOK")
}

@test "input with compact_summary: outputs compaction summary header" {
  run run_hook '{"compact_summary":"Session was compacted. Previous task: build feature X."}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Compaction Summary" ]]
  [[ "$output" =~ "Session was compacted" ]]
}

@test "input with compact_summary: always outputs post-compaction context block" {
  run run_hook '{"compact_summary":"Phase 3 was active."}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Post-Compaction Context" ]]
}

@test "empty input: exits 0 and still outputs post-compaction context" {
  run run_hook '{}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Post-Compaction Context" ]]
}

@test "missing compact_summary field: skips summary block but outputs context" {
  run run_hook '{"other_field":"value"}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Post-Compaction Context" ]]
  # Should NOT have the summary section since field is absent
  [[ ! "$output" =~ "Compaction Summary" ]]
}

@test "output contains git branch info for git repo" {
  run run_hook '{}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Git State" ]]
  [[ "$output" =~ "Branch:" ]]
}
