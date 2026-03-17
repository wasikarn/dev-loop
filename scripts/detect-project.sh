#!/usr/bin/env bash
# detect-project.sh — Detect tathep project from git remote and output config JSON.
# Usage: bash detect-project.sh [project-root]
# Output: {"project":"...","repo":"...","validate":"...","base_branch":"...","branch":"...","hints":"..."}
# If validate is empty for unknown projects, the caller should ask the user for a validate command.
#
# Compatible with bash 3.x (macOS default).

set -euo pipefail

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT" 2>/dev/null || true

# Get current branch
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# Get remote URL and extract repo slug
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
REPO_SLUG=$(echo "$REMOTE_URL" | sed 's/.*[:/]\([^/]*\/[^.]*\).*/\1/' 2>/dev/null || echo "")

# Match against known projects
PROJECT="unknown"
REPO=""
VALIDATE=""
BASE_BRANCH="main"
HINTS=""

case "$REMOTE_URL" in
  *bd-eye-platform-api*)
    PROJECT="tathep-platform-api"
    REPO="100-Stars-Co/bd-eye-platform-api"
    VALIDATE="npm run validate:all"
    BASE_BRANCH="develop"
    HINTS="Clean Architecture (Domain/Application/Infrastructure), Effect-TS pipes, Japa tests, AdonisJS 5.9, Lucid ORM, check for N+1 queries and missing indexes"
    ;;
  *bluedragon-eye-website*)
    PROJECT="tathep-website"
    REPO="100-Stars-Co/bluedragon-eye-website"
    VALIDATE="npm run ts-check && npm run lint:fix && npm test"
    BASE_BRANCH="develop"
    HINTS="Next.js 14 Pages Router, Chakra UI, React Query v3, Firebase Auth, SSR patterns, getServerSideProps/getStaticProps"
    ;;
  *bluedragon-eye-admin*)
    PROJECT="tathep-admin"
    REPO="100-Stars-Co/bluedragon-eye-admin"
    VALIDATE="npm run ts-check && npm run lint:fix && npm run test"
    BASE_BRANCH="develop"
    HINTS="Next.js 14 Pages Router, Tailwind, Headless UI, Vitest, admin dashboard patterns, role-based access"
    ;;
  *tathep-ai-agent-python*)
    PROJECT="tathep-ai-agent"
    REPO="100-Stars-Co/tathep-ai-agent-python"
    VALIDATE="uv run black --check . && uv run mypy ."
    BASE_BRANCH="develop"
    HINTS="Python, uv package manager, mypy strict typing, async patterns"
    ;;
  *tathep-video-processing*)
    PROJECT="tathep-video"
    REPO="100-Stars-Co/tathep-video-processing"
    VALIDATE="bun run check && bun run test"
    BASE_BRANCH="develop"
    HINTS="Bun runtime, video processing pipelines, worker patterns"
    ;;
esac

# Auto-detection fallback for unknown projects
if [ "$PROJECT" = "unknown" ] && [ -z "$VALIDATE" ]; then
  # Try package.json scripts
  if [ -f "package.json" ]; then
    # Look for common validate script names in order of preference
    if grep -q '"validate:all"' package.json 2>/dev/null; then
      VALIDATE="npm run validate:all"
    elif grep -q '"validate"' package.json 2>/dev/null; then
      VALIDATE="npm run validate"
    elif grep -q '"test"' package.json 2>/dev/null && grep -q '"typecheck"\|"ts-check"\|"type-check"' package.json 2>/dev/null; then
      VALIDATE="npm run typecheck && npm test"
    elif grep -q '"test"' package.json 2>/dev/null; then
      VALIDATE="npm test"
    fi
    # Detect package manager (bun preferred if bun.lockb exists)
    if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
      VALIDATE="${VALIDATE/npm/bun}"
    fi
  # Try pyproject.toml (Python/uv)
  elif [ -f "pyproject.toml" ]; then
    if grep -q '\[tool.pytest\|pytest' pyproject.toml 2>/dev/null; then
      VALIDATE="uv run pytest"
    else
      VALIDATE="uv run python -m py_compile *.py"
    fi
  # Try Makefile
  elif [ -f "Makefile" ]; then
    if grep -q '^test:' Makefile 2>/dev/null; then
      VALIDATE="make test"
    elif grep -q '^validate:' Makefile 2>/dev/null; then
      VALIDATE="make validate"
    fi
  fi
  # Use repo slug as project name if available
  if [ -n "$REPO_SLUG" ]; then
    PROJECT=$(basename "$REPO_SLUG")
    REPO="$REPO_SLUG"
  fi
fi

# Build JSON manually (no jq dependency)
echo "{\"project\":\"${PROJECT}\",\"repo\":\"${REPO}\",\"validate\":\"${VALIDATE}\",\"base_branch\":\"${BASE_BRANCH}\",\"branch\":\"${BRANCH}\",\"hints\":\"${HINTS}\"}"
