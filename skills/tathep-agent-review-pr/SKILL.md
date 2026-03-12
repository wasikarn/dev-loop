---
name: tathep-agent-review-pr
description: "PR review skill for tathep-ai-agent-python (Python 3.12 + FastAPI + LangGraph + SQLAlchemy QB + mypy strict). Dispatches 7 parallel specialized agents, verifies Jira AC, then fixes issues (Author) or submits inline comments (Reviewer). Triggers: review PR, check PR, code review, /tathep-agent-review-pr."
argument-hint: "[pr-number] [jira-key?] [Author|Reviewer]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(gh *), Bash(git *)
compatibility: "Requires gh CLI and git. Run from within the tathep-ai-agent-python repo."
---

# PR Review — tathep-ai-agent-python

Invoke as `/tathep-agent-review-pr [pr-number] [jira-key?] [Author|Reviewer]`

**PR:** #$0 | **Jira:** $1 | **Mode:** $2 (default: Author)
**Today:** !`date +%Y-%m-%d`
**Diff stat:** !`git diff develop...HEAD --stat 2>/dev/null | tail -10`
**PR title:** !`gh pr view $0 --json title,body,labels,author --jq '{title,body,labels: [.labels[].name],author: .author.login}' 2>/dev/null`
**PR comments:** !`gh pr view $0 --comments --json comments --jq '[.comments[] | {author: .author.login, body: .body[:200]}]' 2>/dev/null`
**Changed files:** !`gh pr diff $0 --name-only 2>/dev/null`

**Args:** `$0`=PR# (required) · `$1`=Jira key or Author/Reviewer · `$2`=Author/Reviewer
**Role:** Tech Lead — improve code health via architecture, mentoring, team standards. Not a linter. Explain *why*, cite patterns, respect valid approaches.

Read CLAUDE.md first — auto-loaded, contains full project patterns and conventions.

## Project Config

| Key | Value |
| --- | --- |
| GitHub repo | `100-Stars-Co/tathep-ai-agent-python` |
| Validate | `uv run black --check . && uv run mypy .` |
| Scope | `git diff develop...HEAD` |
| Reference modules | `modules/conversation/` (CQRS + repository), `shared/libs/invoke_with_fallback.py` (LLM resilience) |

## References

| File | Content |
| --- | --- |
| [review-workflow.md](../../references/review-workflow.md) | Shared phase workflow — follow this |
| [checklist.md](references/checklist.md) | 12-point review criteria |
| [examples.md](references/examples.md) | Project-specific code examples |
| [review-output-format.md](../../references/review-output-format.md) | Output format |
| [review-conventions.md](../../references/review-conventions.md) | Comment labels, dedup, strengths |

## Hard Rules

Flag unconditionally — no confidence filter, always report:

- `Any` type annotation → Critical (destroys type safety — mypy strict mode forbids it; use specific types or generics)
- bare `except:` or `except Exception:` without re-raise → Critical (swallows all errors including KeyboardInterrupt — always specify exception type)
- `print()` statement → Critical (use `logger` from `shared.libs.logging.logger` — print output vanishes in production)
- missing type hints on function signature → Critical (mypy `disallow_untyped_defs=True` — will fail type check)
- `model.invoke()` without fallback in production agent → Critical (use `invoke_with_fallback()` — single model failure takes down the agent)
- hardcoded model name string outside `get_model()` → Critical (use `get_model("provider/model")` — centralizes model config)
- raw `try/except` with broad `except` where structured `ErrorMessage` pattern exists → Critical (use project error handling patterns — broad catches hide error categories)
- `import *` (wildcard import) → Critical (pollutes namespace — always import specific names)
- query inside loop (N+1) → Critical (batch or preload — exponential DB load)
- nesting > 1 level → Critical (use guard clauses, extract function, or lookup dict — deep nesting buries the happy path)

`feature-dev:code-reviewer` applies Python type hint best practices (generics, Protocol, TypedDict, dataclasses — NO `Any`), Clean Code principles (SRP, early returns, naming intent, function size), and LangGraph patterns (StateGraph, Command/Send, structured output).

## Project Constraints

- Flag changed files with missing tests (Critical)
- **Python project** — all code examples and patterns are Python, not TypeScript

## Reviewer Examples

**Comment style:** Thai mixed with English technical terms — casual Slack/PR tone.
Examples: "ใช้ `invoke_with_fallback()` แทน `model.invoke()` ตรงนี้ด้วยนะครับ", "ขาด type hint ตรงนี้ mypy จะ fail", "N+1 อยู่ ลอง batch query ดูครับ"

**Strengths:** "ใช้ invoke_with_fallback ครบ", "TypedDict state ชัดเจน", "tool docstring ครบทุก function"

---

**Read [review-workflow.md](../../references/review-workflow.md) and follow the phase workflow.** Use the Project Config, Hard Rules, and References above as inputs.
