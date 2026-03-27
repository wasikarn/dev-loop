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
- Run `/optimize-claude-md` when this file feels outdated
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
- Run `/optimize-claude-md` when this file feels outdated

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
- Run `/optimize-claude-md` when this file feels outdated
```

## Template: Global User (~/.claude/CLAUDE.md)

For the user-level global CLAUDE.md. Different purpose from project files: user role, cross-project tools, and persistent preferences — not architecture or commands.

```markdown
# Claude Instructions

## Role

<one-line: who I am, what projects I work on, primary stack>

## Projects & Stack

| Project | Stack | Notes |
|---------|-------|-------|
| `<name>` | <stack> | <key note> |

## Tools

| Tool | Use |
|------|-----|
| `<tool>` | <when/how> |

## Preferences

- <formatting preference>
- <communication style>
- <workflow preference>

## Gotchas

- <cross-project quirk>
- Run `/optimize-claude-md` when this file feels outdated
```

**What to include:** cross-project conventions, global CLI tools, MCP server shortcuts, tone/language preferences, persistent workflow rules.

**What NOT to include:** project-specific architecture (belongs in project CLAUDE.md), commands (belong in project CLAUDE.md), one-time context.

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

See [compression-guide.md](compression-guide.md#passive-context-design-principles) for full rationale and passive/active decision rules.
