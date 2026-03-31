#!/usr/bin/env bats
# Tests for idle-nudge.sh — nudges idle teammates back on task.

HOOK="$BATS_TEST_DIRNAME/../../hooks/idle-nudge.sh"

@test "team name matches NUDGE_PATTERN: exits 2 with nudge message" {
  run bash -c "echo '{\"team_name\":\"review-pr\"}' \
    | NUDGE_PATTERN='review-pr' NUDGE_MSG='Get back to work!' bash '$HOOK'" 2>&1
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Get back to work!" ]]
}

@test "team name does not match NUDGE_PATTERN: exits 0 with no output" {
  run bash -c "echo '{\"team_name\":\"build-project\"}' \
    | NUDGE_PATTERN='review-pr' NUDGE_MSG='Get back to work!' bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "empty NUDGE_PATTERN: exits 0 (no filtering)" {
  run bash -c "echo '{\"team_name\":\"review-pr\"}' \
    | NUDGE_PATTERN='' NUDGE_MSG='nudge' bash '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "empty input (missing team_name): exits 0 gracefully" {
  run bash -c "echo '{}' | NUDGE_PATTERN='review' NUDGE_MSG='nudge' bash '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "NUDGE_CHECK_TASKS=1 with no tasks dir: exits 0 (no pending work)" {
  run bash -c "echo '{\"team_name\":\"review-pr\"}' \
    | NUDGE_PATTERN='review-pr' NUDGE_MSG='back to it' NUDGE_CHECK_TASKS=1 \
      HOME=/nonexistent bash '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "pattern matches team name case-insensitively: triggers nudge" {
  run bash -c "echo '{\"team_name\":\"Review-PR\"}' \
    | NUDGE_PATTERN='review-pr' NUDGE_MSG='Stay on task.' bash '$HOOK'" 2>&1
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Stay on task." ]]
}
