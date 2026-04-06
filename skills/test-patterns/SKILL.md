---
name: df-test-patterns
description: "Test quality patterns for frontend and backend testing. Triggers: writing tests, reviewing test code, generating tests, when tests fail, unit tests, E2E tests, test patterns. Covers Vitest/Jest, React Testing Library, Playwright, and backend API testing."
effort: low
---

# Test Quality Patterns

Test quality guidelines for unit tests, component tests, E2E tests, and backend API tests.

## Core Principles

### 1. Test Behavior, Not Implementation

Tests should verify observable behavior, not implementation details.

### 2. Mock Fidelity

Mocks must match real type definitions. Check actual types before creating mocks.

### 3. Three-Section Coverage

Tests should cover:

- **Happy path**: Normal flow works
- **Edge cases**: Empty, null, boundary values
- **Error paths**: Errors handled gracefully

## Hard Rules

Enforced in all test reviews. See [references/hard-rules.md](references/hard-rules.md):

| Rule | Summary |
|------|---------|
| **T1** | Behavior over implementation |
| **T2** | Mock fidelity - match real types |
| **T3** | Edge case coverage |
| **T4** | No `not.toThrow()` without reason |
| **T5** | Zero assertion check |
| **T6** | Boundary operator coverage |
| **T7** | Stale mock contracts |
| **T8** | No external state in unit tests |
| **T9** | Test isolation |

## Pattern Categories

| Category | Framework | Focus |
|----------|-----------|-------|
| Frontend Unit | Vitest, Jest | Components, hooks, utilities |
| Component Tests | React Testing Library | User interactions, rendering |
| E2E Tests | Playwright | Full user flows, API endpoints |
| Backend Tests | Vitest, Jest | Services, controllers, database |

## Quick Reference

### Frontend Unit Tests

```typescript
describe('ModuleName', () => {
  describe('functionName', () => {
    it('should do X when Y', () => {
      // Arrange
      const input = 'test';
      
      // Act
      const result = functionName(input);
      
      // Assert
      expect(result).toBe(expected);
    });
  });
});
```

### React Testing Library

Query priority: `getByRole` > `getByLabelText` > `getByPlaceholderText` > `getByText` > `getByDisplayValue` > `getByTestId`

```typescript
// ✅ Prefer accessible queries
await userEvent.click(screen.getByRole('button', { name: /submit/i }));

// ✅ Use findBy for async
await screen.findByText('Loaded');
```

### Playwright E2E

```typescript
test('creates billboard', async ({ page }) => {
  const billboardPage = new BillboardPage(page);
  await billboardPage.goto();
  await billboardPage.create('Test Billboard');
  
  await expect(page.getByText('Created successfully')).toBeVisible();
});
```

### Backend Testing

```typescript
describe('UserService', () => {
  let userService: UserService;
  let mockRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockRepository = {
      findById: vi.fn(),
      create: vi.fn()
    };
    userService = new UserService(mockRepository);
  });

  it('creates user with valid data', async () => {
    mockRepository.create.mockResolvedValue(createUser());
    const result = await userService.create({ name: 'John' });
    expect(result.isOk).toBe(true);
  });
});
```

## Detailed Patterns

For comprehensive patterns, examples, and best practices:

- **[references/hard-rules.md](references/hard-rules.md)** — T1-T9 hard rules with examples
- **[references/patterns.md](references/patterns.md)** — Frontend, E2E, and backend patterns

## Related Skills

- `devflow:generate-tests` — Generate tests from source code

- `devflow:review` — Review includes test quality checks (T1-T9)
