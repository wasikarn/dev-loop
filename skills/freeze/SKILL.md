---
name: freeze
description: >
  Lock edits to a specific directory for this session. Blocks Edit and Write tool calls
  outside the target path. Use when you want Claude to only touch files in one area:
  "freeze src/auth", "only edit tests/", "lock to this module".
  Triggers: /freeze [path], "only edit [dir]", "lock to [path]", "don't touch anything outside"
argument-hint: "[directory-path]"
disable-model-invocation: false
---

# /freeze — Directory Lock

`$ARGUMENTS` will be used as the locked directory. If no argument given, ask the user
which directory to lock edits to using the AskUserQuestion tool.

Announce: "Edits are now locked to `[directory]`. I will not edit files outside this path
for the rest of this session."

Then register a mental constraint for this session: before any Edit or Write tool call,
verify the target file path starts with the locked directory. If it doesn't, stop and
explain why you're refusing, then ask for explicit confirmation to override.

> **Note:** True hook-based enforcement requires the `hooks` frontmatter field with
> `$ARGUMENTS` substitution — use this manual approach until the skill runtime supports
> dynamic hook arguments. Track this limitation in the Gotchas section.

## Gotchas

- **Argument required** — `/freeze` with no path is ambiguous. Always ask via AskUserQuestion
  if `$ARGUMENTS` is empty.
- **Hook enforcement is manual** — unlike `/careful`, freeze relies on Claude's judgment,
  not a hard block. It can be overridden if Claude forgets. True enforcement needs dynamic
  hook path injection (not yet supported).
- **Subdirectory paths** — use absolute or repo-relative paths: `/freeze src/auth` not
  `freeze auth`.
