# CLAUDE.md Audit Anti-Patterns

Common patterns that waste context tokens or degrade agent performance. Use during Phase 3 audit to systematically identify noise and redundancy.

## Category: Noise (should remove)

| Anti-pattern | Example | Why harmful |
| --- | --- | --- |
| Generic best practices | "Write tests for all new features" | Claude already knows this — adds tokens, changes no behavior |
| Absolute directive | "You MUST always use X" | Reduces agent adaptability; explore-first framing works better |
| Obvious framework defaults | "Next.js uses `pages/` for routing" | Within training data; no value to repeat |
| Vague instructions | "Be careful with database operations" | Doesn't specify what careful means; agent can't act on it |
| Unresolved TODOs | "TODO: document auth flow" | Dead content; either complete or remove |
| Aspirational statements | "We strive for clean code" | Not actionable; no behavior change |
| Copy-paste template text | `<placeholder>` left unfilled | Literal template artifacts that confuse the agent |

## Category: Stale (must fix)

| Anti-pattern | How to detect | Fix |
| --- | --- | --- |
| Dead file reference | Path doesn't exist in codebase | Update path or remove |
| Wrong command | Command fails when run | Update to working command |
| Outdated version pin | Version in CLAUDE.md ≠ version in `package.json`/lockfile | Update to actual version |
| Renamed module/dir | Old name doesn't appear in `find` output | Update to current name |
| Removed dependency | Listed in CLAUDE.md but not in `package.json` | Remove reference |

## Category: Redundant (can reduce)

| Anti-pattern | Example | Fix |
| --- | --- | --- |
| Duplicate across files | Same command in root `CLAUDE.md` and package `CLAUDE.md` | Keep once, remove from other |
| Inline what's indexed | Full file content + pointer to same file in `agent_docs/` | Keep pointer only |
| Repeated sections | Architecture described in two sections | Merge into one |
| Rules in multiple places | Pattern in CLAUDE.md and also in `.claude/rules/` | Keep in rules, point from CLAUDE.md |

## Category: Missing retrieval (add when absent)

| Situation | What to add |
| --- | --- |
| Framework project, no retrieval directive | `Prefer retrieval-led reasoning over pre-training for [framework] tasks.` |
| Framework project, no docs index | Pipe-delimited index pointing to `agent_docs/<framework>/` |
| Post-cutoff API used, no docs | Document API with usage examples or add to docs index |
| Large architecture — all inline | Pointer to `agent_docs/architecture.md` with 2-3 line summary |

## Wording Anti-Patterns

These patterns affect agent behavior regardless of content correctness:

| Pattern | Problem | Better |
| --- | --- | --- |
| `You MUST always...` | Absolute framing causes tunnel vision | `Prefer X over Y` |
| `Never do X` | Removes agent judgment for edge cases | `Avoid X unless [condition]` |
| `Always check Z first` | Invoke-first framing skips project exploration | `Check project first, then consult Z` |
| `IMPORTANT:` prefix overuse | Everything marked important = nothing is | Reserve for ≤2 items per file |
