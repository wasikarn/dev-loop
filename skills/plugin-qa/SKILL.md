---
name: plugin-qa
description: "Run the full QA check suite to verify hooks, skills, and plugin structure are healthy. Use when validating the devflow plugin, before publishing, after adding skills/hooks, or when something seems broken. Triggers: validate plugin, check hooks, verify skills, health check, is devflow working, plugin broken, something wrong with devflow, /plugin-qa."
disable-model-invocation: true
effort: low
---

# Plugin QA

Run the QA check suite to verify all hooks, skills, and plugin structure are healthy.

Run this command now:

```bash
bash scripts/qa-check.sh 2>&1
```

Report findings:

1. List every check that **passed** ✓
2. List every check that **failed** ✗ with the specific error
3. List checks that were **skipped** and what tool to install to enable them
4. Conclude: "QA PASSED" or "QA FAILED — N issues need attention"

If any check failed, offer to fix each issue one by one.

## Common Failures and Fixes

| Failure | Fix |
| --- | --- |
| Markdownlint errors | Run `npx markdownlint-cli2 --fix "**/*.md"` then re-check |
| `hooks.json` parse error | Validate JSON syntax in `hooks/hooks.json` |
| Missing symlink | Run `bash scripts/link-assets.sh` to re-link |
| `plugin validate` error | Check `plugin.json` manifest for required fields |
| shellcheck warnings | Fix the flagged shell script lines — warnings = real bugs |

If all checks pass but behavior is still broken: restart Claude Code (hooks load at session start, not dynamically).
