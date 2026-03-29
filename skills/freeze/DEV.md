# freeze skill

Locks edits to a specific directory for the current session via model-enforced constraint (not a hard hook block).

## Skill Architecture

- `SKILL.md` only — minimal (~37 lines), no `references/` directory
- Enforcement is manual: Claude checks file paths before Edit/Write calls based on the announced constraint
- Uses `$ARGUMENTS` for the target directory path; falls back to `AskUserQuestion` if empty
- Unlike `/careful`, there is no inline `hooks` frontmatter — enforcement is model-compliance only

## Validate After Changes

```bash
npx markdownlint-cli2 "skills/freeze/SKILL.md"
```

## Gotchas

- No real enforcement mechanism — the SKILL.md itself documents this limitation: "True enforcement needs dynamic hook path injection (not yet supported)." If the Claude Code skill runtime gains support for `$ARGUMENTS` in hook matchers, this skill should be upgraded to a real PreToolUse Edit|Write hook.
- Unlike `/careful` (which has an inline hook and `disable-model-invocation: true`), freeze relies on model attention — it can be bypassed if Claude context grows large and the constraint fades.
- `argument-hint: "[directory-path]"` drives the CLI prompt; if the argument format changes in the skill runtime, update this field.
- Absolute or repo-relative paths work; bare directory names without path context (e.g., `freeze auth`) may be ambiguous — the SKILL.md guidance tells users to use `src/auth` not just `auth`.
