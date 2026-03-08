#!/usr/bin/env bash
# sync-docs.sh — Fetch Claude Code official docs to local cache.
# Usage:
#   bash scripts/sync-docs.sh           # fetch all (skip unchanged via If-Modified-Since)
#   bash scripts/sync-docs.sh --force   # re-fetch everything
#   bash scripts/sync-docs.sh --check   # report staleness only, no fetch

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="$HOME/.claude/docs/claude-code"
STALE_DAYS=14

# Source list: filename:url
DOCS=(
  "features-overview.md:https://code.claude.com/docs/en/features-overview.md"
  "skills.md:https://code.claude.com/docs/en/skills.md"
  "sub-agents.md:https://code.claude.com/docs/en/sub-agents.md"
  "output-styles.md:https://code.claude.com/docs/en/output-styles.md"
  "memory.md:https://code.claude.com/docs/en/memory.md"
  "settings.md:https://code.claude.com/docs/en/settings.md"
  "permissions.md:https://code.claude.com/docs/en/permissions.md"
  "hooks-guide.md:https://code.claude.com/docs/en/hooks-guide.md"
  "hooks.md:https://code.claude.com/docs/en/hooks.md"
  "scheduled-tasks.md:https://code.claude.com/docs/en/scheduled-tasks.md"
  "plugins.md:https://code.claude.com/docs/en/plugins.md"
  "mcp.md:https://code.claude.com/docs/en/mcp.md"
  "agent-teams.md:https://code.claude.com/docs/en/agent-teams.md"
)

# ── Helpers ───────────────────────────────────────────────────────────────────

check_staleness() {
  local sync_file="$CACHE_DIR/.last-sync"
  if [ ! -f "$sync_file" ]; then
    echo "  ⚠ No docs cache — run: bash scripts/sync-docs.sh"
    return 1
  fi

  local last_sync
  last_sync=$(cat "$sync_file")
  local last_epoch
  last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_sync" "+%s" 2>/dev/null) \
    || last_epoch=$(date -d "$last_sync" "+%s" 2>/dev/null) \
    || { echo "  ⚠ Cannot parse .last-sync"; return 1; }

  local now_epoch
  now_epoch=$(date "+%s")
  local age_days=$(( (now_epoch - last_epoch) / 86400 ))

  if [ "$age_days" -ge "$STALE_DAYS" ]; then
    echo "  ⚠ Docs cache is ${age_days} days old (threshold: ${STALE_DAYS}d)"
    echo "    Run: bash scripts/sync-docs.sh"
    return 1
  else
    echo "  ✓ Docs cache is ${age_days} days old (threshold: ${STALE_DAYS}d)"
    echo "    Last sync: $last_sync"
    echo "    Location: $CACHE_DIR/"
    return 0
  fi
}

fetch_doc() {
  local filename="$1"
  local url="$2"
  local force="${3:-false}"
  local filepath="$CACHE_DIR/$filename"

  local curl_args=(-sS -f -o "$filepath" -w "%{http_code}")
  if [ "$force" = "false" ] && [ -f "$filepath" ]; then
    curl_args+=(-z "$filepath")
  fi

  local http_code
  http_code=$(curl "${curl_args[@]}" "$url" 2>/dev/null) || {
    echo "  ✗ $filename [FAILED]"
    return 1
  }

  case "$http_code" in
    200) echo "  ↓ $filename [fetched]" ;;
    304) echo "  ✓ $filename [unchanged]" ;;
    *)   echo "  ✗ $filename [HTTP $http_code]"; return 1 ;;
  esac
}

# ── Main ──────────────────────────────────────────────────────────────────────

case "${1:-}" in
  --check)
    echo "Docs cache status:"
    check_staleness
    echo ""
    local_count=$(find "$CACHE_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Files cached: ${local_count}/${#DOCS[@]} docs + skill-creation-guide.md"
    ;;

  --force|"")
    force="false"
    [ "${1:-}" = "--force" ] && force="true"

    echo "Syncing Claude Code docs → $CACHE_DIR/"
    mkdir -p "$CACHE_DIR"

    failed=0
    for entry in "${DOCS[@]}"; do
      filename="${entry%%:*}"
      url="${entry#*:}"
      fetch_doc "$filename" "$url" "$force" || failed=$((failed + 1))
    done

    # Copy Notion-sourced doc from repo
    local_ref="$REPO_ROOT/references/skill-creation-guide.md"
    if [ -f "$local_ref" ]; then
      cp "$local_ref" "$CACHE_DIR/skill-creation-guide.md"
      echo "  ↻ skill-creation-guide.md [copied from repo]"
    else
      echo "  ✗ skill-creation-guide.md [not found in references/]"
      failed=$((failed + 1))
    fi

    # Write sync timestamp
    date -u "+%Y-%m-%dT%H:%M:%SZ" > "$CACHE_DIR/.last-sync"

    echo ""
    total=$(( ${#DOCS[@]} + 1 ))
    echo "Done: $((total - failed))/$total synced"
    if [ "$failed" -gt 0 ]; then exit 1; fi
    ;;

  *)
    echo "Usage: bash scripts/sync-docs.sh [--force|--check]"
    exit 1
    ;;
esac
