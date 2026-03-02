# 12-Point Review Checklist — tathep-website

**Severity:** 🔴 Critical (must fix) · 🟡 Important (should fix) · 🔵 Suggestion
**Format:** `[#N Aspect] file:line — issue → fix`

## Correctness & Safety

| # | Aspect | Check |
|---|--------|-------|
| 1 | **Functional Correctness** | `IFetchResult.isOk` checked before `.data` everywhere. Logic handles edge cases. |
| 2 | **App Helpers** | Use `@/shared/` barrels · `appConfig` for env vars · `ROUTE_PATHS` for routes · `useAuth()` · `useTranslations()` from `@/shared/libs/locale` (NOT next-intl) |

## Performance

| # | Aspect | Check |
|---|--------|-------|
| 3 | **N+1 Prevention** | No `.find()` inside `.map()` (O(n²)) · `keepPreviousData` disabled on filter changes · No unnecessary re-renders |

## Maintainability

| # | Aspect | Check |
|---|--------|-------|
| 4 | **DRY & Simplicity** | No duplicated mapping or logic — extract to shared util · No magic numbers/strings — use named constants · If logic appears 2+ times, extract it |
| 5 | **Flatten Structure** | Early returns / guard clauses instead of deep nesting · Max 2 levels of nesting in logic blocks · Avoid `else` after `return` |
| 6 | **Small Functions & SOLID** | Thin `*.page.tsx` → `PageContent` (data + UI) → module components · services extend `ApiBaseService` · Functions do ONE thing (≤20 lines) · No side effects in pure functions |
| 7 | **Elegance** | Chakra UI props over custom CSS · Tailwind for custom · idiomatic TypeScript · No clever tricks — obvious code wins · No dead code or unused vars |

## Developer Experience

| # | Aspect | Check |
|---|--------|-------|
| 8 | **Clear Naming** | `*.component.tsx` · `use-*.hook.ts` · `*.service.ts` · `*.map.ts` · `*.type.ts` conventions · Booleans: `is`/`has`/`can` prefix · Avoid abbreviations · Names reveal intent without comments |
| 9 | **Documentation** | No noise comments · complex/non-obvious logic documented · Comments explain *why*, not *what* · No commented-out code |
| 10 | **Type Safety** | No `any` · I-prefix interfaces · `*.map.ts` snake→camel · `IFetchResult<T>` pattern · **TypeScript Advanced Types**: Prefer generics over `any`; use discriminated unions (`\| { ok: true; data: T } \| { ok: false; error: E }`) over boolean flags; use branded types for IDs; use `unknown` for API responses then narrow with type guards; use utility types (`Partial`, `Pick`, `Omit`, `ReturnType`, `Awaited`) over manual re-declaration; avoid `as` assertions — use type guards instead |
| 11 | **Testability** | ≥80% coverage for changed files · Jest + RTL · Tests run in UTC (no hardcoded Thai TZ) · General solutions, not hardcoded values |
| 12 | **Debugging Friendly** | No empty `catch {}` · 401/403 auto-redirect respected · Errors surface clearly |

## React/Next.js Performance (#13)

> Pages Router project — App Router patterns (RSC, `React.cache()`, Server Components) do NOT apply.

**[next-best-practices] Rendering & Data Fetching:**

- `getStaticProps` for data that doesn't change per-request · `getServerSideProps` only when truly dynamic
- No async waterfall — fetch in parallel: `Promise.all([fetchA(), fetchB()])`
- `next/image` for all `<img>` tags — required `width`/`height` or `fill` · no raw `<img>` for user-uploaded content
- `next/link` for all internal navigation — no `<a href="...">` for client-side routes
- `next/dynamic` for heavy components (charts, editors, maps) with `{ ssr: false }` if needed

**[vercel-react-best-practices] React Performance:**

- No inline object/array in JSX: `<Comp style={{ color: 'red' }} />` → extract to constant or `useMemo`
- No inline function passed as prop to memoized children: `<Comp onClick={() => fn(id)} />` → `useCallback`
- `useMemo` only for expensive computations (not as default) · don't memoize primitives
- Stable list keys — never use array index for dynamic/reorderable lists
- Avoid unnecessary `useEffect` — derive state instead of syncing it
- Split contexts by update frequency: fast-changing values in separate context from slow ones
- `React.memo` for pure components that receive same props frequently
- `useRef` for values that should NOT trigger re-render (timers, DOM refs, prev values)

**Bundle Optimization:**

- No barrel imports that pull large unused modules (`import { X } from '@/shared'` is fine; `import * from '@/shared'` is not)
- Heavy third-party libs via `next/dynamic` — not top-level import
- No `console.log` in production code

## tathep-website Specific Checks

Always verify:

- [ ] Mapper consumers consistent after type changes (`grep -r "mapFnName" src/`)
- [ ] `getLayout` pattern used for page layouts
- [ ] `ROUTE_PATHS` used — no hardcoded `/manage/...`
- [ ] `useTranslations()` from `@/shared/libs/locale` (NOT next-intl)
- [ ] Phone PII in `sessionStorage` only (not localStorage) during OTP flow
- [ ] `*.page.tsx` naming for all page files
- [ ] 7 providers order preserved in `_providers/providers.provider.tsx`
- [ ] OFetch default — Axios only for uploads with progress tracking
- [ ] `keepPreviousData` disabled when filter params change
