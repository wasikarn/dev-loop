# CHANGELOG Format Reference

Uses [Keep a Changelog](https://keepachangelog.com/) standard — human-readable, tool-parseable.

## File Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.4] - 2026-03-18
### Fixed
- Fix crash when user data is null (#456)
- Prevent double-submit on payment form (#457)

## [1.2.3] - 2026-02-10
### Added
- User profile photo upload
### Changed
- Improved error messages in login flow
```

## Section Types

| Section | Use for |
| --- | --- |
| `### Added` | New features |
| `### Changed` | Changes to existing functionality |
| `### Deprecated` | Features soon to be removed |
| `### Removed` | Removed features |
| `### Fixed` | Bug fixes |
| `### Security` | Vulnerabilities patched |

## Rules

- Add new version at the **top** (after `## [Unreleased]` if present)
- Date format: `YYYY-MM-DD`
- Each entry is a bullet starting with `-`
- Reference PR/issue numbers in parentheses when available: `(#456)`
- Keep entries short — describe what changed for the user, not implementation details
- Hotfix → use `### Fixed` only
- Release → use whichever sections apply (Added, Changed, etc.)

## Adding a New Entry

Insert after `# Changelog` header (or after `## [Unreleased]` block if it exists):

```markdown
## [{version}] - {YYYY-MM-DD}
### Fixed
- {entry from git log, cleaned up}
```

Do not delete existing entries. Do not re-order existing versions.
