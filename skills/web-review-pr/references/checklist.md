# 12-Point Review Checklist — tathep-website

For ✅/❌ code examples → [examples.md](examples.md)

**Severity:** 🔴 Critical (must fix) · 🟡 Important (should fix) · 🔵 Suggestion
**Format:** `[#N Aspect] file:line — issue → fix`

## Correctness & Safety

| # | Aspect |
| --- | -------- |
| 1 | **Functional Correctness** |
| 2 | **App Helpers** |

## Performance

| # | Aspect |
| --- | -------- |
| 3 | **N+1 Prevention** |

## Maintainability

| # | Aspect |
| --- | -------- |
| 4 | **DRY & Simplicity** |
| 5 | **Flatten Structure** |
| 6 | **Small Functions & SOLID** |
| 7 | **Elegance** |

## Developer Experience

| # | Aspect |
| --- | -------- |
| 8 | **Clear Naming** |
| 9 | **Documentation** |
| 10 | **Type Safety** |
| 11 | **Testability** |
| 12 | **Debugging Friendly** |

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
