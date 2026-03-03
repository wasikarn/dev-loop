# 12-Point Review Checklist — tathep-platform-api

For ✅/❌ code examples → [examples.md](examples.md)

**Severity:** 🔴 Critical (must fix) · 🟡 Important (should fix) · 🔵 Suggestion
**Format:** `[#N Aspect] file:line — issue → fix`

## Correctness & Safety

| # | Aspect |
| --- | -------- |
| 1 | **Functional Correctness** |
| 2 | **Architecture Layers** |

## Performance

| # | Aspect |
| --- | -------- |
| 3 | **N+1 Prevention** |

## Maintainability

| # | Aspect |
| --- | -------- |
| 4 | **DRY & Simplicity** |
| 5 | **Flatten Structure** |
| 6 | **SOLID & Clean Architecture** |
| 7 | **Effect-TS Usage** |

## Developer Experience

| # | Aspect |
| --- | -------- |
| 8 | **Clear Naming** |
| 9 | **Documentation** |
| 10 | **Type Safety** |
| 11 | **Testability** |
| 12 | **Debugging Friendly** |

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

| Layer |
| ------- |
| Route |
| Controller |
| UseCase |
| Repository |
| Validator |
| Test |
