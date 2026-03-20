# Performance Review Lens

Inject into reviewer prompts when diff touches: data fetching, list rendering, event handlers, caching, or any hot path code.

```text
PERFORMANCE LENS (active for this review):

ALGORITHMIC COMPLEXITY:
- Nested loop over same/related collection → O(n²): build Map/Set for O(1) lookup
  Pattern: `.find()` / `.filter()` inside `.map()` → single-pass with Map
- Sort inside a loop → hoist; repeated `.filter()` on same array → single pass
- Unbounded accumulation: `results.push()` in loop with no cap/break

NODE.JS EVENT LOOP (backend — flag any sync op in request path):
- `fs.readFileSync` / `execSync` / `spawnSync` → async equivalents
- CPU-intensive on main thread (image processing, large JSON.parse >1MB, crypto hash
  loops, regex on large strings) → offload to `worker_threads`
- Large data loaded into memory fully: `fs.readFile` on multi-MB files → stream instead
  Pattern: `fs.createReadStream()` piped through transform, never `readFile` + buffer

ASYNC PATTERNS:
- Sequential `await` on independent ops → `Promise.all([a(), b()])`
- User-input async without debounce/throttle (search, autocomplete, scroll)
- Promise returned but neither awaited nor `.catch()`-ed → silent failure

REACT RENDERING (frontend only):
- Expensive component re-renders on unrelated parent state → `React.memo`
- Filtered/sorted arrays or callbacks passed to memoized children → `useMemo`/`useCallback`
- `setState` in `useEffect` with missing/unstable deps → infinite re-render

MEMORY:
- Event listener without cleanup: `removeEventListener` / `AbortController`
- Large object captured in closure outliving component lifecycle
- Stream not `.destroy()`-ed on error path

BUNDLE SIZE (frontend only):
- `import _ from 'lodash'` → `import debounce from 'lodash/debounce'` or `lodash-es`
- Barrel `index.ts` re-exporting everything → blocks tree-shaking
- Heavy dep on non-critical path without `lazy()` / dynamic `import()`

CORE WEB VITALS (frontend — INP replaced FID, March 2024):
- LCP: above-fold `<img>` without `<Image priority>` (Next.js) or `fetchpriority="high"`
- INP (<200ms): long sync work in click handler → `scheduler.postTask()` or yield with `setTimeout(0)`
- CLS: element without reserved dimensions, content injected above fold

TYPESCRIPT COMPILATION (flag in PR touching type definitions):
- Conditional type on large string literal union (>20 members) without intermediate alias
- Recursive type depth >3 without named intermediate → compiler cannot cache
- `as any` in type positions to "fix" slow compilation → find root type cause instead

EXISTING (conf ≥75):
- N+1: DB query in loop → batch / eager load
- Unbounded query: collection endpoint without LIMIT
- Missing index on WHERE/ORDER BY column (large table)
- Hot data fetched every request without cache (Redis / in-memory)
```
