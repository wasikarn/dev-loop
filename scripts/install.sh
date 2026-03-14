#!/usr/bin/env bash
# install.sh — Bootstrap ~/.claude/ from this repo on a new machine.
# Usage: bash scripts/install.sh
#
# What it does:
#   1. Checks prerequisites
#   2. Prompts for machine-specific values (USERNAME, ALLOWED_DOMAINS)
#   3. Creates ~/.claude/ directory structure
#   4. Generates ~/.claude/settings.json from global-settings.template.json
#   5. Runs link-skill.sh to create all symlinks

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
TEMPLATE="$REPO_ROOT/global-settings.template.json"
SETTINGS="$CLAUDE_DIR/settings.json"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
info()    { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET} $*"; }
error()   { echo -e "  ${RED}✗${RESET} $*" >&2; }
section() { echo ""; echo "[$*]"; }

# ── Prerequisites ──────────────────────────────────────────────────────────────
check_prereqs() {
  local missing=0

  for cmd in git jq; do
    if command -v "$cmd" &>/dev/null; then
      info "$cmd — $(command -v "$cmd")"
    else
      error "$cmd — NOT FOUND (required)"
      missing=1
    fi
  done

  for cmd in gh node npm bun; do
    if command -v "$cmd" &>/dev/null; then
      info "$cmd — $(command -v "$cmd")"
    else
      warn "$cmd — not found (optional)"
    fi
  done

  if [ "$missing" -eq 1 ]; then
    echo ""
    echo "Install missing prerequisites, then re-run this script."
    exit 1
  fi
}

# ── Prompt helpers ─────────────────────────────────────────────────────────────
prompt() {
  local var_name="$1"
  local prompt_text="$2"
  local default="$3"
  local value

  if [ -n "$default" ]; then
    read -r -p "  $prompt_text [$default]: " value
    value="${value:-$default}"
  else
    read -r -p "  $prompt_text: " value
    while [ -z "$value" ]; do
      echo "  (required)" >&2
      read -r -p "  $prompt_text: " value
    done
  fi

  printf -v "$var_name" '%s' "$value"
}

# ── Directory structure ────────────────────────────────────────────────────────
create_dirs() {
  local dirs=(
    "$CLAUDE_DIR"
    "$CLAUDE_DIR/memory"
    "$CLAUDE_DIR/docs"
    "$CLAUDE_DIR/skills"
    "$CLAUDE_DIR/agents"
    "$CLAUDE_DIR/hooks"
    "$CLAUDE_DIR/commands"
    "$CLAUDE_DIR/output-styles"
    "$CLAUDE_DIR/scripts"
  )

  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      info "$dir — exists"
    else
      mkdir -p "$dir"
      info "$dir — created"
    fi
  done
}

# ── Generate settings.json ─────────────────────────────────────────────────────
generate_settings() {
  local username="$1"
  local allowed_domains="$2"

  if [ ! -f "$TEMPLATE" ]; then
    error "Template not found: $TEMPLATE"
    exit 1
  fi

  # Backup existing settings if present
  if [ -f "$SETTINGS" ]; then
    local backup="$SETTINGS.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$SETTINGS" "$backup"
    warn "Existing settings.json backed up → $backup"
  fi

  # Substitute placeholders
  sed \
    -e "s|{{USERNAME}}|${username}|g" \
    -e "s|{{ALLOWED_DOMAINS}}|${allowed_domains}|g" \
    "$TEMPLATE" > "$SETTINGS"

  # Validate the generated JSON
  if jq '.' "$SETTINGS" > /dev/null 2>&1; then
    info "settings.json generated and valid"
  else
    error "Generated settings.json is invalid JSON — check template"
    exit 1
  fi
}

# ── Main ───────────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════╗"
echo "║   Claude Code — New Machine Setup    ║"
echo "╚══════════════════════════════════════╝"

section "Prerequisites"
check_prereqs

section "Configuration"
echo ""
echo "  Enter machine-specific values (press Enter to accept defaults)."
echo ""

DEFAULT_USERNAME="$(whoami)"
prompt USERNAME "macOS username (for file permission rules)" "$DEFAULT_USERNAME"
prompt ALLOWED_DOMAINS "Browser allowed domains (comma-separated, e.g. *.example.com,*.other.com)" ""

section "Directories"
create_dirs

section "settings.json"
generate_settings "$USERNAME" "$ALLOWED_DOMAINS"

section "Symlinks"
bash "$REPO_ROOT/scripts/link-skill.sh"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║          Setup complete! ✓           ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Next steps:"
echo "  • Restart Claude Code to pick up new settings"
echo "  • Run 'bash scripts/sync-docs.sh' to fetch Claude Code docs cache"
echo "  • Run 'qmd embed' in project directories to index local codebases"
echo ""
