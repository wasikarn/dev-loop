#!/usr/bin/env bash
# Post-tool-use hook: log git commit summaries to session log.
# Triggered after Bash tool calls. Detects git commits and logs them.
# Replaces parallel claude-mem observer sessions for commit tracking.

# Only process Bash tool calls
if [ "$CLAUDE_TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# Read tool input from stdin
INPUT=$(cat)

# Check if this was a git commit command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Match git commit commands (not git commit --amend checks, log, etc.)
[[ "$COMMAND" =~ ^[[:space:]]*git[[:space:]]+commit[[:space:]] ]] || exit 0

# Ensure log directory exists
LOG_DIR="$HOME/.claude/session-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"

# Extract info from the repo where the commit happened
WORK_DIR=$(pwd)
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
LAST_COMMIT=$(git log -1 --format="%h %s" 2>/dev/null || echo "unknown")
FILES_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || basename "$WORK_DIR")

# Append to session log
{
  echo "---"
  echo "time: $(date '+%H:%M:%S')"
  echo "repo: $REPO"
  echo "branch: $BRANCH"
  echo "commit: $LAST_COMMIT"
  echo "files: $FILES_CHANGED"
} >> "$LOG_FILE"
