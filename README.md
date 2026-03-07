# claude-code-skills

Personal collection of Claude Code skills (custom slash commands) for structured development workflows.

## Installation

Skills are symlinked from `~/.claude/skills/` — changes here take effect immediately in all Claude Code sessions.

```bash
bash scripts/link-skill.sh <name>   # link one skill
bash scripts/link-skill.sh          # link all skills
bash scripts/link-skill.sh --list   # check all symlinks
```

---

## Skills

### PR Review Skills (`*-review-pr`)

Three project-specific skills sharing the same architecture. Dispatch **7 parallel agents**, verify Jira AC, then fix code (Author) or submit inline GitHub review comments in Thai (Reviewer).

| Skill | Project | Tech Stack |
| ------- | --------- | ----------- |
| `/api-review-pr` | tathep-platform-api | AdonisJS 5.9 + Effect-TS + Japa |
| `/web-review-pr` | tathep-website | Next.js 14 Pages Router + Chakra UI + React Query |
| `/admin-review-pr` | tathep-admin | Next.js 14 Pages Router + Tailwind + Vitest |

**Usage:**

```bash
/api-review-pr 42              # PR #42, Author mode (fix code)
/api-review-pr 42 BEP-123      # with Jira ticket
/api-review-pr 42 Reviewer     # submit inline comments in Thai
/api-review-pr 42 BEP-123 Reviewer
```

**7 Agents dispatched in parallel (foreground, READ-ONLY):**

| Agent |
| ------- |
| `pr-review-toolkit:code-reviewer` |
| `pr-review-toolkit:comment-analyzer` |
| `pr-review-toolkit:pr-test-analyzer` |
| `pr-review-toolkit:silent-failure-hunter` |
| `pr-review-toolkit:type-design-analyzer` |
| `pr-review-toolkit:code-simplifier` |
| `feature-dev:code-reviewer` |

**12-Point Checklist:**

| # | Aspect |
| --- | -------- |
| 1 | Functional Correctness |
| 2 | Architecture / App Helpers |
| 3 | N+1 Prevention |
| 4 | DRY & Simplicity |
| 5 | Flatten Structure |
| 6 | SOLID & Clean Architecture |
| 7 | Elegance / Effect-TS Usage |
| 8 | Clear Naming |
| 9 | Documentation & Comments |
| 10 | Type Safety (TS Advanced Types) |
| 11 | Testability |
| 12 | Debugging Friendly |
| 13 | React/Next.js Performance *(web/admin only)* |

**QG Score:** starts 100 — Critical = −15, Important = −5, Suggestion = −1. Gate: 100 = PASS, 85–99 = CONDITIONAL, <85 = FAIL.

---

### `/spec-kit` — Spec-Driven Development

Full SDD workflow using [spec-kit](https://github.com/github/spec-kit). Guides through 6 steps from requirements to working code.

**6-Step Workflow:**

| Step | Command |
| ------ | --------- |
| 1 | `/speckit.constitution` |
| 2 | `/speckit.specify <what>` |
| 3 | `/speckit.clarify` |
| 4 | `/speckit.plan <tech stack>` |
| 5 | `/speckit.tasks` |
| 6 | `/speckit.implement` |

**Optional quality gates** (between steps 5–6):

- `/speckit.analyze` — cross-artifact consistency check (CRITICAL/HIGH/MEDIUM/LOW, max 50 findings, read-only)
- `/speckit.checklist` — requirement quality checklists (`checklists/[domain].md`)
- `/speckit.taskstoissues` — convert `tasks.md` to GitHub issues (requires GitHub MCP server)

**CLI:**

```bash
# Install
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Bootstrap
specify init my-project --ai claude
specify init --here --ai claude --ai-skills
```

---

### `/deep-research-workflow` — Research → Plan → Implement

Structured workflow for complex features requiring research before implementation. Produces a research report, architecture plan, and implementation steps.

---

### `/optimize-context` — CLAUDE.md Optimizer

Audit, score, and optimize CLAUDE.md files across a project. 5-phase workflow: Discovery → Quality Assessment → Audit → Generate Update → Apply & Verify.

---

## Integration Patterns

### ralph-loop + spec-kit

[Ralph Loop](https://ghuntley.com/ralph/) (iterative self-referential agent loop) pairs naturally with spec-kit because spec-kit produces **verifiable artifacts** — tasks.md checkboxes and SC-NNN success criteria — that serve as concrete completion signals.

**Best fit: automate Phase 6 (`/speckit.implement`)**

```bash
/ralph-loop:ralph-loop "Run /speckit.implement. After each session run tests.
If tests fail, fix them and continue.
Output DONE only when: all tasks.md items are [X], all tests pass,
and all SC-NNN in spec.md are satisfied." \
  --completion-promise "DONE" \
  --max-iterations 30
```

**Iterative spec quality loop:**

```bash
/ralph-loop:ralph-loop "Run /speckit.analyze.
If CRITICAL or HIGH findings exist, fix them in spec.md.
Output SPEC_CLEAN only when analyze reports zero CRITICAL/HIGH issues." \
  --completion-promise "SPEC_CLEAN" \
  --max-iterations 10
```

**Full-auto with phase detection:**

```bash
/ralph-loop:ralph-loop "Check current spec-kit phase:
bash ~/.claude/skills/spec-kit/scripts/detect-phase.sh
Execute the recommended next_action.
Output FEATURE_DONE only when current_step is 6_complete." \
  --completion-promise "FEATURE_DONE" \
  --max-iterations 50
```

**When to use ralph-loop per step:**

| Step | Ralph-loop? |
| ------ | ------------ |
| 1–3 (constitution/specify/clarify) | ❌ |
| 4 (plan) | ❌ |
| 5 (tasks) | ❌ |
| quality gates (analyze/checklist) | ✅ |
| 6 (implement) | ✅✅ |

**Tips:**

- Use SC-NNN from `spec.md` as completion criteria — already measurable
- Respect `[P]` markers in `tasks.md` to identify parallelizable work
- Always set `--max-iterations` as safety net
- Never ralph-loop steps requiring human input (specify/plan/clarify)

---

## Skill Structure

```text
skills/<name>/
  SKILL.md          # Main entry point (YAML frontmatter + workflow)
  CLAUDE.md         # Contributor context (architecture, validate commands, gotchas)
  references/       # Supporting docs referenced from SKILL.md
  scripts/          # Helper scripts
```

**SKILL.md frontmatter keys:**

```yaml
name: skill-name
description: "What it does. Use when: X, Y, Z."  # max 1024 chars — primary trigger
argument-hint: "[pr-number] [jira-key?] [Author|Reviewer]"
compatibility: "Requires gh CLI and git"          # optional: prerequisites
context: fork                       # Isolate in fork context (unsupported — test before use)
disable-model-invocation: true      # Remove from context; skill never auto-triggers
```
