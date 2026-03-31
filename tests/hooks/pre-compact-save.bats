#!/usr/bin/env bats
# Tests for pre-compact-save.sh — saves Devflow session state before compaction.

HOOK="$BATS_TEST_DIRNAME/../../hooks/pre-compact-save.sh"
SCRIPTS_DIR="$BATS_TEST_DIRNAME/../../scripts"

setup() {
  # Create a temp git repo to anchor artifact-dir.sh
  TMPDIR_GIT=$(mktemp -d)
  # Resolve symlinks — macOS /var/folders is a symlink to /private/var/folders;
  # git rev-parse --show-toplevel returns the resolved path, so we must match it.
  TMPDIR_GIT=$(cd "$TMPDIR_GIT" && pwd -P)
  git -C "$TMPDIR_GIT" init -q
  git -C "$TMPDIR_GIT" commit --allow-empty -q -m "init" \
    --author="Test <test@test.com>" 2>/dev/null || true

  # Build artifact dir path: encode project root (/ -> -) then append /build
  ENCODED=$(echo "$TMPDIR_GIT" | tr '/' '-')
  PLUGIN_DATA=$(mktemp -d)
  PLUGIN_DATA=$(cd "$PLUGIN_DATA" && pwd -P)
  ARTIFACT_DIR="$PLUGIN_DATA/$ENCODED/build"
  mkdir -p "$ARTIFACT_DIR"

  export TMPDIR_GIT PLUGIN_DATA ARTIFACT_DIR ENCODED
}

teardown() {
  [ -n "${TMPDIR_GIT:-}" ] && rm -rf "$TMPDIR_GIT"
  [ -n "${PLUGIN_DATA:-}" ] && rm -rf "$PLUGIN_DATA"
}

run_hook() {
  echo "$1" | (cd "$TMPDIR_GIT" && CLAUDE_PLUGIN_DATA="$PLUGIN_DATA" bash "$HOOK")
}

@test "artifact dir exists with context file: outputs devflow-pre-compact block" {
  # Write a context file with a Phase header
  cat > "$ARTIFACT_DIR/devflow-context.md" <<'EOF'
---
task: implement feature
phase: 3
---
Phase: 3
EOF
  run run_hook '{}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "devflow-pre-compact" ]]
  [[ "$output" =~ "Artifact dir:" ]]
}

@test "context file contains phase info" {
  cat > "$ARTIFACT_DIR/devflow-context.md" <<'EOF'
Phase: 5
EOF
  run run_hook '{}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Current phase: 5" ]]
}

@test "missing artifact dir: exits 0 gracefully with no output" {
  # Point CLAUDE_PLUGIN_DATA to an empty dir — artifact-dir.sh will create the path
  # but there's no context file, so hook should exit 0 silently
  EMPTY_PLUGIN=$(mktemp -d)
  run bash -c "echo '{}' | (cd '$TMPDIR_GIT' && CLAUDE_PLUGIN_DATA='$EMPTY_PLUGIN' bash '$HOOK')"
  rm -rf "$EMPTY_PLUGIN"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "output contains context file path" {
  cat > "$ARTIFACT_DIR/devflow-context.md" <<'EOF'
Phase: 2
EOF
  run run_hook '{}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "devflow-context.md" ]]
}
