---
name: review-rules
description: "Core 12-point review framework used across code-reviewer, build, and review agents — rule definitions, security coverage, team vs solo reviewer assignment"
user-invocable: false
disable-model-invocation: true
---

# Review Rules — 12-Point Canonical Definition

Single source of truth for the 12-point review framework used across `code-reviewer`, `build`, and `review`. Code examples: [`review-examples`](../review-examples/SKILL.md)

| # | Rule | Category | Look for |
| --- | --- | --- | --- |
| 1 | Functional Correctness | Correctness & Safety | Logic bugs, edge cases (n=0, null, empty), off-by-one, race conditions, security (injection, XSS, auth bypass, exposed secrets) |
| 2 | App Helpers & Util Functions | Correctness & Safety | Reinventing existing helpers — check project utils, framework built-ins, and shared libs before flagging |
| 3 | N+1 Prevention | Performance | Queries in loops, missing eager loading, unbounded fetches, missing pagination |
| 4 | DRY & Simplicity | Maintainability | Copy-paste variation, redundant logic, over-abstraction |
| 5 | Flatten Structure | Maintainability | Nesting > 1 level — use guard clauses, early returns |
| 6 | Small Functions & SOLID | Maintainability | Single responsibility, functions > 30 lines, god classes |
| 7 | Elegance | Maintainability | Idiomatic patterns for the stack, clean readable flow |
| 8 | Clear Naming | Developer Experience | Variables, functions, files — do they communicate intent? |
| 9 | Documentation & Comments | Developer Experience | Complex decisions explained, no stale comments, no over-commenting obvious code |
| 10 | Type Safety | Developer Experience | `any`/`unknown` usage, missing type guards, untyped external data |
| 11 | Testability | Developer Experience | Can the code be unit tested without heavy mocks? Behavior over implementation |
| 12 | Debugging Friendly | Developer Experience | Actionable error messages, no swallowed errors, no bare `console.log` in production |

## Security Coverage

Security is **part of Rule #1** (not a separate numbered rule) — covered at multiple layers to avoid duplication:

- **Hard Rules** (`reviewer-shared-rules.md`): no secrets, no raw SQL concat, no empty catch — bypass confidence filter, always reported
- **Security domain lens** (`review-lenses/security.md`): injected into team reviewers when diff touches auth/API/middleware — OWASP Top 10, JWT patterns, rate limiting
- **Rule #1 scope**: includes injection, XSS, auth bypass, and data exposure as correctness failures

## Team vs Solo Assignment

- **Solo** (`code-reviewer`): all 12 rules
- **Team** (`build` / `review`): per-role assignment in `review-conventions` § Reviewer Focus Areas
