---
name: df-status
description: "Show active devflow workflow artifacts from the current session — artifact directories, current phase, and pending actions. Triggers: status, session status, active artifacts, current phase, workflow state."
argument-hint: ""
---

# Devflow Status

Display active devflow workflow artifacts from the current session, showing artifact directory, files present, and inferred phase.

## Artifact Types

| File | Purpose | Created In |
|------|---------|------------|
| `research.md` | Codebase exploration findings | Phase 1: Research |
| `plan.md` | Implementation plan with steps | Phase 2: Plan |
| `devflow-context.md` | Session context (Jira AC, decisions) | Phase 0: Bootstrap |
| `review.md` | Review findings table | Phase 5: Review |
| `debug-context.md` | Debug session context | Phase 0: Debug Bootstrap |
| `falsification.md` | Falsification results | Phase 7: Falsification |

## Phase Inference Logic

The current phase is inferred from which artifacts exist:

| Artifacts Present | Phase | Status |
|-------------------|-------|--------|
| None | — | No active session |
| `devflow-context.md` only | Phase 0 | Bootstrap complete, waiting to start |
| `research.md` only | Phase 1 | Research complete |
| `research.md` + `plan.md` | Phase 2-3 | Plan complete, implementation in progress |
| `research.md` + `plan.md` + `review.md` | Phase 5+ | Review in progress or complete |
| `debug-context.md` | — | Debug session active |

## Execution

Run the artifact directory detection script:

```bash
bash "${CLAUDE_SKILL_DIR}/../../scripts/artifact-dir.sh" 2>/dev/null || echo "no active Devflow session"
```

Then check for artifact files:

```bash
ARTIFACT_DIR=$(bash "${CLAUDE_SKILL_DIR}/../../scripts/artifact-dir.sh" 2>/dev/null)
if [ -n "$ARTIFACT_DIR" ] && [ -d "$ARTIFACT_DIR" ]; then
  ls -lt "$ARTIFACT_DIR"/*.md 2>/dev/null || echo "No artifact files found"
fi
```

## Report Format

```text
📁 Active Session: ~/.claude/artifacts/build-2024-01-15-abc123/

📄 Artifacts:
├─ devflow-context.md (2 hours ago)
├─ research.md (1 hour ago)
└─ plan.md (30 minutes ago)

📍 Current Phase: Phase 2-3 (Plan complete, implementation in progress)

⏭️  Next Steps:
├─ Review research.md for context
├─ Check plan.md for remaining tasks
└─ Continue implementation or run /devflow:build to resume
```

## Use Cases

- **Resume work**: Check where you left off
- **Handoff**: Show session state to another developer
- **Debug**: Identify which phase produced artifacts
- **Cleanup**: Find stale artifact directories

## Gotchas

- Artifacts are session-scoped (one per build/review/debug session)
- Directory naming: `~/.claude/artifacts/{workflow}-{date}-{id}/`
- If no artifacts found, suggest starting a new session with `/devflow:build`
