# Test Quality Hard Rules

Enforced in all test reviews. Violations require fix before merge.

## T1: Behavior Over Implementation

Test what the code does, not how it does it.

**Rationale:** Implementation tests break on refactoring. Behavior tests survive.

```typescript
// ❌ Wrong - Testing implementation
it('calls fetchUsers on mount', () => {
  const spy = vi.spyOn(service, 'fetchUsers');
  render(<UserList />);
  expect(spy).toHaveBeenCalledTimes(1);
});

// ✅ Correct - Testing behavior
it('displays users after loading', async () => {
  render(<UserList />);
  await waitFor(() => {
    expect(screen.getByText('John Doe')).toBeInTheDocument();
  });
});
```

## T2: Mock Fidelity

Mocks must match real type definitions exactly.

**Rationale:** Stale mocks hide breaking changes.

```typescript
// ❌ Wrong - Missing required fields
vi.mock('../service', () => ({
  fetchUsers: vi.fn().mockResolvedValue([{ name: 'test' }])
}));

// ✅ Correct - Check real type first
type User = { id: string; name: string; email: string };
vi.mock('../service', () => ({
  fetchUsers: vi.fn().mockResolvedValue([
    { id: '1', name: 'John', email: 'john@example.com' }
  ])
}));
```

## T3: Edge Case Coverage

Tests must include edge cases: empty, null, boundary values.

**Rationale:** Edge cases cause production incidents.

```typescript
describe('UserList', () => {
  // Happy path
  it('displays users when data exists', async () => { /* ... */ });
  
  // Edge case - empty
  it('displays empty state when no users', () => { /* ... */ });
  
  // Edge case - null
  it('handles null gracefully', () => { /* ... */ });
  
  // Error path
  it('displays error when fetch fails', async () => { /* ... */ });
});
```

## T4: No `not.toThrow()` Without Reason

Tests must verify behavior, not just absence of errors.

**Rationale:** `not.toThrow()` passes even when nothing is tested.

```typescript
// ❌ Wrong - No assertion
it('does not throw', () => {
  expect(() => createUser()).not.toThrow();
});

// ✅ Correct - Verify behavior
it('creates user with valid data', () => {
  const user = createUser({ name: 'John' });
  expect(user.name).toBe('John');
  expect(user.id).toBeDefined();
});
```

## T5: Zero Assertion Check

Tests must verify behavior, not just mock calls.

**Rationale:** Tests without assertions pass even when broken.

```typescript
// ❌ Wrong - No assertion
it('calls the API', async () => {
  await userService.fetchUsers();
});

// ✅ Correct - Verify result
it('returns users from API', async () => {
  const users = await userService.fetchUsers();
  expect(users.length).toBeGreaterThan(0);
  expect(users[0].name).toBeDefined();
});
```

## T6: Boundary Operator Coverage

When testing ranges, test boundary values explicitly.

**Rationale:** Off-by-one errors occur at boundaries.

```typescript
describe('discount', () => {
  it('gives 0% discount below $100', () => {
    expect(calculateDiscount(99)).toBe(0);
  });
  
  it('gives 10% discount at $100 exactly', () => {
    expect(calculateDiscount(100)).toBe(10);
  });
  
  it('gives 10% discount above $100', () => {
    expect(calculateDiscount(101)).toBe(10);
  });
  
  it('gives 20% discount at $500 exactly', () => {
    expect(calculateDiscount(500)).toBe(100);
  });
});
```

## T7: Stale Mock Contracts

Keep mocks in sync with actual interfaces.

**Rationale:** Mocks that don't match real interfaces hide bugs.

```typescript
// ❌ Wrong - Mock out of sync
vi.mock('../api', () => ({
  fetchUsers: vi.fn()  // Missing new parameter!
}));

// ✅ Correct - Check mock matches real type
// Run type check regularly
// Use ts-auto-mock or similar tools
```

## T8: No External State in Unit Tests

Unit tests should not depend on external services.

**Rationale:** External state causes flaky tests.

```typescript
// ❌ Wrong - Depends on external API
it('fetches from production', async () => {
  const data = await fetch('https://api.example.com/users');
  // Flaky, slow, depends on network
});

// ✅ Correct - Mock external services
it('fetches users', async () => {
  vi.mock('../api', () => ({
    fetchUsers: vi.fn().mockResolvedValue([mockUser])
  }));
  const data = await fetchUsers();
  expect(data).toEqual([mockUser]);
});
```

## T9: Test Isolation

Each test must be independent and not depend on execution order.

**Rationale:** Order-dependent tests fail unpredictably.

```typescript
// ❌ Wrong - Shared mutable state
let user: User;
beforeEach(() => { user = createMockUser(); });

it('test A modifies user', () => {
  user.name = 'Modified';
  // Affects test B
});

it('test B', () => {
  expect(user.name).toBe('John');  // Fails if run after test A
});

// ✅ Correct - Fresh state per test
beforeEach(() => {
  vi.clearAllMocks();
});

it('test A', () => {
  const user = createMockUser();  // Local scope
  user.name = 'Modified';
});
```

## Enforcement

These rules are checked by `devflow:review` and `devflow:generate-tests`. Violations block merge.
