#!/usr/bin/env bash
# link-skill.sh — Create ~/.claude/ symlinks for all assets in this repo.
# Usage:
#   bash scripts/link-skill.sh            # link everything
#   bash scripts/link-skill.sh spec-kit   # link one skill by name
#   bash scripts/link-skill.sh --list     # show current link status

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Asset types: repo_subdir:claude_target (each item in subdir gets symlinked individually)
ASSET_TYPES="skills:$HOME/.claude/skills agents:$HOME/.claude/agents output-styles:$HOME/.claude/output-styles hooks:$HOME/.claude/hooks commands:$HOME/.claude/commands scripts:$HOME/.claude/scripts"

# Dotfiles: individual repo_file:claude_target pairs (space-separated, pipe-delimited entries)
DOTFILES="statusline.sh:$HOME/.claude/statusline.sh|global-CLAUDE.md:$HOME/.claude/CLAUDE.md"

# ── Helpers ───────────────────────────────────────────────────────────────────
link_item() {
  local src="$1"
  local dst="$2"
  local name
  name=$(basename "$src")

  if [ -L "$dst" ]; then
    local existing
    existing=$(readlink "$dst")
    if [ "$existing" = "$src" ]; then
      echo "  ✓ $name — already linked"
      return 0
    fi
    echo "  ~ $name — relinking ($existing → $src)"
    ln -sf "$src" "$dst"
  elif [ -e "$dst" ]; then
    echo "  ✗ $name — $dst exists and is not a symlink, skipping" >&2
    return 1
  else
    ln -s "$src" "$dst"
    echo "  + $name — linked"
  fi
}

link_asset_type() {
  local type="$1"
  local dst_dir="$2"
  local src_dir="$REPO_ROOT/$type"

  [ -d "$src_dir" ] || return 0
  mkdir -p "$dst_dir"

  local found=0
  for item in "$src_dir"/*; do
    [ -e "$item" ] || continue
    found=1
    link_item "$item" "$dst_dir/$(basename "$item")"
  done

  if [ $found -eq 0 ]; then
    echo "  (no items in $type/)"
  fi
}

link_dotfiles() {
  IFS='|' read -ra PAIRS <<< "$DOTFILES"
  for pair in "${PAIRS[@]}"; do
    local src_rel="${pair%%:*}"
    local dst="${pair#*:}"
    local src="$REPO_ROOT/$src_rel"
    [ -f "$src" ] || continue
    link_item "$src" "$dst"
  done
}

list_status() {
  for entry in $ASSET_TYPES; do
    local type="${entry%%:*}"
    local dst_dir="${entry#*:}"
    local src_dir="$REPO_ROOT/$type"

    [ -d "$src_dir" ] || continue

    echo ""
    echo "$type:"
    for item in "$src_dir"/*; do
      [ -e "$item" ] || continue
      local name
      name=$(basename "$item")
      local dst="$dst_dir/$name"
      local target
      target=$(readlink "$dst" 2>/dev/null) \
        && echo "  ✓ $name → $target" \
        || echo "  ✗ $name (not linked)"
    done
  done

  echo ""
  echo "dotfiles:"
  IFS='|' read -ra PAIRS <<< "$DOTFILES"
  for pair in "${PAIRS[@]}"; do
    local src_rel="${pair%%:*}"
    local dst="${pair#*:}"
    local target
    target=$(readlink "$dst" 2>/dev/null) \
      && echo "  ✓ $src_rel → $target" \
      || echo "  ✗ $src_rel (not linked at $dst)"
  done
}

link_one_skill() {
  local name="$1"
  local src="$REPO_ROOT/skills/$name"
  local dst="$HOME/.claude/skills/$name"

  if [ ! -d "$src" ]; then
    echo "  ✗ $name — not found in skills/" >&2
    return 1
  fi

  mkdir -p "$HOME/.claude/skills"
  link_item "$src" "$dst"
}

# ── Main ──────────────────────────────────────────────────────────────────────
case "${1:-}" in
  --list)
    list_status
    ;;
  "")
    echo "Linking all assets → ~/.claude/"
    for entry in $ASSET_TYPES; do
      type="${entry%%:*}"
      dst_dir="${entry#*:}"
      echo ""
      echo "[$type]"
      link_asset_type "$type" "$dst_dir"
    done

    # Dotfiles: individual file symlinks
    echo ""
    echo "[dotfiles]"
    link_dotfiles

    # Report docs cache staleness (informational only — does not auto-fetch)
    echo ""
    echo "[docs]"
    sync_file="$HOME/.claude/docs/claude-code/.last-sync"
    if [ -f "$sync_file" ]; then
      last_sync=$(cat "$sync_file")
      last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_sync" "+%s" 2>/dev/null) \
        || last_epoch=$(date -d "$last_sync" "+%s" 2>/dev/null) \
        || last_epoch=0
      now_epoch=$(date "+%s")
      age_days=$(( (now_epoch - last_epoch) / 86400 ))
      if [ "$age_days" -ge 14 ]; then
        echo "  ⚠ Docs cache is ${age_days} days old — run: bash scripts/sync-docs.sh"
      else
        echo "  ✓ Docs cache is ${age_days} days old (last: $last_sync)"
      fi
    else
      echo "  ⚠ No docs cache — run: bash scripts/sync-docs.sh"
    fi
    ;;
  *)
    link_one_skill "$1"
    ;;
esac
