#!/usr/bin/env bash
# install.sh — Bootstrap ~/.claude/ from this repo on a new machine.
# Usage: bash scripts/install.sh
#
# What it does:
#   1. Checks prerequisites
#   2. Prompts for machine-specific values (USERNAME, ALLOWED_DOMAINS)
#   3. Creates ~/.claude/ directory structure
#   4. Generates ~/.claude/settings.json from global-settings.template.json
#   5. Runs link-skill.sh to symlink skills, agents, hooks, and output-styles

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

  for cmd in gh node npm bun shellcheck; do
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

section "MCP binaries (global npm install)"
for pkg in "@bytebase/dbhub" "figma-developer-mcp" "@modelcontextprotocol/server-sequential-thinking"; do
  bin_name="${pkg##*/}"
  bin_name="${bin_name/server-/mcp-server-}"
  if command -v "$bin_name" &>/dev/null 2>&1 || npm list -g --depth=0 "$pkg" &>/dev/null 2>&1; then
    info "$pkg — already installed"
  else
    echo "  Installing $pkg..."
    npm install -g "$pkg" && info "$pkg — installed" || warn "$pkg — install failed, run: npm install -g $pkg"
  fi
done

section "MCP server configuration (~/.claude.json)"
CLAUDE_JSON="$HOME/.claude.json"
if [ ! -f "$CLAUDE_JSON" ]; then
  warn "~/.claude.json not found — start Claude Code once, then re-run this script to configure MCP servers"
else
  python3 - "$CLAUDE_JSON" <<'PYEOF'
import json, sys, os

path = sys.argv[1]
with open(path) as f:
    d = json.load(f)

servers = d.setdefault('mcpServers', {})

# Only set if not already pointing to a global binary (avoid overwriting user customizations)
def needs_update(key, new_cmd):
    return key not in servers or servers[key].get('command', '').startswith('npx') or servers[key].get('command', '').startswith('uvx')

updates = {
    'tathep-db': {
        'type': 'stdio',
        'command': '/opt/homebrew/bin/dbhub',
        'args': ['--config', os.path.expanduser('~') + '/.claude/dbhub.toml']
    },
    'figma': {
        'command': '/opt/homebrew/bin/figma-developer-mcp',
        'args': ['--stdio']
    },
    'sequential-thinking': {
        'type': 'stdio',
        'command': '/opt/homebrew/bin/mcp-server-sequential-thinking',
        'args': [],
        'env': {}
    },
    'context7': {
        'command': '/opt/homebrew/bin/context7-mcp',
    },
}

changed = []
for key, cfg in updates.items():
    if needs_update(key, cfg['command']):
        servers[key] = cfg
        changed.append(key)

if changed:
    with open(path, 'w') as f:
        json.dump(d, f, indent=2)
    print(f"  ✓ MCP servers updated: {', '.join(changed)}")
else:
    print("  ✓ MCP servers — already configured")
PYEOF
fi

section "QMD"
if command -v qmd &>/dev/null; then
  info "qmd — already installed ($(command -v qmd))"
elif command -v bun &>/dev/null; then
  echo "  Installing qmd via bun..."
  bun install -g qmd && info "qmd — installed" || warn "qmd — install failed, run: bun install -g qmd"
else
  warn "qmd — skipped (bun not found). Install bun first, then: bun install -g qmd"
fi

section "Symlinks"
bash "$REPO_ROOT/scripts/link-skill.sh"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║          Setup complete! ✓           ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Next steps:"
echo "  • Restart Claude Code to pick up new settings"
echo "  • Run 'qmd update && qmd embed' in each project directory to index codebases"
echo ""
