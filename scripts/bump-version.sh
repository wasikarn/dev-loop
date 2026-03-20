#!/usr/bin/env bash
# bump-version.sh — Bump plugin version, commit, push, and create GitHub release.
#
# Usage:
#   bash scripts/bump-version.sh <version>   # explicit: 0.5.1
#   bash scripts/bump-version.sh patch       # auto-increment: 0.5.0 → 0.5.1
#   bash scripts/bump-version.sh minor       # auto-increment: 0.5.0 → 0.6.0
#   bash scripts/bump-version.sh major       # auto-increment: 0.5.0 → 1.0.0
#
# What it does:
#   1. Updates version in .claude-plugin/plugin.json and marketplace.json
#   2. Commits the version bump
#   3. Pushes to origin
#   4. Creates a GitHub release with auto-generated notes

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

# ── helpers ──────────────────────────────────────────────────────────────────

current_version() {
  grep '"version"' "$PLUGIN_JSON" | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/'
}

auto_bump() {
  local current="$1" bump_type="$2"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$current"
  case "$bump_type" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "${major}.$((minor + 1)).0" ;;
    patch) echo "${major}.${minor}.$((patch + 1))" ;;
  esac
}

die() { echo "error: $*" >&2; exit 1; }

# ── parse arg ────────────────────────────────────────────────────────────────

ARG="${1:-}"
if [[ -z "$ARG" ]]; then
  echo "Usage: bump-version.sh <version|patch|minor|major>"
  exit 1
fi

CURRENT=$(current_version)
[[ -n "$CURRENT" ]] || die "could not read current version from $PLUGIN_JSON"

case "$ARG" in
  patch|minor|major)
    NEW_VERSION=$(auto_bump "$CURRENT" "$ARG")
    ;;
  [0-9]*)
    NEW_VERSION="$ARG"
    ;;
  *)
    die "invalid argument '$ARG' — expected a version number or patch/minor/major"
    ;;
esac

# ── pre-flight ───────────────────────────────────────────────────────────────

# Warn if working tree is dirty (uncommitted changes other than the version files)
if ! git -C "$REPO_ROOT" diff --quiet HEAD; then
  echo "warning: working tree has uncommitted changes — they will NOT be included in the version bump commit."
  read -r -p "Continue anyway? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
fi

echo ""
echo "  Current version : $CURRENT"
echo "  New version     : $NEW_VERSION"
echo "  Tag             : v${NEW_VERSION}"
echo ""
read -r -p "Release title (e.g. 'Centralized Artifact Paths'): " RELEASE_TITLE
[[ -n "$RELEASE_TITLE" ]] || die "release title cannot be empty"
echo ""

# ── update JSON files ─────────────────────────────────────────────────────────

# macOS sed requires '' after -i; GNU sed accepts it too
sed -i '' "s/\"version\": \"${CURRENT}\"/\"version\": \"${NEW_VERSION}\"/" "$PLUGIN_JSON"
sed -i '' "s/\"version\": \"${CURRENT}\"/\"version\": \"${NEW_VERSION}\"/" "$MARKETPLACE_JSON"

echo "✓ Updated $PLUGIN_JSON"
echo "✓ Updated $MARKETPLACE_JSON"

# ── commit + push ─────────────────────────────────────────────────────────────

git -C "$REPO_ROOT" add "$PLUGIN_JSON" "$MARKETPLACE_JSON"
git -C "$REPO_ROOT" commit -m "chore: bump version to ${NEW_VERSION}"
git -C "$REPO_ROOT" push
echo "✓ Pushed version bump commit"

# ── GitHub release ────────────────────────────────────────────────────────────

REPO=$(gh -C "$REPO_ROOT" repo view --json nameWithOwner --jq '.nameWithOwner')

gh release create "v${NEW_VERSION}" \
  --repo "$REPO" \
  --title "v${NEW_VERSION} — ${RELEASE_TITLE}" \
  --generate-notes

echo ""
echo "✓ Released: https://github.com/${REPO}/releases/tag/v${NEW_VERSION}"
