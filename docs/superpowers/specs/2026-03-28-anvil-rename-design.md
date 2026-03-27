# Plugin Rename: dev-loop → anvil

**Date:** 2026-03-28
**Version:** 0.7.1 → 1.0.0
**Type:** Breaking rename — full identity change

## Problem

"dev-loop" and "DLC" (Development Loop Cycle) no longer fit the plugin:

1. **Not descriptive** — sounds like a generic dev tool, doesn't convey multi-agent orchestration
2. **Scope evolved** — plugin is far beyond "loop": Agent Teams, adversarial debate, falsification, hooks, output styles
3. **DLC confusion** — "DLC" universally means "Downloadable Content" in gaming; abbreviation clashes
4. **Anvilttable** — doesn't stand out from other dev plugins

## Solution

Rename to **forge** — short, punchy, metaphor for shaping raw material through heat and pressure into something strong. Maps directly to what the plugin does: code goes through structured phases (build → review → debate → respond → debug) and comes out refined.

**Key design decision:** Drop the `dlc-` prefix entirely. Skills become `build`, `review`, etc. — namespaced under the `anvil` plugin. Invocation: `/anvil:build` instead of `/dev-loop:dlc-build`.

## Rename Mapping

### Names

| Element | Current | New |
| --- | --- | --- |
| Plugin name | `dev-loop` | `anvil` |
| Concept name | "Development Loop Cycle (DLC)" | _(removed — no acronym)_ |
| Skill prefix | `dlc-*` | _(removed — no prefix)_ |
| GitHub repo | `wasikarn/dev-loop` | `wasikarn/anvil` |
| Version | `0.7.1` | `1.0.0` |

### Skills (7 directory renames)

| Current | New | Invocation |
| --- | --- | --- |
| `skills/dlc-build/` | `skills/build/` | `/anvil:build` |
| `skills/dlc-review/` | `skills/review/` | `/anvil:review` |
| `skills/dlc-respond/` | `skills/respond/` | `/anvil:respond` |
| `skills/dlc-debug/` | `skills/debug/` | `/anvil:debug` |
| `skills/dlc-metrics/` | `skills/metrics/` | `/anvil:metrics` |
| `skills/dlc-onboard/` | `skills/onboard/` | `/anvil:onboard` |
| `skills/dlc-status/` | `skills/status/` | `/anvil:status` |

### Agents (3 file renames — keep `anvil-` prefix for agent context clarity)

| Current | New |
| --- | --- |
| `agents/dlc-build-bootstrap.md` | `agents/anvil-build-bootstrap.md` |
| `agents/dlc-debug-bootstrap.md` | `agents/anvil-debug-bootstrap.md` |
| `agents/dlc-respond-bootstrap.md` | `agents/anvil-respond-bootstrap.md` |

### Other file renames (3)

| Current | New |
| --- | --- |
| `.claude/rules/dlc-review-rules.md` | `.claude/rules/anvil-review-rules.md` |
| `docs/eval/dlc-eval-protocol.md` | `docs/eval/anvil-eval-protocol.md` |
| `.claude/agent-memory/dev-loop-skill-validator/` | `.claude/agent-memory/anvil-skill-validator/` |

### Artifact / runtime names

| Current | New |
| --- | --- |
| `dev-loop-context.md` | `anvil-context.md` |
| `dlc-metrics.jsonl` | `anvil-metrics.jsonl` |
| `dlc-checkpoint-iter-*` (git tags) | `anvil-checkpoint-iter-*` |
| `.claude/dlc-build/` (.gitignore) | `.claude/anvil-build/` |
| `.claude/dlc-debug/` (.gitignore) | `.claude/anvil-debug/` |
| `dlc-build-workspace/` (.markdownlintignore) | `anvil-build-workspace/` |
| `~/.claude/plugins/data/dev-loop-dev-loop/` | `~/.claude/plugins/data/anvil-anvil/` |

### Environment variables (breaking — users may have set these)

| Current | New |
| --- | --- |
| `DEV_LOOP_ARTIFACT_TTL_DAYS` | `ANVIL_ARTIFACT_TTL_DAYS` |
| `DEV_LOOP_USAGE_LOG` | `ANVIL_USAGE_LOG` |

**Backward compat:** Add fallback in scripts: `${ANVIL_ARTIFACT_TTL_DAYS:-${DEV_LOOP_ARTIFACT_TTL_DAYS:-7}}`

## Blast Radius

### Inventory (from exhaustive grep + expert audit)

| Pattern | Files affected |
| --- | --- |
| `dlc-` (prefix) | 78 files |
| `dev-loop` (plugin name) | 45 files |
| `DLC` (uppercase acronym) | 16 files |
| `Development Loop Cycle` | 2 files |
| `DEV_LOOP_*` (env vars) | 3 files + 1 test |
| `dev-loop-context.md` (artifact) | ~35 locations |
| `dlc-metrics.jsonl` | ~20 locations |
| `dev-loop-dev-loop` (data path) | 4 files |
| `/dev-loop:` (invocation prefix) | ~40 locations in README |
| Hook matchers (`dev-loop`) | 2 files, 4 entries |
| XML tags (`<dev-loop-*>`) | 2 files (subagent-start-context.sh, pre-compact-save.sh) |

**Total unique files requiring changes:** ~90 (excluding CHANGELOG.md)

### Files explicitly EXCLUDED from rename

- `CHANGELOG.md` — historical records preserved as-is (established convention from v0.7.1)
- `docs/superpowers/specs/2026-03-27-dev-loop-adaptive-ceremony-design.md` — historical spec
- `docs/superpowers/plans/2026-03-27-dev-loop-adaptive-ceremony-gaps.md` — historical plan
- `docs/references/research-*.md` — historical research notes (exclude from rename, add to grep exclusion)

## Execution Plan

### Phase 1: Prerequisites

1. **Name collision check:** `claude plugin search anvil` — must return no conflicts. This is a **blocking gate**.
2. **Version sync:** Fix `marketplace.json` version from `0.6.23` to match `plugin.json` `0.7.1` before starting rename.
3. **Foundry disclaimer:** Note that "anvil" is also used by Foundry (Ethereum tooling) — add brief clarification in README.

### Phase 2: Directory and file renames (git mv)

Skill directories (7):

```bash
git mv skills/dlc-build skills/build
git mv skills/dlc-review skills/review
git mv skills/dlc-respond skills/respond
git mv skills/dlc-debug skills/debug
git mv skills/dlc-metrics skills/metrics
git mv skills/dlc-onboard skills/onboard
git mv skills/dlc-status skills/status
```

Agent files (3):

```bash
git mv agents/dlc-build-bootstrap.md agents/anvil-build-bootstrap.md
git mv agents/dlc-debug-bootstrap.md agents/anvil-debug-bootstrap.md
git mv agents/dlc-respond-bootstrap.md agents/anvil-respond-bootstrap.md
```

Other (3):

```bash
git mv .claude/rules/dlc-review-rules.md .claude/rules/anvil-review-rules.md
git mv docs/eval/dlc-eval-protocol.md docs/eval/anvil-eval-protocol.md
git mv .claude/agent-memory/dev-loop-skill-validator .claude/agent-memory/anvil-skill-validator
```

**Total: 13 git mv operations**

### Phase 3: Global string replacements

Execute in this order (most specific → least specific to avoid partial matches).

**CRITICAL:** Step 21 (`DLC` → `Anvil`) MUST use word-boundary matching (`\bDLC\b`) to avoid corrupting `CLAUDE_PLUGIN_DATA`, `CLAUDE_PLUGIN_ROOT`, etc.

**CRITICAL:** All `dlc-` → replacement steps MUST be global (all occurrences per line), not first-match-only. This is required for lines like `dev-loop@dev-loop` → `anvil@anvil`.

| Order | Find | Replace | Scope |
| --- | --- | --- | --- |
| 1 | `Development Loop Cycle (DLC)` | `anvil workflow` | all .md, .json |
| 2 | `Development Loop Cycle` | `anvil workflow` | all .md |
| 3 | `DEV_LOOP_ARTIFACT_TTL_DAYS` | `ANVIL_ARTIFACT_TTL_DAYS` | .sh, .bats |
| 4 | `DEV_LOOP_USAGE_LOG` | `ANVIL_USAGE_LOG` | .sh, .bats |
| 5 | `dev-loop-dev-loop` | `anvil-anvil` | .sh, .json |
| 6 | `<dev-loop-pre-compact>` | `<anvil-pre-compact>` | .sh |
| 7 | `</dev-loop-pre-compact>` | `</anvil-pre-compact>` | .sh |
| 8 | `<dev-loop-reviewer-context>` | `<anvil-reviewer-context>` | .sh |
| 9 | `</dev-loop-reviewer-context>` | `</anvil-reviewer-context>` | .sh |
| 10 | `dev-loop-context.md` | `anvil-context.md` | all |
| 11 | `dlc-metrics.jsonl` | `anvil-metrics.jsonl` | all |
| 12 | `dlc-checkpoint-iter-` | `anvil-checkpoint-iter-` | all .md |
| 13 | `dlc-build-workspace` | `anvil-build-workspace` | .markdownlintignore |
| 14 | `dlc-build-bootstrap` | `anvil-build-bootstrap` | all |
| 15 | `dlc-debug-bootstrap` | `anvil-debug-bootstrap` | all |
| 16 | `dlc-respond-bootstrap` | `anvil-respond-bootstrap` | all |
| 17 | `dlc-build` | `build` | all (excl. CHANGELOG) |
| 18 | `dlc-review` | `review` | all (excl. CHANGELOG) |
| 19 | `dlc-respond` | `respond` | all (excl. CHANGELOG) |
| 20 | `dlc-debug` | `debug` | all (excl. CHANGELOG) |
| 21 | `dlc-metrics` | `metrics` | all (excl. CHANGELOG) |
| 22 | `dlc-onboard` | `onboard` | all (excl. CHANGELOG) |
| 23 | `dlc-status` | `status` | all (excl. CHANGELOG) |
| 24 | `dlc-eval` | `anvil-eval` | all |
| 25 | `\bDLC\b` | `Anvil` | all (excl. CHANGELOG) — word-boundary, case-sensitive |
| 26 | `/dev-loop:` | `/anvil:` | README, docs |
| 27 | `dev-loop` | `anvil` | all (excl. CHANGELOG) — remaining instances |

### Phase 4: Context-sensitive manual review

After global replacements, these files need **manual verification** because replacements may produce awkward or incorrect text:

| File | Why |
| --- | --- |
| `hooks/hooks.json` | Verify GATE_PATTERN, NUDGE_PATTERN, all matcher values |
| `.claude/settings.json` | Duplicate hook entries — must match hooks.json exactly |
| `hooks/skill-routing.sh` | Keyword detection patterns — verify routing logic |
| `hooks/pre-compact-save.sh` | XML tags, DLC→Anvil in comments, artifact paths |
| `hooks/check-deps.sh` | User-visible messages: "anvil: Missing Dependencies" |
| `hooks/cleanup-artifacts.sh` | Env var fallback + echo messages |
| `hooks/session-end-cleanup.sh` | Echo messages |
| `hooks/skill-usage-tracker.sh` | Env var fallback + data path comment |
| `scripts/bump-version.sh` | `anvil@anvil` install commands |
| `scripts/artifact-dir.sh` | Data path comments and fallback |
| `CONTRIBUTING.md` | 10+ refs: clone URL, install command, repo structure tree, skill examples |
| `README.md` | Badges, install commands, all `/anvil:build` invocations, Foundry disclaimer |
| `.gitignore` | `.claude/anvil-build/`, `.claude/anvil-debug/` entries |
| Output styles (`output-styles/*.md`) | Check for any dev-loop/DLC refs |
| `skills/*/SKILL.md` (all 7 renamed) | Verify `name:` frontmatter matches new dir name (e.g., `name: build`) |
| `tests/hooks/skill_usage_tracker.bats` | Env var name + test data skill names |
| `docs/eval/anvil-eval-protocol.md` | Content references to old names |

### Phase 5: SKILL.md frontmatter updates

Since prefixes are dropped, every renamed skill's `name:` field changes:

| File | Old `name:` | New `name:` |
| --- | --- | --- |
| `skills/build/SKILL.md` | `dlc-build` | `build` |
| `skills/review/SKILL.md` | `dlc-review` | `review` |
| `skills/respond/SKILL.md` | `dlc-respond` | `respond` |
| `skills/debug/SKILL.md` | `dlc-debug` | `debug` |
| `skills/metrics/SKILL.md` | `dlc-metrics` | `metrics` |
| `skills/onboard/SKILL.md` | `dlc-onboard` | `onboard` |
| `skills/status/SKILL.md` | `dlc-status` | `status` |

Cross-skill references also change: e.g., "Run `/dlc-build`" → "Run `/anvil:build`" throughout all SKILL.md and reference files.

### Phase 6: Metadata updates

- `plugin.json`: name, description (remove "DLC"), keywords, homepage → `wasikarn/anvil`, repository
- `marketplace.json`: name, description, keywords, homepage, repository — **nested structure** (root level + `plugins[0].*`)
- Version bump: `0.7.1` → `1.0.0` in both files
- `README.md`: title, badges (version, hooks count), install commands, Foundry note

### Phase 7: GitHub repo rename

```bash
gh repo rename anvil
```

Update all URL references: `wasikarn/dev-loop` → `wasikarn/anvil`

### Phase 8: Verification

```bash
# Must return 0 hits
grep -r "dlc-\|DEV_LOOP" --include="*.md" --include="*.sh" --include="*.json" --include="*.bats" \
  --exclude="CHANGELOG.md" \
  --exclude-dir=".git" \
  | grep -v "docs/superpowers/" \
  | grep -v "docs/references/research-"

# Word-boundary DLC check (exclude CHANGELOG, historical docs)
grep -rw "DLC" --include="*.md" --include="*.sh" --include="*.json" \
  --exclude="CHANGELOG.md" \
  --exclude-dir=".git" \
  | grep -v "docs/superpowers/" \
  | grep -v "docs/references/research-"

# dev-loop check
grep -r "dev-loop" --include="*.md" --include="*.sh" --include="*.json" --include="*.bats" \
  --exclude="CHANGELOG.md" \
  --exclude-dir=".git" \
  | grep -v "docs/superpowers/" \
  | grep -v "docs/references/research-"

# Plugin validation
claude plugin validate

# QA suite
bash scripts/qa-check.sh

# Verify all skill frontmatter names match directories
for d in skills/*/; do
  name=$(grep "^name:" "$d/SKILL.md" 2>/dev/null | head -1 | sed 's/name: *//')
  dir=$(basename "$d")
  [ "$name" != "$dir" ] && echo "MISMATCH: $d has name: $name"
done
```

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| `anvil` name already taken | Blocks rename | **Phase 1 gate:** `claude plugin search anvil` |
| Foundry (Ethereum) name collision | User confusion | Add disclaimer in README: "Not related to Foundry's anvil (Ethereum dev tool)" |
| Existing installs break | Users must reinstall | GitHub redirect handles old URLs; README migration note |
| `DEV_LOOP_*` env var users | Silent config loss | Backward-compat fallback: `${ANVIL_*:-${DEV_LOOP_*:-default}}` |
| Partial replacement leaves broken refs | Runtime errors | Phase 7 multi-pattern grep verification |
| `\bDLC\b` replacement hits wrong targets | Corrupted env vars | Word-boundary matching only; manual review in Phase 3 |
| CHANGELOG references look broken | Cosmetic | Excluded by convention — historical records stay |
| Orphaned `~/.claude/plugins/data/dev-loop-dev-loop/` | Wasted disk | Users can manually delete; not worth migration hook for personal plugin |
| claude-mem/QMD old references | Degraded recall | Self-heal over time as new sessions accumulate |
| `marketplace.json` nested structure missed | Broken marketplace listing | Phase 5 explicitly lists root + `plugins[0].*` fields |

## Not in Scope

- CHANGELOG.md content changes (historical)
- Historical spec/plan docs in `docs/superpowers/` (filenames preserved)
- Historical research docs in `docs/references/research-*.md` (excluded from rename)
- External systems (claude-mem observations, QMD indexes) — self-heal over time
- Renaming `review-*` background skills (not prefixed with dlc-, not affected)
- Deprecation release (0.8.0) — personal plugin, small user base, direct to 1.0.0
- Dead cross-ref `dlc-workflow-quality-improvements-round2-design.md` in 3 files — pre-existing broken link, fix opportunistically
