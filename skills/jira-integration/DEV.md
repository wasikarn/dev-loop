# jira-integration skill

Library skill providing shared Jira context injection — key detection, ticket fetch, AC extraction, and skill-specific integration patterns for `review`, `build`, `debug`, and `respond`.

## Skill Architecture

- `SKILL.md` only — this file IS the reference document loaded by 4 consumer skills
- `user-invocable: false`, `disable-model-invocation: true` — never auto-triggers
- Four skill-specific sections: `review` (AC verification), `build` (scope & planning), `debug` (bug enrichment), `respond` (thread prioritization)
- Fetch order: `issue-bootstrap` agent (atlassian-pm) → `mcp-atlassian` fallback → warn + skip
- Non-blocking design: Jira unavailability never halts a consumer skill run

## Validate After Changes

```bash
npx markdownlint-cli2 "skills/jira-integration/SKILL.md"

# Verify all 4 consumers still reference this skill
grep -r "jira-integration" skills/review/ skills/build/ skills/debug/ skills/respond/
```

## Gotchas

- Changes affect all 4 consumer skills simultaneously — review each skill-specific section (`## review`, `## build`, `## debug`, `## respond`) against the actual workflow phase numbers in each consumer before merging.
- The 3-tier AC mapping heuristic (Single-file / Multi-file / Architectural AC) in the `review` section is nuanced — "Architectural AC" must never be Critical if no concrete implementation was expected in the PR.
- Phase injection points are exact: `review` Phase 0.05, `build` Phase 0 Step 2.5, `debug` Phase 0 Step 1.5, `respond` Phase 0 Step 0.5. If a consumer skill refactors its phases, update the step reference here.
- `issue-bootstrap` agent availability depends on the `atlassian-pm` plugin being installed — the detection note ("bundles `jira-cache-server` MCP server") must stay accurate as atlassian-pm evolves.
- Non-blocking is intentional and must be preserved — adding a hard-fail path for Jira errors would break review/build runs in environments without Jira access.
