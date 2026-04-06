---
name: df-setup
description: "Post-install setup for devflow plugin — installs devflow-engine dependencies (bun install) and runs a smoke test. Idempotent: detects what is already configured and skips those steps. Triggers: devflow-setup, /devflow-setup, devflow setup, bun install engine. Use after plugin install or reinstall. Do NOT use for project onboarding (use /onboard instead)."
argument-hint: ""
effort: low
allowed-tools: Bash
---

# /df-setup

Post-install setup for the `devflow` plugin. Idempotent — safe to re-run.

## Phase 1 — Detect State

Run as a **single Bash call** to detect current state before taking any action.

```bash
ENGINE_DIR="${CLAUDE_SKILL_DIR}/../../devflow-engine"

BUN_OK=false
ENGINE_DIR_OK=false
NODE_MODULES_OK=false

command -v bun > /dev/null 2>&1 && BUN_OK=true
[ -d "$ENGINE_DIR" ] && ENGINE_DIR_OK=true
[ -d "$ENGINE_DIR/node_modules" ] && NODE_MODULES_OK=true

echo "BUN_OK=$BUN_OK"
echo "ENGINE_DIR_OK=$ENGINE_DIR_OK"
echo "NODE_MODULES_OK=$NODE_MODULES_OK"
echo "ENGINE_DIR=$(cd "$ENGINE_DIR" 2>/dev/null && pwd || echo "$ENGINE_DIR")"
```

**Fast path:** If `BUN_OK=true` AND `NODE_MODULES_OK=true` → skip Phases 2–3, jump to Phase 4 (smoke test only).

Print fast path message: `"devflow-engine already configured — running smoke test to verify..."`

**Engine missing entirely:** If `ENGINE_DIR_OK=false` → abort with:

```text
✗ devflow-engine directory not found at: $ENGINE_DIR
  This should not happen after a normal plugin install.
  Try reinstalling: claude plugin install devflow
```

## Phase 2 — Install Bun (if missing)

**Skip if `BUN_OK=true`.** Print `"  bun: already installed ✓"` and continue.

If `BUN_OK=false`, install Bun:

```bash
echo "Installing bun..."
curl -fsSL https://bun.sh/install | bash
```

After install, source the profile to make `bun` available in the current session:

```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

Verify:

```bash
if command -v bun > /dev/null 2>&1; then
  echo "  bun $(bun --version): installed ✓"
else
  echo "ERROR: bun install failed. Install manually: https://bun.sh"
  exit 1
fi
```

## Phase 3 — Install Engine Dependencies (if missing)

**Skip if `NODE_MODULES_OK=true`.** Print `"  devflow-engine/node_modules: already installed ✓"` and continue.

If `NODE_MODULES_OK=false`:

```bash
echo "Installing devflow-engine dependencies..."
cd "$ENGINE_DIR" && bun install
```

Verify:

```bash
if [ -d "$ENGINE_DIR/node_modules" ]; then
  echo "  devflow-engine dependencies: installed ✓"
else
  echo "ERROR: bun install failed. Check output above for details."
  exit 1
fi
```

## Phase 4 — Smoke Test

Run the engine smoke test to verify all non-LLM components work:

```bash
echo "Running smoke test..."
cd "$ENGINE_DIR" && bun smoke-test.ts 2>&1
SMOKE_EXIT=$?
```

- Exit 0 → print `"  smoke test: all checks passed ✓"`
- Exit non-0 → print the output and warn:

```text
⚠️  Smoke test had failures (see output above).
    The engine may not work correctly. Check devflow-engine/ for issues.
    Core devflow skills (build, review, debug) will fall back to rule-based mode.
```

Do NOT abort — a smoke test failure is a warning, not a hard stop. Skills degrade gracefully without the engine.

## Phase 5 — Summary

```text
✅ devflow setup complete

  ✓  bun                  <version>
  ✓  devflow-engine       dependencies installed
  ✓  smoke test           <N> passed

→ /onboard    bootstrap this project (creates hard-rules.md + artifact dirs)
→ /build      start a coding task with full research → plan → implement loop
→ /review     adversarial PR review with 3-reviewer debate
```

If smoke test failed, replace the smoke test line with:

```text
  ⚠️  smoke test          had failures — engine running in degraded mode
```
