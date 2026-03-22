# Hook Test

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
