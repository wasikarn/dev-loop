#!/usr/bin/env bats
# Tests for task-gate.sh — blocks task completion without file:line evidence.

HOOK="$BATS_TEST_DIRNAME/../../hooks/task-gate.sh"

@test "task name matches GATE_PATTERN with evidence: exits 0 (allow)" {
  run bash -c "echo '{\"task_name\":\"review findings\",\"tool_output\":\"Found issue at hooks/common.sh:18 — pattern too loose\"}' \
    | GATE_PATTERN='review' bash '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "task name matches GATE_PATTERN without evidence: exits 2 (block)" {
  run bash -c "echo '{\"task_name\":\"review findings\",\"tool_output\":\"Everything looks good.\"}' \
    | GATE_PATTERN='review' bash '$HOOK'"
  [ "$status" -eq 2 ]
}

@test "task name does not match GATE_PATTERN: exits 0 (passthrough)" {
  run bash -c "echo '{\"task_name\":\"build project\",\"tool_output\":\"no references\"}' \
    | GATE_PATTERN='review' bash '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "empty GATE_PATTERN: exits 0 (allow everything)" {
  run bash -c "echo '{\"task_name\":\"review findings\",\"tool_output\":\"no refs\"}' \
    | GATE_PATTERN='' bash '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "custom GATE_MSG appears in block stderr output" {
  run bash -c "echo '{\"task_name\":\"debate round\",\"tool_output\":\"consensus reached\"}' \
    | GATE_PATTERN='debate' GATE_MSG='Cite specific file:line locations.' bash '$HOOK'" 2>&1
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Cite specific file:line locations." ]]
}

@test "empty input (missing fields): exits 0 gracefully" {
  run bash -c "echo '{}' | GATE_PATTERN='review' bash '$HOOK'"
  [ "$status" -eq 0 ]
}
