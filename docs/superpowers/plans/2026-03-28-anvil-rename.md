# Plugin Rename: dev-loop → anvil — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename plugin from `dev-loop` to `anvil`, drop `dlc-` prefix from skills, bump to v1.0.0

**Architecture:** 8-phase rename: prerequisites → git mv → ordered string replacements → manual review → frontmatter → metadata → GitHub rename → verification. Replacements use `sed -i ''` (macOS) ordered most-specific-first to prevent partial matches.

**Tech Stack:** git, sed, grep, bash, `claude plugin validate`

**Spec:** `docs/superpowers/specs/2026-03-28-anvil-rename-design.md`

---

### Task 1: Prerequisites — collision check + version sync

**Files:**
- Modify: `.claude-plugin/marketplace.json:14`

- [ ] **Step 1: Check for name collision**

```bash
claude plugin search anvil
```

Expected: No plugin named `anvil` in results. If a conflict exists, **STOP** — the rename cannot proceed.

- [ ] **Step 2: Fix marketplace.json version mismatch**

marketplace.json is at `0.6.23`, plugin.json is at `0.7.1`. Sync them:

```bash
sed -i '' 's/"version": "0.6.23"/"version": "0.7.1"/' .claude-plugin/marketplace.json
```

- [ ] **Step 3: Verify version sync**

```bash
grep '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json
```

Expected: Both show `"version": "0.7.1"`

- [ ] **Step 4: Commit prerequisite fix**

```bash
git add .claude-plugin/marketplace.json
git commit -m "fix: sync marketplace.json version to 0.7.1"
```

---

### Task 2: Directory and file renames (13 git mv)

**Files:**
- Rename: 7 skill dirs, 3 agent files, 1 rule file, 1 eval doc, 1 agent-memory dir

- [ ] **Step 1: Rename skill directories**

```bash
git mv skills/dlc-build skills/build
git mv skills/dlc-review skills/review
git mv skills/dlc-respond skills/respond
git mv skills/dlc-debug skills/debug
git mv skills/dlc-metrics skills/metrics
git mv skills/dlc-onboard skills/onboard
git mv skills/dlc-status skills/status
```

- [ ] **Step 2: Rename agent files**

```bash
git mv agents/dlc-build-bootstrap.md agents/anvil-build-bootstrap.md
git mv agents/dlc-debug-bootstrap.md agents/anvil-debug-bootstrap.md
git mv agents/dlc-respond-bootstrap.md agents/anvil-respond-bootstrap.md
```

- [ ] **Step 3: Rename other files**

```bash
git mv .claude/rules/dlc-review-rules.md .claude/rules/anvil-review-rules.md
git mv docs/eval/dlc-eval-protocol.md docs/eval/anvil-eval-protocol.md
git mv .claude/agent-memory/dev-loop-skill-validator .claude/agent-memory/anvil-skill-validator
```

- [ ] **Step 4: Verify renames**

```bash
git status --short | head -30
```

Expected: All 13 renames show as `R` (renamed), no deletes/adds.

- [ ] **Step 5: Commit renames**

```bash
git add -A
git commit -m "refactor: rename directories and files for anvil identity (dev-loop → anvil)"
```

---

### Task 3: String replacements — high-specificity patterns

These are compound strings that must be replaced BEFORE their substrings. Uses `find` to build file lists excluding CHANGELOG and historical docs.

**Files:**
- Modify: ~20 files across hooks/, scripts/, skills/, agents/

- [ ] **Step 1: Build reusable file list (exclude CHANGELOG + historical docs)**

```bash
RENAME_FILES=$(find . -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' -o -name '*.bats' \) \
  ! -path './.git/*' \
  ! -name 'CHANGELOG.md' \
  ! -path './docs/superpowers/*' \
  ! -path './docs/references/research-*')
```

- [ ] **Step 2: Replace full concept name**

```bash
echo "$RENAME_FILES" | xargs sed -i '' 's/Development Loop Cycle (DLC)/anvil workflow/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/Development Loop Cycle/anvil workflow/g'
```

- [ ] **Step 3: Replace environment variables**

```bash
find . -type f \( -name '*.sh' -o -name '*.bats' \) ! -path './.git/*' | \
  xargs sed -i '' 's/DEV_LOOP_ARTIFACT_TTL_DAYS/ANVIL_ARTIFACT_TTL_DAYS/g'
find . -type f \( -name '*.sh' -o -name '*.bats' \) ! -path './.git/*' | \
  xargs sed -i '' 's/DEV_LOOP_USAGE_LOG/ANVIL_USAGE_LOG/g'
```

- [ ] **Step 4: Replace compound data path**

```bash
find . -type f \( -name '*.sh' -o -name '*.json' \) ! -path './.git/*' | \
  xargs sed -i '' 's/dev-loop-dev-loop/anvil-anvil/g'
```

- [ ] **Step 5: Replace XML tags**

```bash
find . -type f -name '*.sh' ! -path './.git/*' | \
  xargs sed -i '' 's/<dev-loop-pre-compact>/<anvil-pre-compact>/g'
find . -type f -name '*.sh' ! -path './.git/*' | \
  xargs sed -i '' 's/<\/dev-loop-pre-compact>/<\/anvil-pre-compact>/g'
find . -type f -name '*.sh' ! -path './.git/*' | \
  xargs sed -i '' 's/<dev-loop-reviewer-context>/<anvil-reviewer-context>/g'
find . -type f -name '*.sh' ! -path './.git/*' | \
  xargs sed -i '' 's/<\/dev-loop-reviewer-context>/<\/anvil-reviewer-context>/g'
```

- [ ] **Step 6: Replace artifact filenames**

```bash
echo "$RENAME_FILES" | xargs sed -i '' 's/dev-loop-context\.md/anvil-context.md/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-metrics\.jsonl/anvil-metrics.jsonl/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-checkpoint-iter-/anvil-checkpoint-iter-/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-build-workspace/anvil-build-workspace/g'
```

- [ ] **Step 7: Verify no high-specificity patterns remain**

```bash
grep -r "Development Loop Cycle\|DEV_LOOP\|dev-loop-dev-loop\|dev-loop-context\|dlc-metrics\.jsonl\|dev-loop-pre-compact\|dev-loop-reviewer-context" \
  --include="*.md" --include="*.sh" --include="*.json" --include="*.bats" \
  --exclude="CHANGELOG.md" --exclude-dir=".git" \
  | grep -v "docs/superpowers/" | grep -v "docs/references/research-"
```

Expected: 0 hits

- [ ] **Step 8: Commit high-specificity replacements**

```bash
git add -A
git commit -m "refactor: replace high-specificity patterns (env vars, XML tags, artifact names)"
```

---

### Task 4: String replacements — agent bootstrap names

Must run BEFORE `dlc-build` → `build` to prevent `dlc-build-bootstrap` becoming `build-bootstrap` instead of `anvil-build-bootstrap`.

**Files:**
- Modify: ~15 files across agents/, skills/, hooks/

- [ ] **Step 1: Replace bootstrap agent names**

```bash
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-build-bootstrap/anvil-build-bootstrap/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-debug-bootstrap/anvil-debug-bootstrap/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-respond-bootstrap/anvil-respond-bootstrap/g'
```

- [ ] **Step 2: Verify**

```bash
grep -r "dlc-.*-bootstrap" --include="*.md" --include="*.sh" --include="*.json" \
  --exclude="CHANGELOG.md" --exclude-dir=".git" | grep -v "docs/superpowers/"
```

Expected: 0 hits

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: rename bootstrap agent references"
```

---

### Task 5: String replacements — dlc-* skill names → unprefixed

The core rename: `dlc-build` → `build`, `dlc-review` → `review`, etc.

**Files:**
- Modify: ~70 files across entire repo

- [ ] **Step 1: Replace all 7 skill name patterns**

```bash
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-build/build/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-review/review/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-respond/respond/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-debug/debug/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-metrics/metrics/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-onboard/onboard/g'
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-status/status/g'
```

- [ ] **Step 2: Replace dlc-eval (keeps anvil- prefix since it's not a skill invocation)**

```bash
echo "$RENAME_FILES" | xargs sed -i '' 's/dlc-eval/anvil-eval/g'
```

- [ ] **Step 3: Replace DLC uppercase (word-boundary only)**

This MUST NOT match `CLAUDE_PLUGIN_DATA` or similar. Use word-boundary regex:

```bash
echo "$RENAME_FILES" | xargs sed -i '' 's/[[:<:]]DLC[[:>:]]/Anvil/g'
```

Note: `[[:<:]]` and `[[:>:]]` are macOS sed word-boundary anchors (equivalent to `\b` in GNU sed).

- [ ] **Step 4: Verify no dlc- or DLC patterns remain**

```bash
grep -r "dlc-" --include="*.md" --include="*.sh" --include="*.json" --include="*.bats" \
  --exclude="CHANGELOG.md" --exclude-dir=".git" \
  | grep -v "docs/superpowers/" | grep -v "docs/references/research-"

grep -rw "DLC" --include="*.md" --include="*.sh" --include="*.json" \
  --exclude="CHANGELOG.md" --exclude-dir=".git" \
  | grep -v "docs/superpowers/" | grep -v "docs/references/research-"
```

Expected: Both return 0 hits

- [ ] **Step 5: Spot-check that CLAUDE_PLUGIN_DATA was NOT corrupted**

```bash
grep "CLAUDE_PLUGIN" hooks/*.sh scripts/*.sh
```

Expected: All instances still say `CLAUDE_PLUGIN_DATA` and `CLAUDE_PLUGIN_ROOT` — not `CLAUAnvil_PLUGIN_DATA`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: replace dlc-* skill names and DLC acronym"
```

---

### Task 6: String replacements — dev-loop plugin name

Last replacement pass: `dev-loop` → `anvil` for all remaining instances.

**Files:**
- Modify: ~45 files

- [ ] **Step 1: Replace invocation prefix in README/docs**

```bash
echo "$RENAME_FILES" | xargs sed -i '' 's|/dev-loop:|/anvil:|g'
```

- [ ] **Step 2: Replace remaining dev-loop instances**

```bash
echo "$RENAME_FILES" | xargs sed -i '' 's/dev-loop/anvil/g'
```

- [ ] **Step 3: Verify no dev-loop remains**

```bash
grep -r "dev-loop" --include="*.md" --include="*.sh" --include="*.json" --include="*.bats" \
  --exclude="CHANGELOG.md" --exclude-dir=".git" \
  | grep -v "docs/superpowers/" | grep -v "docs/references/research-"
```

Expected: 0 hits

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: replace dev-loop plugin name with anvil"
```

---

### Task 7: Manual review — context-sensitive files

After global replacements, review files where naive replacement may produce incorrect text. Read each file and fix any awkward phrasing, broken references, or incorrect replacements.

**Files:**
- Review: hooks/hooks.json, .claude/settings.json, hooks/skill-routing.sh, hooks/pre-compact-save.sh, hooks/check-deps.sh, hooks/cleanup-artifacts.sh, hooks/session-end-cleanup.sh, hooks/skill-usage-tracker.sh, scripts/bump-version.sh, scripts/artifact-dir.sh, CONTRIBUTING.md, README.md, .gitignore, .markdownlintignore, output-styles/*.md, tests/hooks/skill_usage_tracker.bats, docs/eval/anvil-eval-protocol.md

- [ ] **Step 1: Review hooks/hooks.json**

Read file. Verify:
- `"description"` says "anvil" not "dev-loop"
- All `"matcher"` values: `"anvil"` (was `"dev-loop"`)
- `GATE_PATTERN='anvil|explore|implement|review|fix|finding'`
- `NUDGE_PATTERN='anvil'`

- [ ] **Step 2: Review .claude/settings.json**

Read file. Verify hook matchers match hooks.json exactly (these are duplicated).

- [ ] **Step 3: Review hooks/skill-routing.sh**

Read file. Verify keyword detection patterns route to new skill names (`build`, `review`, `respond`, `debug`, not `anvil-build` etc.).

- [ ] **Step 4: Review hooks/cleanup-artifacts.sh**

Read file. Verify env var fallback is backward-compatible:

```bash
TTL_DAYS="${ANVIL_ARTIFACT_TTL_DAYS:-${DEV_LOOP_ARTIFACT_TTL_DAYS:-7}}"
```

If not, add the backward-compat chain manually.

- [ ] **Step 5: Review hooks/skill-usage-tracker.sh**

Read file. Verify env var fallback:

```bash
LOG="${ANVIL_USAGE_LOG:-${DEV_LOOP_USAGE_LOG:-$DATA_DIR/skill-usage.tsv}}"
```

If not, add the backward-compat chain manually.

- [ ] **Step 6: Review remaining hook scripts**

Read `hooks/pre-compact-save.sh`, `hooks/check-deps.sh`, `hooks/session-end-cleanup.sh`. Verify:
- Echo messages say "anvil:" not "dev-loop:"
- XML tags say `<anvil-pre-compact>` not `<dev-loop-pre-compact>`
- All artifact path references use `anvil`

- [ ] **Step 7: Review scripts/**

Read `scripts/bump-version.sh`, `scripts/artifact-dir.sh`. Verify:
- `anvil@anvil` install commands (not `anvil@dev-loop`)
- Data path comments reference `anvil-anvil`

- [ ] **Step 8: Review CONTRIBUTING.md**

Read file. Verify:
- Clone URL: `wasikarn/anvil.git`
- Install command: `claude plugin install wasikarn/anvil`
- `cd anvil` (not `cd dev-loop`)
- Repo structure tree uses `anvil/` root
- Skill examples reference `skills/build/` not `skills/dlc-build/`

- [ ] **Step 9: Review .gitignore and .markdownlintignore**

Verify entries reference `anvil-build`, `anvil-debug`, `anvil-build-workspace`.

- [ ] **Step 10: Review output styles**

Read `output-styles/senior-software-engineer.md` and `output-styles/coding-mentor.md`. Confirm no dev-loop/DLC references (expected clean — per expert audit).

- [ ] **Step 11: Review test file**

Read `tests/hooks/skill_usage_tracker.bats`. Verify:
- `ANVIL_USAGE_LOG` env var name
- Test data uses `build`, `review` skill names (not `dlc-build`)

- [ ] **Step 12: Commit any manual fixes**

```bash
git add -A
git commit -m "fix: manual review corrections after global replacement"
```

---

### Task 8: SKILL.md frontmatter + cross-skill references

Verify all 7 renamed skills have correct `name:` frontmatter and cross-references use `/anvil:` invocation syntax.

**Files:**
- Modify: skills/build/SKILL.md, skills/review/SKILL.md, skills/respond/SKILL.md, skills/debug/SKILL.md, skills/metrics/SKILL.md, skills/onboard/SKILL.md, skills/status/SKILL.md
- Modify: All `skills/*/references/*.md` files with cross-skill invocations

- [ ] **Step 1: Verify name: frontmatter matches directory**

```bash
for d in skills/*/; do
  if [ -f "$d/SKILL.md" ]; then
    name=$(grep "^name:" "$d/SKILL.md" | head -1 | sed 's/name: *//')
    dir=$(basename "$d")
    if [ "$name" != "$dir" ]; then
      echo "MISMATCH: $d has name: '$name' (expected '$dir')"
    fi
  fi
done
```

Expected: No mismatches. If any exist, fix the `name:` field.

- [ ] **Step 2: Verify cross-skill invocations use /anvil: prefix**

```bash
grep -r "/build\b\|/review\b\|/respond\b\|/debug\b\|/metrics\b\|/onboard\b\|/status\b" \
  skills/ agents/ --include="*.md" | grep -v "/anvil:" | grep -v "git" | head -20
```

This finds bare `/build` references that should be `/anvil:build`. Fix any found.

- [ ] **Step 3: Verify description: fields in SKILL.md don't reference old names**

```bash
grep -A1 "^description:" skills/*/SKILL.md | grep -i "dlc\|dev-loop"
```

Expected: 0 hits. Fix any found.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "fix: verify and correct SKILL.md frontmatter and cross-references"
```

---

### Task 9: Metadata + version bump + README

**Files:**
- Modify: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `CLAUDE.md`

- [ ] **Step 1: Update plugin.json**

Read `.claude-plugin/plugin.json`. Update:
- `"name": "anvil"`
- `"description":` remove "DLC", use anvil language
- `"version": "1.0.0"`
- `"keywords":` replace `"dlc"` and `"dev-loop"` with `"anvil"`, `"multi-agent"`, `"agent-teams"`
- `"homepage":` → `https://github.com/wasikarn/anvil#readme`
- `"repository":` → `https://github.com/wasikarn/anvil`

- [ ] **Step 2: Update marketplace.json**

Read `.claude-plugin/marketplace.json`. Update root level AND `plugins[0].*` nested fields:
- Root: `"name": "anvil"`, description, version `"1.0.0"`
- `plugins[0]`: name, description, keywords, homepage, repository
- Version: `"1.0.0"` at both levels

- [ ] **Step 3: Update README.md badges**

Update badge URLs:
- Version: `version-1.0.0-blue`
- Skills: verify count
- Agents: verify count
- Hooks: verify count

- [ ] **Step 4: Add Foundry disclaimer to README**

Add after the first paragraph of the description or in the Quick Start section:

```markdown
> **Note:** This plugin is not related to [Foundry's anvil](https://github.com/foundry-rs/foundry) (Ethereum tooling).
```

- [ ] **Step 5: Update CLAUDE.md**

Read `CLAUDE.md`. Verify:
- Plugin name says `anvil`
- Skill table uses new names (`build`, `review`, etc.)
- Agent table uses new names (`anvil-build-bootstrap`, etc.)
- Install command: `claude plugin install anvil`
- All references updated

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: update metadata, version bump to 1.0.0, README badges"
```

---

### Task 10: Full verification

Run all verification checks from spec Phase 8.

- [ ] **Step 1: Grep for dlc- and DEV_LOOP**

```bash
grep -r "dlc-\|DEV_LOOP" --include="*.md" --include="*.sh" --include="*.json" --include="*.bats" \
  --exclude="CHANGELOG.md" --exclude-dir=".git" \
  | grep -v "docs/superpowers/" | grep -v "docs/references/research-"
```

Expected: 0 hits

- [ ] **Step 2: Grep for DLC (word-boundary)**

```bash
grep -rw "DLC" --include="*.md" --include="*.sh" --include="*.json" \
  --exclude="CHANGELOG.md" --exclude-dir=".git" \
  | grep -v "docs/superpowers/" | grep -v "docs/references/research-"
```

Expected: 0 hits

- [ ] **Step 3: Grep for dev-loop**

```bash
grep -r "dev-loop" --include="*.md" --include="*.sh" --include="*.json" --include="*.bats" \
  --exclude="CHANGELOG.md" --exclude-dir=".git" \
  | grep -v "docs/superpowers/" | grep -v "docs/references/research-"
```

Expected: 0 hits

- [ ] **Step 4: Plugin validation**

```bash
claude plugin validate
```

Expected: PASS

- [ ] **Step 5: QA suite**

```bash
bash scripts/qa-check.sh
```

Expected: PASS (or known failures unrelated to rename)

- [ ] **Step 6: Frontmatter name check**

```bash
for d in skills/*/; do
  name=$(grep "^name:" "$d/SKILL.md" 2>/dev/null | head -1 | sed 's/name: *//')
  dir=$(basename "$d")
  [ "$name" != "$dir" ] && echo "MISMATCH: $d has name: $name"
done
```

Expected: No mismatches

- [ ] **Step 7: Verify CLAUDE_PLUGIN vars not corrupted**

```bash
grep "CLAUDE_PLUGIN" hooks/*.sh scripts/*.sh
```

Expected: All say `CLAUDE_PLUGIN_DATA` / `CLAUDE_PLUGIN_ROOT` — no corruption

- [ ] **Step 8: Fix any remaining issues found above, commit**

```bash
git add -A
git commit -m "fix: address verification findings"
```

Skip this step if verification is clean.

---

### Task 11: Final commit + GitHub repo rename

- [ ] **Step 1: Squash or keep granular commits (user choice)**

Option A — squash all into one:
```bash
git reset --soft HEAD~8
git commit -m "feat!: rename plugin dev-loop → anvil, drop dlc- prefix, bump to v1.0.0

BREAKING CHANGE: Plugin renamed from dev-loop to anvil.
- Skills: dlc-build → build, dlc-review → review, etc.
- Invocation: /anvil:build (was /dev-loop:dlc-build)
- Env vars: ANVIL_ARTIFACT_TTL_DAYS (was DEV_LOOP_ARTIFACT_TTL_DAYS)
- Version: 1.0.0"
```

Option B — keep granular commits as-is.

- [ ] **Step 2: Push**

```bash
git push origin main
```

- [ ] **Step 3: Rename GitHub repo**

```bash
gh repo rename anvil
```

- [ ] **Step 4: Verify remote URL updated**

```bash
git remote get-url origin
```

Expected: `https://github.com/wasikarn/anvil.git` or `git@github.com:wasikarn/anvil.git`

If not updated automatically:
```bash
git remote set-url origin git@github.com:wasikarn/anvil.git
```

- [ ] **Step 5: Verify old URL redirects**

```bash
curl -sI https://github.com/wasikarn/dev-loop | head -5
```

Expected: `301` or `302` redirect to `wasikarn/anvil`
