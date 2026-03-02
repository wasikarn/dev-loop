# 12-Point Review Checklist — tathep-platform-api

**Severity:** 🔴 Critical (must fix) · 🟡 Important (should fix) · 🔵 Suggestion
**Format:** `[#N Aspect] file:line — issue → fix`

## Correctness & Safety

| # | Aspect | Check |
|---|--------|-------|
| 1 | **Functional Correctness** | Logic handles edge cases · No forbidden patterns: `as any`, `as unknown as T`, `throw new Error()`, `.innerJoin()`, `try {} catch {}` (silent) |
| 2 | **Architecture Layers** | Controller thin → delegates to UseCase only · UseCase has all business logic · Repository has all data access · DI via `@inject([InjectPaths.X])` — no `new MyService()` |

## Performance

| # | Aspect | Check |
|---|--------|-------|
| 3 | **N+1 Prevention** | Use `model.rel ?? await model.related('rel').query().first()` · No `.innerJoin()` — use `subquery/whereHas` · No unnecessary queries |

## Maintainability

| # | Aspect | Check |
|---|--------|-------|
| 4 | **DRY & Simplicity** | No duplicated business logic — extract to Services or Helpers · No magic numbers/strings — use named constants · If logic appears 2+ times, extract it |
| 5 | **Flatten Structure** | Early returns / guard clauses instead of deep nesting · Max 2 levels of nesting in logic blocks · Avoid `else` after `return`/`throw` |
| 6 | **SOLID & Clean Architecture** | Controller: thin · UseCase: orchestration · Repository: data access only · Provider: dynamic imports via `ModulePaths.ts` (not global) · Functions do ONE thing (≤20 lines) · No side effects in pure functions |
| 7 | **Effect-TS Usage** | Import from `App/Helpers/Effect` (branded, Option, Either, match, concurrency) · `TryCatch` from `App/Helpers/TryCatch` · Use `Effect.pipe()` for composition · `Option` for nullable values (not `null \| undefined`) |

## Developer Experience

| # | Aspect | Check |
|---|--------|-------|
| 8 | **Clear Naming** | PascalCase files (`MyService.ts`) · InjectPaths use `'IClassName'` (short, interface-style) · New Job files registered in `start/jobs.ts` · Booleans: `is`/`has`/`can` prefix · Avoid abbreviations (`usr` → `user`) · Names reveal intent without comments |
| 9 | **Documentation** | No noise comments · complex/non-obvious logic documented · Comments explain *why*, not *what* · No commented-out code |
| 10 | **Type Safety** | Absolutely no `as any` or `as unknown as T` · Typed mocks: `createStubObj<IMyRepo>()` not `as any` casts · `fromPartial<Model>()` for partial instances · **TypeScript Advanced Types**: Prefer generics over `any`; use discriminated unions (`type Result = \| { ok: true; data: T } \| { ok: false; error: E }`) over boolean flags; use branded types for domain IDs (`type UserId = string & { readonly _brand: 'UserId' }`); use `unknown` for external data then narrow with type guards (`if ('field' in x)`) rather than `as` assertions; use utility types (`Partial`, `Required`, `Pick`, `Omit`, `ReturnType`) over manual re-declaration |
| 11 | **Testability** | Tests added for changed files · Japa tests (not Jest) · Parallel-safe tests · Transaction isolation pattern used · No `as any` in tests |
| 12 | **Debugging Friendly** | Use `ModuleException.type()` — not `throw new Error('msg')` · No silent `try {} catch {}` · No PII in logs · Auth middleware applied (`auth:adminApi`, `auth:publicApi`, `playerAuth`, `apiKey`) |

## tathep-platform-api Specific Checks

Always verify:

- [ ] **Forbidden patterns absent**: `as any`, `as unknown as T`, `throw new Error`, `new MyService()`, string InjectPaths `'App/Services/X'`, `.innerJoin()`, empty `catch {}`
- [ ] **DI correct**: `@inject([InjectPaths.X])` · InjectPaths use `'IClassName'` format
- [ ] **Provider imports**: via `ModulePaths.ts` relative paths — not global `'App/...'` strings
- [ ] **Query style**: `subquery` or `whereHas` — never `JOIN`
- [ ] **Error handling**: `ModuleException.type()` for domain errors
- [ ] **Test isolation**: `Database.beginGlobalTransaction()` / `rollbackGlobalTransaction()` + `sinon.restore()`
- [ ] **Test type safety**: `createStubObj<IMyRepo>({ method: sinon.stub() })` — typed mocks
- [ ] **New Job files**: registered in `start/jobs.ts`
- [ ] **Security**: Input via Validator · no PII in logs · auth middleware correct
- [ ] **Reference module**: `Sms/` for gold standard patterns, `Questionnaire/` for simple module patterns

## Jira Ticket → Layer Mapping

| Layer | Files |
|-------|-------|
| Route | `start/routes/` |
| Controller | `app/Controllers/` or `app/Modules/{Name}/Controllers/` |
| UseCase | `app/UseCases/` or `app/Modules/{Name}/UseCases/` |
| Repository | `app/Repositories/` or `app/Modules/{Name}/Repositories/` |
| Validator | `app/Validators/` or `app/Modules/{Name}/Validators/` |
| Test | `tests/unit/`, `tests/integration/`, `tests/functional/` |
