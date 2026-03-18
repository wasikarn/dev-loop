# Review Examples — 12-Point Canonical Examples

✅/❌ code examples for each rule in [`review-rules.md`](review-rules.md). TypeScript examples — patterns apply to other stacks.

---

## Rule #1 — Functional Correctness

❌ Bad — semantic bug: correct type, wrong value

```ts
// order.total = credits balance (not money paid)
const refund = orderPaymentAmount ?? order.total
//                                   ^^^^^^^^^^^^ wrong fallback — credits ≠ money
```

✅ Good — trace what the fallback value *means*

```ts
const refund = orderPaymentAmount ?? 0
// If no payment was made, refund amount is 0 — not the credit balance
```

⚠️ Don't flag: `null` coalescing where both branches are semantically equivalent (e.g., `label ?? 'Untitled'`)

---

## Rule #2 — App Helpers & Util Functions

❌ Bad — reimplementing what the framework already provides

```ts
// Manually formatting a date that Luxon/dayjs already handles
const formatted = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
```

✅ Good — use the existing util

```ts
import { formatDate } from '@/utils/date'
const formatted = formatDate(d, 'YYYY-MM-DD')
```

⚠️ Don't flag: reimplementation when the existing helper has different behavior or different output contract

---

## Rule #3 — N+1 Prevention

❌ Bad — query inside loop

```ts
const orders = await Order.all()
for (const order of orders) {
  order.items = await OrderItem.findBy('orderId', order.id) // N queries
}
```

✅ Good — eager load or batch

```ts
const orders = await Order.query().preload('items') // 1 query with JOIN
```

⚠️ Don't flag: loops with in-memory operations that don't touch the DB

---

## Rule #4 — DRY & Simplicity

❌ Bad — copy-paste variation with subtle differences

```ts
function getAdminLabel(user: User) {
  return `${user.firstName} ${user.lastName} (Admin)`
}
function getModeratorLabel(user: User) {
  return `${user.firstName} ${user.lastName} (Mod)`
}
```

✅ Good — extract the shared pattern

```ts
function getUserLabel(user: User, role: string) {
  return `${user.firstName} ${user.lastName} (${role})`
}
```

⚠️ Don't flag: two functions that look similar but have legitimately different semantics or divergence points

---

## Rule #5 — Flatten Structure

❌ Bad — nesting > 1 level

```ts
function processOrder(order: Order | null) {
  if (order) {
    if (order.isPaid) {
      if (order.items.length > 0) {
        ship(order) // buried 3 levels deep
      }
    }
  }
}
```

✅ Good — guard clauses, happy path left-aligned

```ts
function processOrder(order: Order | null) {
  if (!order) return
  if (!order.isPaid) return
  if (order.items.length === 0) return
  ship(order)
}
```

⚠️ Don't flag: single-level conditionals (`if/else` with no inner nesting)

---

## Rule #6 — Small Functions & SOLID

❌ Bad — god function doing validation + DB + email

```ts
async function createUser(dto: CreateUserDto) {
  if (!dto.email.includes('@')) throw new Error('Invalid email')
  if (dto.password.length < 8) throw new Error('Password too short')
  const existing = await User.findBy('email', dto.email)
  if (existing) throw new Error('Already exists')
  const user = await User.create({ ...dto, password: await hash(dto.password) })
  await sendWelcomeEmail(user.email)
  return user
}
```

✅ Good — each function has one responsibility

```ts
async function createUser(dto: CreateUserDto) {
  validateUserDto(dto)
  await assertEmailUnique(dto.email)
  const user = await persistUser(dto)
  await sendWelcomeEmail(user.email)
  return user
}
```

⚠️ Don't flag: orchestration functions that call multiple single-responsibility helpers — that's the pattern

---

## Rule #7 — Elegance

❌ Bad — verbose, non-idiomatic

```ts
const activeUsers = []
for (let i = 0; i < users.length; i++) {
  if (users[i].isActive === true) {
    activeUsers.push(users[i])
  }
}
```

✅ Good — idiomatic for the stack

```ts
const activeUsers = users.filter(u => u.isActive)
```

⚠️ Don't flag: verbose code that is intentionally explicit for readability in complex domain logic

---

## Rule #8 — Clear Naming

❌ Bad — cryptic abbreviations, generic names

```ts
const d = new Date()
const tmp = await getUserData(id)
function handle(x: any) { ... }
```

✅ Good — names communicate intent

```ts
const createdAt = new Date()
const user = await getUserById(userId)
function handlePaymentWebhook(event: StripeEvent) { ... }
```

⚠️ Don't flag: conventional short names in small scopes (`i` in a loop, `e` in a catch block, `req`/`res` in Express handlers)

---

## Rule #9 — Documentation & Comments

❌ Bad — stale comment, or commenting the obvious

```ts
// get users
const users = await User.all()

// TODO: fix this later (added 2 years ago, still here)
const result = legacyCalculate(data)
```

✅ Good — explain *why*, not *what*

```ts
// Paginate at 100 to avoid memory pressure — user list can reach 500k rows
const users = await User.query().paginate(page, 100)
```

⚠️ Don't flag: absence of comments on self-evident code (`const total = price * quantity`)

---

## Rule #10 — Type Safety

❌ Bad — `any` cast, boolean flag proliferation

```ts
const data = response.data as any
const parsed = JSON.parse(raw) as UserProfile // unvalidated external data

type State = { isLoading: boolean; isError: boolean; isSuccess: boolean }
// impossible: isLoading=true AND isSuccess=true
```

✅ Good — `unknown` + type guard, discriminated union

```ts
const data: unknown = response.data
if (!isUserProfile(data)) throw new Error('Unexpected response shape')

type State =
  | { status: 'loading' }
  | { status: 'error'; error: Error }
  | { status: 'success'; data: UserProfile }
```

⚠️ Don't flag: `as const` assertions, well-typed internal casts with a justification comment

---

## Rule #11 — Testability

❌ Bad — testing implementation details

```ts
it('calls setState twice', () => {
  const setState = jest.spyOn(component, 'setState')
  component.submit()
  expect(setState).toHaveBeenCalledTimes(2) // brittle: breaks on refactor
})
```

✅ Good — test observable behavior

```ts
it('shows success message after submit', async () => {
  render(<Form />)
  await userEvent.click(screen.getByRole('button', { name: /submit/i }))
  expect(screen.getByText('Saved!')).toBeInTheDocument()
})
```

⚠️ Don't flag: spying on external service calls (HTTP, DB) — those are boundaries, not implementation details

---

## Rule #12 — Debugging Friendly

❌ Bad — swallowed error, bare `console.log`

```ts
try {
  await processPayment(order)
} catch (e) {
  // silent failure — operator never knows
}

console.log(user) // left in production code
```

✅ Good — actionable error with context, structured logging

```ts
try {
  await processPayment(order)
} catch (error) {
  logger.error('Payment processing failed', {
    orderId: order.id,
    error: error instanceof Error ? error.message : String(error),
  })
  throw error // re-throw so caller can handle
}
```

⚠️ Don't flag: `console.log` in test files or scripts; `catch` blocks that intentionally suppress (e.g., optional feature detection) — must have a comment explaining why
