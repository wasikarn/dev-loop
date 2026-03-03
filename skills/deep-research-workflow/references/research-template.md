# Research: [Feature Name]

## Scope

What we're investigating and why. Link to issue/ticket if applicable.

## Summary

_One paragraph TL;DR of key findings. Write last, after all sections below are complete. This is the re-entry point if context is compacted — read this first._

## Codebase Analysis

### [Area 1 — e.g. "Authentication middleware"]

- **Files examined:** `src/middleware/auth.ts`, `src/utils/jwt.ts`
- **Execution path:** request → middleware → jwt.verify() → req.user → handler
- **Key patterns:** uses passport strategy, tokens stored in httpOnly cookies
- **Conventions:** error responses use `AppError` class, status codes from `constants/http.ts`

### [Area 2 — e.g. "Database layer"]

- **Files examined:** ...
- **Execution path:** ...
- **Key patterns:** ...
- **Conventions:** ...

## Existing Implementations

Code and patterns that can be reused or referenced as specification:

| Pattern | Location |
| --- | --- |
| CRUD endpoint | `src/routes/users.ts` |
| Validation schema | `src/schemas/user.schema.ts` |

## Key Decisions

Decisions discovered during research that will directly shape the plan:

- **[Decision topic]:** [What was found and what it implies for the implementation]
- **[Decision topic]:** ...

## Constraints & Gotchas

- Things that could break if changed
- Non-obvious coupling between modules
- Performance-sensitive paths
- External service dependencies/limitations

## Open Questions

- [ ] Unresolved items needing clarification from user or team
- [ ] Ambiguities in requirements
- [ ] Technical decisions that need input
