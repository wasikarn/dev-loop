# DLC Status

Show active Development Loop Cycle artifacts from the current session.

Run this command now:

```bash
bash scripts/artifact-dir.sh 2>/dev/null || echo "no active DLC session"
```

Then check for artifact files:

```bash
ARTIFACT_DIR=$(bash scripts/artifact-dir.sh 2>/dev/null)
if [ -n "$ARTIFACT_DIR" ] && [ -d "$ARTIFACT_DIR" ]; then
  ls -lt "$ARTIFACT_DIR"/*.md 2>/dev/null || echo "No artifact files found"
fi
```

Report:

1. **Active session**: show artifact directory path
2. **Files present**: list each .md artifact with age (research.md, plan.md, etc.)
3. **Current phase**: infer from which files exist:
   - Only `research.md` → Phase 1 Research complete
   - `research.md` + `plan.md` → Phase 2 Plan complete
   - `research.md` + `plan.md` (no `review.md`) → Phase 3 Implementation in progress
   - `research.md` + `plan.md` + `review.md` → Phase 4+ Review/Ship in progress
4. If no artifacts: "No active DLC session — start one with /dlc-build"
