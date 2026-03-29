# debug — Good/Bad Examples

Examples of systematic root-cause analysis vs surface-level fixes, and quality DX findings.

---

## Root Cause vs Symptom Fix

### ❌ Symptom fix — masks the real problem

**Bug:** `NullPointerException: Cannot read property 'name' of undefined` in `UserService.findById`

**Bad fix:**

```typescript
// Before
async findById(id: string): Promise<User> {
  return User.findOrFail(id)
}

// Bad fix: adds null guard at the caller
async getUserProfile(id: string) {
  const user = await this.userService.findById(id)
  if (!user) return null  // ← user can never be null here — findOrFail throws
  return user.profile.name  // ← actual crash still happens here
}
```

**Why it's wrong:** `findOrFail` throws, never returns null. The crash is `user.profile` being undefined, not `user` itself. Null guard at caller doesn't reach the real problem.

### ✅ Root cause fix — addresses the actual source

**Investigation finding:**

```markdown
## Root Cause

`user.profile` is `null` for users created before 2024-01-15 (migration date of profile table).
`findOrFail` correctly returns a User, but `profile` relation is optional in the schema and
not eager-loaded — accessing `.name` crashes when relation is absent.

**Evidence:**
- `app/models/user.ts:34` — `@hasOne(() => Profile)` declared as optional
- `database/migrations/20240115_create_profiles.ts` — migration only creates future rows
- `tests/unit/user.service.spec.ts:78` — test uses factory that always creates profile → false green

**Root cause:** Missing preload + missing null check on optional relation.
```

**Root cause fix:**

```typescript
// app/models/user.ts:89 — preload where relation is accessed
async findById(id: string): Promise<User> {
  return User.query()
    .where('id', id)
    .preload('profile')  // ← ensures relation is loaded
    .firstOrFail()
}

// app/services/user.service.ts:42 — null-safe access
async getUserProfile(id: string): Promise<string | null> {
  const user = await this.findById(id)
  return user.profile?.name ?? null  // ← safe optional chaining
}
```

---

## Investigation Output Quality

### ✅ Good `investigation.md` — specific, confidence-rated, has fix plan

```markdown
## Root Cause

**Hypothesis:** Order total calculation rounds mid-computation instead of at output,
causing off-by-one errors when item prices have 3+ decimal places.

**Evidence:**
- `app/services/order.service.ts:156` — `Math.round(subtotal * 100) / 100` called per item,
  not on final total — rounding accumulates across items
- `tests/unit/order.service.spec.ts:89` — test uses whole-number prices only → never catches this
- Database log shows `total = 99.99` for order that should be `100.00` (3 items × 33.333...)

**Confidence:** High — reproduced consistently with fractional prices in REPL

## DX Findings

| Sev | Category | File | Line | Issue | Recommendation |
| --- | --- | --- | --- | --- | --- |
| Warning | Test Coverage | `tests/unit/order.service.spec.ts` | 89 | Test prices are always whole numbers — fractional cases never tested | Add parameterized test with `[33.333, 33.333, 33.334]` |
| Warning | Error Handling | `app/services/order.service.ts` | 201 | `chargeStripe()` catch block logs error but doesn't re-throw — caller assumes success | Add `throw e` or return `Result<T, E>` |
| Info | Observability | `app/services/order.service.ts` | 156 | No log of calculated total before charge — can't reconstruct order amount from logs | Add `logger.info('Order total calculated', { orderId, total })` |

## Fix Plan

1. [Bug] Move rounding to final total, not per-item — `order.service.ts:156`
2. [Test] Add fractional price test case — `order.service.spec.ts:89`
3. [DX] Re-throw in catch block — `order.service.ts:201`
```

### ❌ Bad `investigation.md` — vague, no evidence, no confidence

```markdown
## Root Cause

The order calculation has a bug. Something is wrong with the math.

## Fix Plan

1. Fix the calculation
2. Add tests
3. Improve error handling
```

---

## DX Finding Quality

### ✅ Good DX findings — specific, actionable, scoped to affected area

```markdown
| Warning | Error Handling | `app/services/payment.service.ts` | 78 |
`catch (e) {}` swallows Stripe errors — failed payments appear as successes to callers |
Add `logger.error('Stripe charge failed', { error: e }); throw e;` |

| Warning | Test Coverage | `tests/unit/payment.service.spec.ts` | 45 |
Only happy-path tested — no spec for Stripe timeout (HTTP 408) or card decline (402) |
Add test cases: `stripe.charges.create` throws `StripeTimeoutError`, expect service to re-throw |

| Info | Observability | `app/services/payment.service.ts` | 45 |
No structured log before/after charge — can't correlate failed charges to user sessions |
Add `logger.info('Initiating charge', { userId, amount })` before `stripe.charges.create` |
```

### ❌ Bad DX findings — too broad, no file:line, vague recommendation

```markdown
| Warning | Testing | payment code | — | Not enough tests | Write more tests |
| Info | Logging | everywhere | — | Add more logging | Use a logger |
```

---

## Fix Approach Quality

### ✅ Good fix — follows Fix Plan exactly, no scope creep

Fix Plan item: "Move rounding to final total"

```typescript
// Before (rounding per-item):
const items = order.items.map(item => ({
  ...item,
  price: Math.round(item.price * 100) / 100,  // ← rounds too early
}))
const total = items.reduce((sum, item) => sum + item.price, 0)

// After (rounding at output only):
const total = order.items.reduce((sum, item) => sum + item.price, 0)
const roundedTotal = Math.round(total * 100) / 100  // ← round once at end
```

Commit: `fix(orders): move rounding to final total to prevent accumulation errors`

### ❌ Bad fix — fixes symptom, adds unrequested changes, no commit discipline

```typescript
// Fixes the rounding bug BUT ALSO rewrites the entire order calculation,
// extracts a new OrderCalculator class, changes the API signature,
// and adds a caching layer — none of which was in the Fix Plan
class OrderCalculator {
  private cache = new Map<string, number>()

  calculate(items: Item[]): number {
    const key = JSON.stringify(items)
    if (this.cache.has(key)) return this.cache.get(key)!
    // ... 60 more lines
  }
}
```

---

## Severity Classification

### P0 — Outage (auto-Full, skip mode confirmation)

```text
/debug "POST /api/payments returns 500 for ALL users since deploy 10 minutes ago"
```

✅ Correct: Lead auto-selects Full mode, skips mode confirmation gate, proceeds immediately.
❌ Wrong: Asking "which mode would you like?" when production is down.

### P1 — Critical (Full mode default)

```text
/debug "Users created after March 1 cannot login — JWT validation fails"
```

✅ Correct: Presents Full vs Quick choice (pre-selected Full), waits for confirmation.

### P2 — Minor (Quick mode default)

```text
/debug "Pagination returns wrong total count when filtering by status=cancelled"
```

✅ Correct: Presents Full vs Quick choice (pre-selected Quick), describes scope difference.
