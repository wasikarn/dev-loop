# CLAUDE.md Templates

Use only sections relevant to the project. Not all sections are needed.

## Recommended Sections

| Section |
| --- |
| Commands |
| Architecture |
| Retrieval Directive |
| Key Files |
| Code Style |
| Environment |
| Testing |
| Gotchas |
| Workflow |

## Template: Minimal (Single Project)

```markdown
# <Project Name>

<One-line description>. Tech stack: <framework> + <language> + <db>.

## Commands

| Command | Description |
|---------|-------------|
| `<install>` | Install dependencies |
| `<dev>` | Start dev server |
| `<build>` | Production build |
| `<test>` | Run tests |
| `<lint>` | Lint/format |

## Architecture

<root>/
  <dir>/    # <purpose>
  <dir>/    # <purpose>

## Gotchas

- <non-obvious thing>
- Run `/optimize-context` when this file feels outdated
```

## Template: Comprehensive (Single Project)

```markdown
# <Project Name>

<One-line description>. Tech stack: <framework> + <language> + <db>.
Prefer retrieval-led reasoning over pre-training-led reasoning for any <framework> tasks.

## Commands

| Command | Description |
|---------|-------------|
| `<command>` | <description> |

## Architecture

<root>/
  <dir>/    # <purpose>
Full docs: `agent_docs/architecture.md` (read when relevant)

## Key Files

- `<path>` - <purpose>

## Code Style

- <convention>
- <preference over alternative>

## Environment

Required: `<VAR>` (<purpose>), `<VAR>` (<purpose>)
Setup: <steps>

## Testing

- `<command>` - <scope>
- <testing pattern>

## Gotchas

- <gotcha>
- Run `/optimize-context` when this file feels outdated

## Workflow

- <when to do X>
```

## Template: Monorepo Root

```markdown
# <Monorepo Name>

<Description>

## Packages

| Package | Path | Purpose |
|---------|------|---------|
| `<name>` | `<path>` | <purpose> |

## Commands

| Command | Description |
|---------|-------------|
| `<command>` | <description> |

## Cross-Package Patterns

- <shared pattern>
```

## Template: Package/Module (in monorepo)

```markdown
# <Package Name>

<Purpose>

## Usage

<import/usage example>

## Key Exports

- `<export>` - <purpose>

## Dependencies

- Depends on `<package>` for <reason>

## Notes

- <important note>
```

## Template: Framework-Heavy Project

For projects that heavily rely on framework APIs (especially post-training-cutoff versions):

```markdown
# <Project Name>

<One-line description>. Tech stack: <framework vX.Y> + <language> + <db>.

## Retrieval Directive

Prefer retrieval-led reasoning over pre-training-led reasoning for any <framework> tasks.
Explore project structure first, then consult docs index for API details.

## Commands

| Command | Description |
|---------|-------------|
| `<command>` | <description> |

## Architecture

<root>/
  <dir>/    # <purpose>

## [<Framework> Docs Index]

|root: ./agent_docs/<framework>
|<category>:{<file1>,<file2>}
|<category>/<sub>:{<file1>,<file2>}

## Post-Cutoff APIs Used

| API | Docs | Notes |
|-----|------|-------|
| `<api>` | `agent_docs/<path>` | <usage context in this project> |

## Gotchas

- <gotcha>
- Run `/optimize-context` when this file feels outdated
```

## File Types & Locations

| Type | Location |
| --- | --- |
| Project root | `./CLAUDE.md` |
| Local overrides | `./.claude.local.md` |
| Global defaults | `~/.claude/CLAUDE.md` |
| Package-specific | `./packages/*/CLAUDE.md` |

Claude auto-discovers CLAUDE.md files in parent directories.

## Content Guidelines

**Add:**

- Commands/workflows discovered during analysis
- Gotchas and non-obvious patterns found in code
- Package relationships not obvious from code
- Testing approaches that work
- Configuration quirks
- Framework-specific retrieval directive (see compression-guide.md)

**Do NOT add:**

- Info obvious from code (e.g. "UserService handles users")
- Generic best practices (e.g. "write tests for new features")
- One-off fixes unlikely to recur
- Verbose explanations when a one-liner suffices
- Standard language/framework behavior Claude already knows
- Content that doesn't change agent behavior (noise — may distract)

## Passive Context vs Skills

From Vercel research: agents ignored available skills 56% of the time.

| Use Case |
| --- |
| General framework knowledge |
| Project conventions & architecture |
| Action-specific workflows (migrations, upgrades) |
| One-time operations (scaffolding, code generation) |

**Rule:** If the agent needs this info on every task → passive context. If only for specific user-triggered actions → skill.

> "The gap may close as models get better at tool use, but results matter now." — Vercel. Prefer passive context until skills catch up.
