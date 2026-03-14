#!/usr/bin/env bash
# Update Claude Code docs from docs.anthropic.com
# Usage: ~/.claude/scripts/update-claude-code-docs.sh

set -euo pipefail

DOCS_DIR="$HOME/.claude/docs/claude-code"
BASE_URL="https://docs.anthropic.com/en/docs/claude-code"
FETCH_DATE=$(date +%Y-%m-%d)

PAGES=(
  agent-teams
  features-overview
  hooks
  hooks-guide
  mcp
  memory
  output-styles
  permissions
  plugins
  scheduled-tasks
  settings
  skill-creation-guide
  skills
  sub-agents
)

mkdir -p "$DOCS_DIR"

echo "Fetching Claude Code docs..."
UPDATED=0
FAILED=0

for page in "${PAGES[@]}"; do
  url="$BASE_URL/$page"
  out="$DOCS_DIR/$page.md"

  content=$(curl -sf \
    -H "Accept: text/plain, text/markdown, text/html" \
    -H "User-Agent: Mozilla/5.0" \
    "$url" 2>/dev/null) || { echo "  ✗ $page (fetch failed)"; ((FAILED++)); continue; }

  if [ -z "$content" ]; then
    echo "  ✗ $page (empty response)"
    ((FAILED++))
    continue
  fi

  printf '<!-- source: %s | fetched: %s -->\n\n%s\n' "$url" "$FETCH_DATE" "$content" > "$out"
  echo "  ✓ $page"
  ((UPDATED++))
done

echo ""
echo "Done: $UPDATED updated, $FAILED failed"

if [ "$UPDATED" -gt 0 ]; then
  echo "Re-indexing QMD..."
  qmd update docs && qmd embed docs --background
  echo "QMD re-index queued"
fi
