# setup skill — contributor context

## Purpose

Post-install setup for devflow plugin. Installs `devflow-engine` dependencies via `bun install` and verifies the engine with a smoke test. Simpler than atlassian-pm/setup — no credentials, no MCP, no config files.

## Architecture

Single SKILL.md, no references/ needed — 5 phases fit within the file.

Idempotent design: Phase 1 detects state via bash flags (`BUN_OK`, `NODE_MODULES_OK`) and each phase skips work already done.

## Key Path

`PLUGIN_ROOT` is resolved from `${BASH_SOURCE[0]}` (hooks pattern) going up two levels from `skills/setup/`. Works correctly when invoked from any working directory.

## Smoke Test

`devflow-engine/smoke-test.ts` — validates all non-LLM components (diff-reader, domain-mapper, triage, consolidator, output, schemas, CLI args). Failures are warnings, not hard stops — skills degrade gracefully.

## Validate

```bash
npx markdownlint-cli2 "skills/setup/**/*.md"
claude plugin validate .
```
