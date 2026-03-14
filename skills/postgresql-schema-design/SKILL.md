---
name: postgresql-schema-design
description: "PostgreSQL schema design — data types, constraints, indexing strategies, partitioning, and PostgreSQL-specific gotchas. Use when designing tables, reviewing migrations, choosing data types, or setting up indexes. Distinct from sql-optimization (which handles query tuning). Triggers: schema design, table design, postgresql, create table, migration, index strategy, data types, FK index."
---

# PostgreSQL Schema Design

## Core Rules

- Define a **PRIMARY KEY** for reference tables. Prefer `BIGINT GENERATED ALWAYS AS IDENTITY`; use `UUID` only when global uniqueness/opacity is needed (distributed systems, opaque IDs).
- **Normalize first (3NF)** to eliminate redundancy and update anomalies; denormalize **only** for measured, high-ROI reads where join performance is proven problematic.
- Add **NOT NULL** everywhere semantically required; use **DEFAULT**s for common values.
- Create **indexes for access paths you actually query**: PK/unique (auto), **FK columns (manual!)**, frequent filters/sorts, join keys.
- Prefer **TIMESTAMPTZ** for event time; **NUMERIC** for money; **TEXT** for strings; **BIGINT** for integers; **DOUBLE PRECISION** for floats.

## PostgreSQL Gotchas

- **FK indexes**: PostgreSQL **does not** auto-index FK columns. Always add them manually.
- **Identifiers**: unquoted → lowercased. Use `snake_case`. Avoid quoted/mixed-case names.
- **Unique + NULLs**: UNIQUE allows multiple NULLs. Use `NULLS NOT DISTINCT` (PG15+) to restrict to one NULL.
- **No silent coercions**: length/precision overflows error out (no truncation). `999` into `NUMERIC(2,0)` fails.
- **Sequences have gaps** — rollbacks, crashes, and concurrent transactions create gaps. This is normal; don't try to make IDs consecutive.
- **MVCC**: updates/deletes leave dead tuples; vacuum handles them — design to avoid hot wide-row churn.
- **No clustered PK by default** (unlike SQL Server/MySQL InnoDB) — `CLUSTER` is a one-off reorganization.

## Data Types

### IDs

- `BIGINT GENERATED ALWAYS AS IDENTITY` — preferred default
- `UUID` — only for distributed systems, merging data sources, or opaque IDs. Use `gen_random_uuid()`.
- Avoid `SERIAL` — use `GENERATED ALWAYS AS IDENTITY` instead.

### Numbers

- `BIGINT` for integers (prefer over `INTEGER` unless storage is critical)
- `NUMERIC(p,s)` for money — **never** `FLOAT` or `MONEY` type
- `DOUBLE PRECISION` for floats (over `REAL`)

### Strings

- `TEXT` — preferred for all strings
- Do **NOT** use `CHAR(n)` or `VARCHAR(n)` — use `TEXT` with `CHECK (LENGTH(col) <= n)` if limits needed
- `BYTEA` for binary data

### Time

- `TIMESTAMPTZ` for all timestamps — **never** `TIMESTAMP` (without timezone)
- `DATE` for date-only; `INTERVAL` for durations
- Do **NOT** use `TIMETZ`

### JSON

- `JSONB` over `JSON` (binary, indexable, faster) — use only for optional/semi-structured attributes
- Use `JSON` only when original key ordering **must** be preserved

### Enums vs Text

- `CREATE TYPE ... AS ENUM` for small, stable, closed sets (e.g., days of week, US states)
- For business-logic-driven, evolving values (e.g., order statuses) → use `TEXT + CHECK` or lookup table

### Other

- `BOOLEAN NOT NULL` unless tri-state required
- `INET`/`CIDR` for IP addresses, `MACADDR` for MAC
- `TSVECTOR` for full-text search — always specify language: `to_tsvector('english', col)`

## Constraints

| Constraint | Key Notes |
|---|---|
| **PRIMARY KEY** | Implicit UNIQUE + NOT NULL; creates B-tree index |
| **FOREIGN KEY** | Specify `ON DELETE/UPDATE` action. **Add explicit index on FK column manually.** Use `DEFERRABLE INITIALLY DEFERRED` for circular FK dependencies. |
| **UNIQUE** | Allows multiple NULLs by default. Use `NULLS NOT DISTINCT` (PG15+) to restrict. |
| **CHECK** | NULL values pass check (three-valued logic). Combine with NOT NULL to enforce: `price NUMERIC NOT NULL CHECK (price > 0)` |
| **EXCLUDE** | Prevents overlapping values via operators. Use for booking/scheduling: `EXCLUDE USING gist (room_id WITH =, period WITH &&)` |

## Indexing

| Type | Use When |
|---|---|
| **B-tree** (default) | Equality/range queries (`=`, `<`, `>`, `BETWEEN`, `ORDER BY`) |
| **Composite** | Multiple filter columns — order matters: most selective/filtered column first. `WHERE a = ? AND b > ?` uses index `(a,b)` but `WHERE b = ?` alone does not. |
| **Covering** | `CREATE INDEX ON tbl (id) INCLUDE (name, email)` — index-only scans without table heap access |
| **Partial** | Hot subsets: `CREATE INDEX ON tbl (user_id) WHERE status = 'active'` |
| **Expression** | Computed searches: `CREATE INDEX ON tbl (LOWER(email))` — WHERE clause must match exactly |
| **GIN** | JSONB containment (`@>`, `?`), arrays, full-text search (`@@`) |
| **GiST** | Range types, geometry, exclusion constraints |
| **BRIN** | Very large naturally-ordered tables (time-series) — minimal storage, effective when row order correlates with column |

## Partitioning

Use for very large tables (>100M rows) where queries consistently filter on partition key, or for data maintenance (bulk replace/prune by partition).

```sql
-- RANGE (most common for time-series)
CREATE TABLE logs (id BIGINT, created_at TIMESTAMPTZ, ...)
  PARTITION BY RANGE (created_at);

CREATE TABLE logs_2024_01 PARTITION OF logs
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- LIST (discrete values)
PARTITION BY LIST (region);
CREATE TABLE logs_us PARTITION OF logs FOR VALUES IN ('us-east', 'us-west');

-- HASH (even distribution when no natural key)
PARTITION BY HASH (user_id);
```

**Limitations:** No global UNIQUE constraints — include partition key in PK/UNIQUE. FKs from partitioned tables not supported; use triggers.

## Row-Level Security

```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_access ON orders
  FOR SELECT TO app_users
  USING (user_id = current_user_id());
```

## Performance Patterns for Hot Tables

- **Separate hot/cold columns** — put frequently updated columns in a separate table to minimize bloat
- **`fillfactor=90`** — leaves space for HOT updates that avoid index maintenance overhead
- **UNLOGGED tables** — persistent but not crash-safe; good for caches, staging, temp data

## Quick Checklist

- [ ] PK defined on reference tables (`BIGINT GENERATED ALWAYS AS IDENTITY` or `UUID`)
- [ ] FK columns have explicit indexes (PostgreSQL does NOT auto-create them)
- [ ] Using `TIMESTAMPTZ` not `TIMESTAMP`
- [ ] Using `TEXT` not `VARCHAR(n)` or `CHAR(n)`
- [ ] Using `NUMERIC` not `FLOAT` for money
- [ ] Not using `SERIAL` (use `GENERATED ALWAYS AS IDENTITY`)
- [ ] Composite indexes have columns in correct selectivity order
- [ ] Partial indexes for high-frequency filtered queries
- [ ] UNIQUE constraints have `NULLS NOT DISTINCT` if needed (PG15+)
- [ ] Partitioning considered for tables >100M rows
