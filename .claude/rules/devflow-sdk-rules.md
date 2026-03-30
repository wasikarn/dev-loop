---
paths:
  - "devflow-engine/**"
---

# Devflow Engine Conventions

TypeScript engine at `devflow-engine/` — programmatic PR review pipeline. `private: true`, not published to npm.

**Tech stack:** TypeScript strict · bun test (built-in) · Bun for running

**Structure:**

```text
devflow-engine/src/
├── review/        # orchestrator, triage, consolidator, falsifier, domain-mapper, output
├── cli.ts         # CLI entry point (bun src/cli.ts review|falsify|plan-challenge)
├── config.ts      # configuration
└── types.ts       # shared types
```

**Commands:**

| Task | Command |
| --- | --- |
| Run tests | `cd devflow-engine && bun test` |
| Watch tests | `cd devflow-engine && bun test --watch` |
| Run CLI review | `cd devflow-engine && bun run review -- --pr <number>` |

**Rules:**

- No `any` types — use proper TypeScript generics
- Each domain module has a corresponding `.test.ts` file
- Test behavior not implementation — mock only external I/O (gh CLI, git)
- CLI exits with code 0 on success, 1 on fatal error — structured JSON output on stdout
- Engine is a fallback/accelerator for Agent Teams — it complements, doesn't replace agents
