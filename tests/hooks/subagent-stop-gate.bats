#!/usr/bin/env bats
# Tests for subagent-stop-gate.sh — gates reviewer agents without file:line evidence.

HOOK="$BATS_TEST_DIRNAME/../../hooks/subagent-stop-gate.sh"

run_hook() {
  echo "$1" | GATE_PATTERN="${GATE_PATTERN:-}" GATE_MSG="${GATE_MSG:-}" bash "$HOOK"
}

@test "non-reviewer agent name: exits 0 (allow)" {
  run bash -c "echo '{\"agent_type\":\"commit-finalizer\",\"last_assistant_message\":\"done\"}' \
    | GATE_PATTERN='code-reviewer' bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "reviewer agent with file:line evidence: exits 0 (allow)" {
  run bash -c "echo '{\"agent_type\":\"code-reviewer\",\"last_assistant_message\":\"Found issue at src/api/handler.ts:42 — missing null check\"}' \
    | GATE_PATTERN='code-reviewer' bash '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "reviewer agent without evidence: outputs block decision JSON" {
  run bash -c "echo '{\"agent_type\":\"code-reviewer\",\"last_assistant_message\":\"Looks good to me, no issues found.\"}' \
    | GATE_PATTERN='code-reviewer' bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" =~ '"decision"' ]]
  [[ "$output" =~ '"block"' ]]
}

@test "empty input (missing fields): exits 0 gracefully" {
  run bash -c "echo '{}' | GATE_PATTERN='code-reviewer' bash '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "empty GATE_PATTERN: exits 0 (no filtering)" {
  run bash -c "echo '{\"agent_type\":\"code-reviewer\",\"last_assistant_message\":\"no references\"}' \
    | GATE_PATTERN='' bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "pattern matches agent name case-insensitively: triggers gate" {
  run bash -c "echo '{\"agent_type\":\"Code-Reviewer\",\"last_assistant_message\":\"no file refs here\"}' \
    | GATE_PATTERN='code-reviewer' bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" =~ '"decision"' ]]
  [[ "$output" =~ '"block"' ]]
}

@test "custom GATE_MSG appears in block reason" {
  run bash -c "echo '{\"agent_type\":\"silent-failure-hunter\",\"last_assistant_message\":\"nothing found\"}' \
    | GATE_PATTERN='silent-failure-hunter' GATE_MSG='Must cite file:line references.' bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Must cite file:line references." ]]
}
