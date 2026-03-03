# Plan: [Feature Name]

_Based on: [research.md](research.md)_

## Problem

What problem this solves and why it matters now.

## Approach

High-level strategy. Reference the research findings that informed this choice.

## Changes

### [File/Module 1 — e.g. `src/routes/orders.ts`]

- What changes and why
- Code snippets where helpful:

```ts
// New endpoint following pattern from src/routes/users.ts
router.post('/orders', validate(orderSchema), async (req, res) => {
  // ...
});
```

### [File/Module 2]

- ...

## Trade-offs

| Option | Pros | Cons |
| --- | --- | --- |
| Option A | ... | ... |
| Option B | ... | ... |

## Test Strategy

How to verify this works:

- Unit tests: what to test, expected behavior
- Integration tests: end-to-end flows to verify
- Manual verification: commands to run, expected output

## Tasks

- [ ] Task 1 — description
- [ ] Task 2 — description
- [ ] Task 3 — description
- [ ] Run tests and verify

## Annotations

_User corrections and constraints go here during annotation cycles._

## Future

_Items noticed during implementation that are out of scope for this change._
