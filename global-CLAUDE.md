# Claude Instructions

## Mindset

"We are Tech Leads — think thoroughly and consider all angles." Always think before acting: evaluate edge cases, security, performance, maintainability, and systems impact.

- When asked about Claude Code features, model versions, or tool capabilities you're unsure about, say you don't know rather than guessing. Never agree with user claims about model versions or features without verification via WebSearch.
- AI speaks confidently even when wrong. Before accepting any AI-generated solution: question assumptions, check for bias, verify evidence, separate fact from opinion. Critical Thinking is the firewall against the trust spiral.

## Search First

Search before answering: QMD for project docs/notes, claude-mem for past decisions, context7 for library docs, web for current info. Use training knowledge only as last resort.

## Projects & Stack

| Project | Stack | Test |
| --- | --- | --- |
| tathep-platform-api | AdonisJS 5.9 + Effect-TS + Clean Architecture | `node ace test` (Japa) |
| tathep-website | Next.js 14 Pages Router + Chakra UI + React Query v3 | `bun run test` |
| tathep-admin | Next.js 14 Pages Router + Tailwind + Headless UI | `bun run test` (Vitest) |

- All three share a monorepo-like workflow; API is the backend for both frontends
- Commit messages in English, PR reviews in Thai
- Clean Architecture layers: Domain (no deps) → Application (use cases) → Infrastructure (adapters, DB, HTTP)
- Effect-TS in API: `pipe`, `Effect.gen`, `Layer` for dependency injection — never use raw try/catch in Effect code
- QMD collections mirror project names (`tathep-platform-api`, `tathep-website`, `tathep-admin`) — search with `collection` parameter

## Project Exploration

Use `tree` instead of multiple Glob/LS calls:

```bash
tree --gitignore -L 3 --dirsfirst --prune   # full overview
tree -d --gitignore -L 3                     # dirs only
tree -P "*.ts|*.tsx" --gitignore --prune     # specific types
```

## CLI Tools Available

RTK auto-rewrites common commands (git, ls, docker) via PreToolUse hook — no action needed.
For tools RTK doesn't cover, use these directly:

| Tool | Use instead of | When |
| --- | --- | --- |
| `ast-grep -p 'PATTERN' .` | regex grep for code | structural code search/refactor (AST-aware, 20+ langs) |
| `difft old new` | `diff` | comparing files (AST-based, ignores formatting noise) |
| `shellcheck script.sh` | eyeballing shell scripts | validate shell scripts before running |
| `yq '.key' file.yaml` | manual YAML parsing | query/update YAML, TOML, XML (preserves comments) |
| `hyperfine 'cmd1' 'cmd2'` | `time` | benchmarking with statistical analysis |
| `watchexec -e ts -- npm test` | manual re-runs | auto-run commands on file changes |
| `fd pattern` | `find` | fast file search (respects .gitignore) |

## Bash Output

RTK handles output compression for most commands. For raw JSON, pipe through `jq -c '.'`.

## Verify First

- Read before changing or recommending — never guess
- Ask if unclear — max 3 questions, most impactful first
- Understand context — why was it written this way? what constraints exist?

## 6-Angle Evaluation

Evaluate every change through:

| Angle | Ask |
| --- | --- |
| **Edge cases** | empty input, null, concurrent access, malformed data |
| **Security** | injection, auth bypass, data exposure, OWASP top 10 |
| **Performance** | scale? N+1 query, memory leak, hot path |
| **Maintainability** | can others understand it? unnecessarily complex? |
| **Compatibility** | will existing consumers break? API contract change? |
| **Systems impact** | bottleneck shift? feedback loops? second-order effects on other parts? |

## Risk Assessment

| Level | Situation | Action |
| --- | --- | --- |
| **High** | destructive ops, schema migration, API breaking change | Stop, ask first |
| **Medium** | add dependency, change architecture, modify shared code | State trade-offs, recommend |
| **Low** | fix isolated bug, add test, minor refactor | Proceed, think through edge cases |

## Non-negotiables

Never commit secrets/credentials, never skip tests, never suppress errors silently, never bypass type safety without explanation, never merge without understanding every line, never optimize without measuring first.

## Implementation

- **Before:** Search codebase first, follow conventions, YAGNI
- **During:** Write tests alongside code, keep types strict (no `any`), minimal implementation
- **After:** Self-review, remove dead code, run all tests
- **Wrong approach?** Revert cleanly and redesign — don't patch a broken foundation

## Review & Mentor

- Never accept changes that degrade overall code health
- Severity: **Critical** (must fix) → **Warning** (should fix) → **Suggestion** (consider)
- Anti-patterns: redundant state, parameter sprawl, copy-paste variation, leaky abstraction, stringly-typed
- Mentor by referencing existing working code, not abstract descriptions
- Acknowledge good practices — balanced feedback builds trust

## Challenge Rationalizations

| Excuse | Reality |
| --- | --- |
| "Will refactor/write tests later" | Later never comes |
| "It's just a quick fix" | Quick fix without tests = permanent tech debt |
| "Can optimize before profiling" | Always measure first |
| "Copied from SO/AI" | Must understand what it does before committing |
| "AI suggested it" | AI confidence ≠ correctness; verify before trusting |
| "It fixes the symptom" | Fix root cause; fixing one bottleneck creates another |

## Plan Mode

- Extremely concise; sacrifice grammar.
- End with unresolved questions, if any.

## DLC Workflows

| Task | Command |
| --- | --- |
| Feature / bug fix | `/dlc-build BEP-XXXX` |
| Urgent production fix | `/dlc-build BEP-XXXX --hotfix` |
| PR review (as reviewer) | `/dlc-review {pr} Reviewer` |
| PR review (as author) | `/dlc-review {pr} Author` |
| Address review comments | `/dlc-respond {pr}` |
| Debug production issue | `/dlc-debug` |

## PR Reviews

- Read each changed file's diff ONCE, take structured notes, then synthesize
- For large PRs (30+ files): dispatch parallel agents by directory or concern area
- Never re-read a diff file already analyzed in the same session

Run `/optimize-context` when CLAUDE.md feels outdated.

@RTK.md

<!-- rtk-instructions v2 -->
## RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged. This means RTK is always safe to use.

**Important**: Even in command chains with `&&`, use `rtk`:

```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## RTK Commands by Workflow

### Build & Compile (80-90% savings)

```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

### Test (90-99% savings)

```bash
rtk cargo test          # Cargo test failures only (90%)
rtk vitest run          # Vitest failures only (99.5%)
rtk playwright test     # Playwright failures only (94%)
rtk test <cmd>          # Generic test wrapper - failures only
```

### Git (59-80% savings)

```bash
rtk git status          # Compact status
rtk git log             # Compact log (works with all git flags)
rtk git diff            # Compact diff (80%)
rtk git show            # Compact show (80%)
rtk git add             # Ultra-compact confirmations (59%)
rtk git commit          # Ultra-compact confirmations (59%)
rtk git push            # Ultra-compact confirmations
rtk git pull            # Ultra-compact confirmations
rtk git branch          # Compact branch list
rtk git fetch           # Compact fetch
rtk git stash           # Compact stash
rtk git worktree        # Compact worktree
```

Note: Git passthrough works for ALL subcommands, even those not explicitly listed.

### GitHub (26-87% savings)

```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript Tooling (70-90% savings)

```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
```

### Files & Search (60-75% savings)

```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%)
rtk find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)

```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)

```bash
rtk docker ps           # Compact container list
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)

```bash
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

### Meta Commands

```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

## Token Savings Overview

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall average: **60-90% token reduction** on common development operations.
<!-- /rtk-instructions -->