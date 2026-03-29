# careful skill

Activates session-scoped safe mode by registering an inline PreToolUse hook that blocks destructive Bash commands.

## Skill Architecture

- `SKILL.md` only — no `references/` directory
- The `hooks` frontmatter block IS the skill — it registers a PreToolUse Bash hook that regex-matches dangerous commands
- `disable-model-invocation: true` — skill produces no model output; hook registration is the entire effect
- Blocked commands: `rm -rf`, `DROP TABLE`, `git push --force`, `truncate`, `git reset --hard`

## Validate After Changes

```bash
npx markdownlint-cli2 "skills/careful/SKILL.md"
```

## Gotchas

- The `hooks` frontmatter is the only inline hook defined inside a skill in this repo — all other hooks live in `hooks/`. This is a deliberate exception because the hook IS the skill's behavior.
- Session-scoped only — hook deactivates when session ends. Users expecting persistent protection need to re-invoke each session.
- Regex-based blocking: unusual spacing (e.g., `rm  -rf` with double space) or shell quoting may bypass the pattern. This is a reminder layer, not a hard security boundary.
- When updating the blocked command list, update both the regex in the frontmatter hook AND the "Blocked commands" list in the SKILL.md body — they must stay in sync.
- `disable-model-invocation: true` means the skill body text is not injected into context at invocation. The Gotchas section in SKILL.md is for user awareness only, not for Claude to read.
