---
paths:
  - "devflow-sdk/**"
---

# Devflow SDK Conventions

TypeScript SDK at `devflow-sdk/` — programmatic PR review pipeline. `private: true`, not published to npm.

**Tech stack:** TypeScript strict · vitest · tsx for running

**Structure:**

```text
devflow-sdk/src/
├── review/        # orchestrator, triage, consolidator, falsifier, domain-mapper, output
├── cli.ts         # CLI entry point (tsx src/cli.ts review|falsify|plan-challenge)
├── config.ts      # configuration
└── types.ts       # shared types
```

**Commands:**

| Task | Command |
| --- | --- |
| Run tests | `cd devflow-sdk && npm test` |
| Watch tests | `cd devflow-sdk && npm run test:watch` |
| Run CLI review | `cd devflow-sdk && npm run review -- --pr <number>` |

**Rules:**

- No `any` types — use proper TypeScript generics
- Each domain module has a corresponding `.test.ts` file
- Test behavior not implementation — mock only external I/O (gh CLI, git)
- CLI exits with code 0 on success, 1 on fatal error — structured JSON output on stdout
- SDK is a fallback/accelerator for Agent Teams — it complements, doesn't replace agents
