# dlc-build — Good/Bad Examples

Examples of what high-quality vs low-quality output looks like at each phase.

---

## Phase 1: Research Quality

### ✅ Good research — file:line evidence, concrete, answers "what exists already"

```markdown
## Research Summary

**Task:** Add rate limiting to POST /api/payments

**Existing pattern (file:line evidence):**
- Rate limiting already exists for auth endpoints: `src/middleware/rate-limit.ts:23`
  uses `@adonisjs/limiter` with `throttle(5, '1m')` per IP
- Middleware registration pattern: `start/kernel.ts:41` — registered as named middleware
- Payment route: `start/routes.ts:88` — currently no limiter middleware attached
- Limiter config: `config/limiter.ts:12` — Redis store, prefix `rl:`

**Gap identified:**
- No rate limiter on payment routes → attack surface for card-testing fraud
- Existing middleware is copy-paste ready — no new dependency needed

**Risk:**
- Redis must be available in all envs — check `.env.example` for `REDIS_*` vars
```

### ❌ Bad research — vague, no file references, doesn't answer what already exists

```markdown
## Research

The app has some middleware. We might need to add rate limiting to payments.
I'll need to create a new middleware file. There could be dependencies needed.
```

---

## Phase 2: Plan Quality

### ✅ Good plan — concrete tasks, YAGNI-compliant, correct ordering

```markdown
## Implementation Plan

**Mode:** Quick | **Scope:** 2 files changed

### Tasks

1. **[TEST] Add rate limiter spec for payment route**
   - File: `tests/functional/payments/rate-limit.spec.ts` (new)
   - Assert: 6th request within 1 min returns 429

2. **[IMPL] Attach `throttle` middleware to payment routes**
   - File: `start/routes.ts:88`
   - Change: add `.use(middleware.throttle(5, '1m'))` to the route group
   - No new files — reuse existing `src/middleware/rate-limit.ts`

3. **[IMPL] Add rate limit key to test env**
   - File: `.env.test`
   - Add `REDIS_HOST=127.0.0.1` if not already present (check first)

**Out of scope (YAGNI):**
- Custom error response format — not in task description
- Per-user vs per-IP differentiation — not requested
- Admin bypass — not requested
```

### ❌ Bad plan — scope creep, vague tasks, wrong order

```markdown
## Plan

1. Create rate limiting infrastructure
2. Add middleware
3. Maybe refactor the middleware system to be more flexible
4. Add logging and monitoring
5. Consider a plugin architecture for future extensibility
6. Write tests (maybe)
7. Update documentation
```

---

## Phase 3: Implementation Quality

### ✅ Good implementation — minimal, follows existing patterns, no surprises

```typescript
// start/routes.ts — before
router.group(() => {
  router.post('/payments', [PaymentsController, 'store'])
}).prefix('/api')

// start/routes.ts — after (2-line change)
router.group(() => {
  router.post('/payments', [PaymentsController, 'store'])
    .use(middleware.throttle(5, '1m'))
}).prefix('/api')
```

```typescript
// tests/functional/payments/rate-limit.spec.ts
test('returns 429 after 5 requests in 1 minute', async ({ client }) => {
  for (let i = 0; i < 5; i++) {
    await client.post('/api/payments').json(validPayload).expect(200)
  }
  const response = await client.post('/api/payments').json(validPayload)
  response.assertStatus(429)
})
```

### ❌ Bad implementation — scope creep, unnecessary abstraction, skips existing patterns

```typescript
// Created a whole new RateLimiterService class (not needed — middleware already exists)
class RateLimiterService {
  private store: Map<string, { count: number; resetAt: number }> = new Map()

  // In-memory store — doesn't work across instances, ignores existing Redis config
  async check(key: string, limit: number, windowMs: number): Promise<boolean> {
    const record = this.store.get(key) ?? { count: 0, resetAt: Date.now() + windowMs }
    if (Date.now() > record.resetAt) record.count = 0
    record.count++
    this.store.set(key, record)
    return record.count <= limit
  }
}
```

---

## YAGNI Violations — What to Flag in Review

### ❌ Speculative abstraction — not in task

```typescript
// Task was: "add rate limiting to payments"
// Worker added: a fully generic, configurable rate limiting framework

interface RateLimitConfig {
  strategy: 'sliding-window' | 'fixed-window' | 'token-bucket'
  store: 'memory' | 'redis' | 'database'
  keyResolver: (ctx: HttpContext) => string
  onExceeded: (ctx: HttpContext) => Promise<void>
}

class RateLimiterFactory {
  create(config: RateLimitConfig): Middleware { ... }
}
```

**Finding:** YAGNI — task requires attaching existing middleware to one route, not building a framework. Revert to using existing `throttle` middleware.

### ❌ Unused parameter added "just in case"

```typescript
// Added optional `options` object to a function that doesn't use it yet
async function chargeUser(
  userId: string,
  amount: number,
  options?: { retry?: boolean; idempotencyKey?: string }  // never read
) {
  return stripe.charges.create({ amount })  // options ignored
}
```

---

## Phase 6: Commit Quality

### ✅ Good commits — one commit per concern, conventional format

```text
feat(payments): attach rate limiter middleware to POST /api/payments
test(payments): add rate limit spec — 429 after 5 requests per minute
```

### ❌ Bad commits — mixed concerns, vague message, WIP

```text
update stuff
fix things and also add rate limiting and some other changes
wip: halfway through feature
```

---

## Invocation Examples

✅ **Good** — task description + explicit mode flag:

```text
/dlc-build "Add health check endpoint GET /api/health → returns {status: ok, uptime}" --full
/dlc-build "Fix null crash in UserService.findById when profile is missing" --quick
/dlc-build ABC-1234 --hotfix
```

❌ **Bad** — no task description (skill cannot determine scope):

```text
/dlc-build
/dlc-build --full
```

❌ **Bad** — Jira key without `--hotfix`/`--quick` when mode is ambiguous (forces unnecessary mode-confirmation round trip):

```text
/dlc-build ABC-1234
```

> **Tip:** Include a Jira key when the ticket has AC — the skill auto-extracts acceptance criteria into plan tasks. Combine with `--quick` for small tasks or `--hotfix` for production incidents.
