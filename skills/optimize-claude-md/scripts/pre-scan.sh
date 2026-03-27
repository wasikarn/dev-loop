#!/usr/bin/env bash
# pre-scan.sh — Collect all Phase 1 metadata in one pass.
# Output: compact JSON to stdout. Run before starting optimize-claude-md workflow.
# Usage: bash skills/optimize-claude-md/scripts/pre-scan.sh [project-root]
#
# Replaces ~5 separate agent reads with one script. Saves ~2-4k tokens per run.

set -euo pipefail
ROOT="${1:-.}"
cd "$ROOT"

# ── Helpers ───────────────────────────────────────────────────────────────────
json_str() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'; }

# ── CLAUDE.md files (stat for total, awk for human — single file read each) ──
files_json="["
first_file=1
while IFS= read -r f; do
  total=$(stat -f%z "$f" 2>/dev/null || wc -c < "$f" | tr -d ' ')
  human=$(awk '!/claude-mem-context/ { h += length($0) + 1 } END { print h+0 }' "$f" 2>/dev/null || echo "$total")
  [[ $first_file -eq 0 ]] && files_json+=","
  files_json+="{\"path\":\"$(json_str "$f")\",\"bytes\":$total,\"human_bytes\":$human}"
  first_file=0
done < <(find . \( -name "CLAUDE.md" -o -name ".claude.local.md" -o -name ".claude.md" \) \
           ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | sort)
files_json+="]"

# ── Framework + npm scripts (single python3 parse — checks both deps + devDeps) ──
framework="none"
fw_version="unknown"
npm_scripts="{}"

if [[ -f "package.json" ]]; then
  pkg_out=$(python3 - <<'PY' 2>/dev/null || printf 'none\nunknown\n{}'
import json, sys
try:
    p = json.load(open('package.json'))
    deps = {**p.get('dependencies', {}), **p.get('devDependencies', {})}
    fw, ver = 'none', 'unknown'
    for pkg, fw_name in [('next','nextjs'),('@nestjs/core','nestjs'),('express','express'),('react','react')]:
        if pkg in deps:
            fw, ver = fw_name, deps[pkg]
            break
    print(fw)
    print(ver)
    print(json.dumps(p.get('scripts', {})))
except Exception:
    print('none'); print('unknown'); print('{}')
PY
)
  line_num=0
  while IFS= read -r line; do
    ((line_num++)) || true
    case $line_num in
      1) framework="$line" ;;
      2) fw_version="$line" ;;
      3) npm_scripts="$line" ;;
    esac
  done <<< "$pkg_out"
fi

# ── Python / Go fallback ──────────────────────────────────────────────────────
if [[ "$framework" == "none" ]]; then
  for req_file in requirements.txt pyproject.toml setup.py; do
    if [[ -f "$req_file" ]]; then
      framework="python"
      grep -qi "django"  "$req_file" 2>/dev/null && framework="django"
      grep -qi "fastapi" "$req_file" 2>/dev/null && framework="fastapi"
      break
    fi
  done
fi

if [[ "$framework" == "none" && -f "go.mod" ]]; then
  framework="go"
  fw_version=$(awk '/^go / {print $2; exit}' go.mod || echo "unknown")
fi

# ── Directory structure (2 levels, excluding common noise) ───────────────────
dir_json=$(find . -maxdepth 2 \
  ! -path "*/node_modules*" ! -path "*/.git*" ! -path "*/.next*" \
  ! -path "*/dist*" ! -path "*/build*" ! -path "*/__pycache__*" \
  ! -path "*/.turbo*" 2>/dev/null | sort | head -80 \
  | python3 -c "import sys,json; print(json.dumps([l.rstrip() for l in sys.stdin if l.strip()]))" \
  2>/dev/null || echo "[]")

# ── Supplementary paths ───────────────────────────────────────────────────────
has_agent_docs="false"; [[ -d "agent_docs" ]] && has_agent_docs="true"
has_claude_rules="false"; [[ -d ".claude/rules" ]] && has_claude_rules="true"

# ── Output ────────────────────────────────────────────────────────────────────
printf '{"claude_files":%s,"framework":{"name":"%s","version":"%s"},"npm_scripts":%s,"dir_structure":%s,"has_agent_docs":%s,"has_claude_rules":%s}\n' \
  "$files_json" \
  "$(json_str "$framework")" \
  "$(json_str "$fw_version")" \
  "$npm_scripts" \
  "$dir_json" \
  "$has_agent_docs" \
  "$has_claude_rules"
