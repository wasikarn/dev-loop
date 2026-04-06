---
name: df-audit
description: "Audit project for security vulnerabilities and dependency CVEs. Modes: --deps (dependency vulnerability scan via npm audit / pip-audit / cargo audit), --security (OWASP Top 10 + business logic scan using security-reviewer agent), --all (both). Use for pre-release security reviews, compliance checks, or when adding new dependencies. Triggers: security audit, CVE scan, vulnerability check, npm audit, dependency audit, OWASP, security review."
argument-hint: "[--deps|--security|--all] [path?]"
effort: high
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Audit

Run a security audit on the project. Default (no args): runs `--all`.

Parse `$ARGUMENTS` to determine mode and optional path:

- `--deps` → dependency vulnerability scan only
- `--security` → codebase security scan only (spawns security-reviewer agent)
- `--all` or no args → both in sequence
- Optional path argument → scope security scan to that path (default: codebase root)

## Mode: --deps

Detect the package manager and run the appropriate audit tool:

**Node.js** (detect `package.json`):

```bash
npm audit --json 2>/dev/null | jq '{
  metadata: .metadata,
  critical: [.vulnerabilities | to_entries[] | select(.value.severity == "critical") | {name: .key, severity: .value.severity, via: .value.via, fixAvailable: .value.fixAvailable}],
  high: [.vulnerabilities | to_entries[] | select(.value.severity == "high") | {name: .key, severity: .value.severity, via: .value.via, fixAvailable: .value.fixAvailable}]
}'
```

If `jq` is not available, run `npm audit` without JSON and parse text output.

**Python** (detect `requirements.txt` or `pyproject.toml`):

```bash
pip-audit --format json 2>/dev/null || pip-audit
```

**Rust** (detect `Cargo.toml`):

```bash
cargo audit --json 2>/dev/null || cargo audit
```

**Report format for --deps:**

List Critical and High CVEs in a table:

| Package | Severity | CVE | Description | Fix |
| --- | --- | --- | --- | --- |

Then:

- Total counts: Critical: N, High: N, Moderate: N
- Fix suggestion: `npm audit fix` for auto-fixable, manual upgrade for others
- If no vulnerabilities: "No known vulnerabilities found."

## Mode: --security

Spawn `security-reviewer` agent with the target path:

```text
Spawn agent: security-reviewer
Task: Perform a full security audit on [path or "the entire codebase"].
  - Scan for OWASP Top 10 vulnerabilities
  - Detect hardcoded secrets and credentials
  - Trace data flows from user input to sinks (DB, shell, HTML, file)
  - Identify business logic vulnerabilities
  - Report findings by severity: CRITICAL, HIGH, MEDIUM, LOW
```

Wait for agent to complete and present its findings table.

## Mode: --all

Run `--deps` first, then `--security`. Present both reports in sequence with clear section headers:

```markdown
## Dependency Vulnerabilities
[deps output]

## Code Security Findings
[security-reviewer output]

## Summary
Critical issues requiring immediate action: N
```

## Security Checklist

The security-reviewer agent checks OWASP Top 10 vulnerabilities and common patterns:

- **Authentication**: Password storage, session tokens, JWT secrets
- **Input Validation**: SQL injection, XSS, file uploads
- **Data Protection**: Encryption, secrets in code, logs
- **API Security**: Rate limiting, CORS, status codes
- **Infrastructure**: Dependency CVEs, security headers, HTTPS
- **Business Logic**: Rate limits, idempotency, state validation

See [references/security-checklist.md](references/security-checklist.md) for the full checklist.

## After Audit

If any CRITICAL or HIGH findings:

1. List them as a prioritized action plan
2. Suggest: "Run `/build` to fix the highest-severity issues, or address manually"

If clean:

- "No critical or high severity issues found. Project is audit-clean."
