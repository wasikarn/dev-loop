---
name: test-patterns
description: Test quality patterns for frontend and backend testing. Use when writing tests, reviewing test code, generating tests, or when tests fail. Covers Vitest/Jest (unit), React Testing Library (component), Playwright (E2E), and backend API testing with database patterns. Integrates with devflow:generate-tests and devflow:review.
---

# Test Quality Patterns

Test quality guidelines for unit tests, component tests, E2E tests, and backend API tests.

## Core Principles

### 1. Test Behavior, Not Implementation

Tests should verify observable behavior, not implementation details.

```typescript
// ❌ Wrong - Testing implementation details
it('calls fetchUsers on mount', () => {
  const fetchSpy = vi.spyOn(service, 'fetchUsers');
  render(<UserList />);
  expect(fetchSpy).toHaveBeenCalledTimes(1);
});

// ✅ Correct - Testing behavior
it('displays users after loading', async () => {
  render(<UserList />);
  expect(screen.getByText('Loading...')).toBeInTheDocument();
  
  await waitFor(() => {
    expect(screen.getByText('John Doe')).toBeInTheDocument();
  });
});
```

### 2. Mock Fidelity

Mocks must match real type definitions. Check actual types before creating mocks.

```typescript
// ❌ Wrong - Mock doesn't match real type
vi.mock('../service', () => ({
  fetchUsers: vi.fn().mockResolvedValue([{ name: 'test' }])  // Missing required fields!
}));

// ✅ Correct - Check real type first
// 1. Read the actual type
type User = { id: string; name: string; email: string };

// 2. Create complete mock
vi.mock('../service', () => ({
  fetchUsers: vi.fn().mockResolvedValue([
    { id: '1', name: 'John', email: 'john@example.com' }
  ])
}));
```

### 3. Three-Section Coverage

Tests should cover:

- **Happy path**: Normal flow works
- **Edge cases**: Empty, null, boundary values
- **Error paths**: Errors handled gracefully

```typescript
describe('UserList', () => {
  // Happy path
  it('displays users when data exists', async () => {
    render(<UserList users={[mockUser]} />);
    await waitFor(() => {
      expect(screen.getByText(mockUser.name)).toBeInTheDocument();
    });
  });

  // Edge case
  it('displays empty state when no users', () => {
    render(<UserList users={[]} />);
    expect(screen.getByText('No users found')).toBeInTheDocument();
  });

  // Error path
  it('displays error message when fetch fails', async () => {
    vi.spyOn(service, 'fetchUsers').mockRejectedValue(new Error('Network error'));
    render(<UserList />);
    await waitFor(() => {
      expect(screen.getByText('Failed to load users')).toBeInTheDocument();
    });
  });
});
```

## Frontend Unit Tests (Vitest/Jest)

### Test Structure

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

### Mock Hierarchy

From most to least preferred:

1. **Real service with test data** (integration)
2. **vi.mock at module level** (unit)
3. **vi.fn for individual functions** (unit)
4. **vi.spyOn for method tracking** (unit)

```typescript
// Level 1: Integration test with real service (preferred for E2E)
const service = new UserService(testFetcher);

// Level 2: Module mock (most common)
vi.mock('../service', () => ({
  fetchUsers: vi.fn(),
  createUser: vi.fn()
}));

// Level 3: Function mock (for specific cases)
const mockFetch = vi.fn();
vi.mock('../api', () => ({ fetch: mockFetch }));

// Level 4: Spy (for tracking calls)
vi.spyOn(service, 'fetchUsers').mockResolvedValue([mockUser]);
```

### Testing React Hooks

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from 'react-query';

// Wrapper for React Query hooks
const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } }
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useUsers', () => {
  it('returns users after fetch', async () => {
    const { result } = renderHook(() => useUsers(), {
      wrapper: createWrapper()
    });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data).toEqual([mockUser]);
  });
});
```

## React Testing Library Patterns

### Query Priority

Use queries in order of accessibility:

1. `getByRole` - Most accessible
2. `getByLabelText` - Form elements
3. `getByPlaceholderText` - Inputs
4. `getByText` - Text content
5. `getByDisplayValue` - Form values
6. `getByTestId` - Last resort

```typescript
// ❌ Wrong - Using test-id unnecessarily
fireEvent.click(screen.getByTestId('submit-button'));

// ✅ Correct - Use accessible queries
fireEvent.click(screen.getByRole('button', { name: /submit/i }));
```

### userEvent vs fireEvent

Prefer `userEvent` for realistic interactions:

```typescript
// ❌ Wrong - fireEvent doesn't simulate real user behavior
fireEvent.change(input, { target: { value: 'test' } });

// ✅ Correct - userEvent simulates real events
import userEvent from '@testing-library/user-event';

await userEvent.type(input, 'test');
await userEvent.click(button);
```

### Async Queries

```typescript
// Use findBy for async elements
await screen.findByText('Loaded');

// Or waitFor for assertions
await waitFor(() => {
  expect(screen.getByText('Loaded')).toBeInTheDocument();
});
```

### Prop Capture for Verification

```typescript
// Capturing props from mocked components
const MockComponent = vi.fn();

vi.mock('../component', () => ({
  Component: (props: any) => {
    MockComponent(props);
    return <div>Mock</div>;
  }
}));

render(<ParentComponent data={testData} />);

// Verify props passed to child
expect(MockComponent).toHaveBeenCalledWith(
  expect.objectContaining({
    data: testData,
    onSubmit: expect.any(Function)
  })
);
```

## Playwright E2E Patterns

### Page Object Model

```typescript
// pages/billboard.page.ts
export class BillboardPage {
  readonly page: Page;
  readonly createButton: Locator;
  readonly nameInput: Locator;

  constructor(page: Page) {
    this.page = page;
    this.createButton = page.getByRole('button', { name: /create/i });
    this.nameInput = page.getByLabel(/billboard name/i);
  }

  async goto() {
    await this.page.goto('/billboard');
  }

  async create(name: string) {
    await this.createButton.click();
    await this.nameInput.fill(name);
    await this.page.getByRole('button', { name: /save/i }).click();
  }
}

// tests/billboard.spec.ts
test('creates billboard', async ({ page }) => {
  const billboardPage = new BillboardPage(page);
  await billboardPage.goto();
  await billboardPage.create('Test Billboard');
  
  await expect(page.getByText('Created successfully')).toBeVisible();
});
```

### Auth Setup

```typescript
// auth.setup.ts
test('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name="email"]', process.env.E2E_EMAIL!);
  await page.fill('[name="password"]', process.env.E2E_PASSWORD!);
  await page.click('button[type="submit"]');
  
  // Save storage state
  await page.context().storageState({ path: 'auth.json' });
});

// playwright.config.ts
export default defineConfig({
  projects: [
    { name: 'setup', testMatch: /auth\.setup\.ts/ },
    {
      name: 'chromium',
      use: { storageState: 'auth.json' },
      dependencies: ['setup']
    }
  ]
});
```

### API Testing with Playwright

```typescript
// API endpoint testing
test('GET /api/users returns list', async ({ request }) => {
  const response = await request.get('/api/users');
  expect(response.status()).toBe(200);
  
  const body = await response.json();
  expect(body.data).toBeInstanceOf(Array);
  expect(body.data.length).toBeGreaterThan(0);
});

test('POST /api/users creates user', async ({ request }) => {
  const response = await request.post('/api/users', {
    data: { name: 'John', email: 'john@example.com' }
  });
  expect(response.status()).toBe(201);
  
  const body = await response.json();
  expect(body.data.name).toBe('John');
});
```

## Backend Testing Patterns

### API Endpoint Testing (Generic)

```typescript
describe('UserController', () => {
  describe('GET /users', () => {
    it('returns list of users', async () => {
      const response = await request(app).get('/users');
      
      expect(response.status).toBe(200);
      expect(response.body.data).toBeInstanceOf(Array);
    });

    it('filters by status', async () => {
      const response = await request(app).get('/users?status=active');
      
      expect(response.status).toBe(200);
      response.body.data.every(user => {
        expect(user.status).toBe('active');
      });
    });
  });

  describe('POST /users', () => {
    it('creates user with valid data', async () => {
      const response = await request(app)
        .post('/users')
        .send({ name: 'John', email: 'john@example.com' });
      
      expect(response.status).toBe(201);
      expect(response.body.data.name).toBe('John');
    });

    it('rejects invalid email', async () => {
      const response = await request(app)
        .post('/users')
        .send({ name: 'John', email: 'invalid' });
      
      expect(response.status).toBe(400);
      expect(response.body.error).toContain('email');
    });
  });
});
```

### Database Testing Patterns

#### Setup/Teardown

```typescript
// Test setup - run once before all tests
beforeAll(async () => {
  await db.connect();
});

// Test teardown - run once after all tests
afterAll(async () => {
  await db.disconnect();
});

// Per-test isolation
beforeEach(async () => {
  await db.clear();
});
```

#### Transaction Rollback

```typescript
describe('UserService', () => {
  let transaction;

  beforeEach(async () => {
    transaction = await db.beginTransaction();
  });

  afterEach(async () => {
    await transaction.rollback();
  });

  it('creates user within transaction', async () => {
    const user = await UserService.create({ name: 'John' }, transaction);
    expect(user.id).toBeDefined();
  });
});
```

#### Test Factories

```typescript
// factories/user.factory.ts
export function createUser(overrides?: Partial<User>): User {
  return {
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
    status: 'active',
    createdAt: new Date(),
    ...overrides
  };
}

// Usage in tests
const mockUser = createUser({ status: 'inactive' });
const mockAdmin = createUser({ role: 'admin' });
```

### Service Layer Testing

```typescript
describe('UserService', () => {
  let userService: UserService;
  let mockRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockRepository = {
      findById: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      delete: vi.fn()
    };
    userService = new UserService(mockRepository);
  });

  describe('create', () => {
    it('creates user with valid data', async () => {
      mockRepository.create.mockResolvedValue(createUser());
      
      const result = await userService.create({ name: 'John' });
      
      expect(result.isOk).toBe(true);
      expect(result.data?.name).toBe('John');
    });

    it('returns error when email exists', async () => {
      mockRepository.findByEmail.mockResolvedValue(createUser());
      
      const result = await userService.create({ 
        name: 'John', 
        email: 'existing@example.com' 
      });
      
      expect(result.isOk).toBe(false);
      expect(result.error?.message).toContain('already exists');
    });
  });
});
```

### Mocking External Services

```typescript
// Mock HTTP client
vi.mock('../http-client', () => ({
  httpClient: {
    get: vi.fn(),
    post: vi.fn()
  }
}));

// Mock email service
vi.mock('../email-service', () => ({
  EmailService: vi.fn().mockImplementation(() => ({
    send: vi.fn().mockResolvedValue({ success: true })
  }))
}));

// Use in test
it('sends welcome email after registration', async () => {
  const mockSend = vi.fn().mockResolvedValue({ success: true });
  vi.mocked(EmailService).mockImplementation(() => ({
    send: mockSend
  } as any));

  await userService.register({ email: 'test@example.com' });
  
  expect(mockSend).toHaveBeenCalledWith(
    expect.objectContaining({ to: 'test@example.com' })
  );
});
```

### Integration Testing with Real Database

```typescript
describe('UserController (integration)', () => {
  let app: Application;
  let db: Database;

  beforeAll(async () => {
    db = await setupTestDatabase();
    app = createApp(db);
  });

  afterAll(async () => {
    await db.close();
  });

  beforeEach(async () => {
    await db.seed(testData);
  });

  it('GET /users/:id returns user', async () => {
    const response = await request(app).get('/users/1');
    
    expect(response.status).toBe(200);
    expect(response.body.data.id).toBe('1');
  });
});
```

### Controller Testing Patterns

```typescript
describe('UserController', () => {
  describe('index', () => {
    it('returns paginated users', async () => {
      const req = mockRequest({ query: { page: '1', limit: '10' } });
      const res = mockResponse();

      await controller.index(req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.any(Array),
          meta: expect.objectContaining({ page: 1, limit: 10 })
        })
      );
    });
  });
});

// Mock helpers
function mockRequest(overrides?: Partial<Request>): Request {
  return { ...overrides } as Request;
}

function mockResponse(): Response {
  const res: any = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  return res;
}
```

## Test Isolation

### Reset Between Tests

```typescript
beforeEach(() => {
  vi.clearAllMocks();
  vi.resetModules();
});

afterEach(() => {
  vi.restoreAllMocks();
});
```

### Avoid Shared State

```typescript
// ❌ Wrong - Shared mutable state
let user: User;
beforeEach(() => { user = createMockUser(); });

// ✅ Correct - Fresh state per test
beforeEach(() => {
  vi.clearAllMocks();
});

it('test A', () => {
  const user = createMockUser();  // Local scope
});
```

### Database Cleanup

```typescript
// For integration tests
afterAll(async () => {
  await db.cleanup();
  await server.close();
});
```

## Hard Rules

These rules are enforced in reviews:

### T1: Behavior Over Implementation

Test what the code does, not how it does it.

### T2: Mock Fidelity

Mocks must match real types exactly.

### T3: Edge Case Coverage

Tests must include edge cases (empty, null, boundary values).

### T4: No `not.toThrow()` Without Reason

Tests must verify behavior, not just absence of errors.

### T5: Zero Assertion Check

Tests must verify behavior, not just mock calls.

### T6: Boundary Operator Coverage

When testing ranges, test boundary values explicitly.

### T7: Stale Mock Contracts

Keep mocks in sync with actual interfaces.

### T8: No External State in Unit Tests

Unit tests should not depend on external services.

### T9: Test Isolation

Each test must be independent and not depend on execution order.

## Related Skills

- `devflow:generate-tests` - Generate tests from source code
- `devflow:review` - Review includes test quality checks
