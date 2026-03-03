# Skills Best Practices

Researched 2026-03-03 from agentskills.io spec, Claude Code official docs, and IDE validator.

## Supported Frontmatter Fields

| Field | Required | Max |
| ------- | ---------- | ----- |
| `name` | No* | 64 chars |
| `description` | Recommended | 1024 chars |
| `argument-hint` | No | — |
| `compatibility` | No | 500 chars |
| `disable-model-invocation` | No | — |
| `user-invocable` | No | — |
| `license` | No | — |
| `metadata` | No | — |

**Not IDE-validated:** `context`, `agent`, `model`, `hooks` — IDE flags these as unsupported.
Existing PR review skills have `context: fork` and work at runtime; IDE validator may be behind.

## disable-model-invocation vs user-invocable

| Setting | In context? | `/` menu | Auto-invoke |
| --------- | ------------ | ---------- | ------------- |
| (default) | ✅ | ✅ | ✅ |
| `disable-model-invocation: true` | ❌ | ✅ | ❌ |
| `user-invocable: false` | ✅ | ❌ | ✅ |

## Description Rules

1. Max **1024 chars** — use the full budget for auto-invoked skills
2. Cover **what** it does AND **when** to use it
3. **Third person** — injected into system prompt
4. Include **specific trigger keywords** users would naturally say
5. No XML tags

**Good pattern:**

```yaml
description: "Summarize PR changes. Use when user asks for PR summary, code review overview, or wants to understand what changed in a PR."
```

## Description Context Budget

- **2% of context window** (floor: 16,000 chars) at startup
- If many skills are installed and exceed budget, some are excluded — run `/context` to check
- Override: `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var

## String Substitutions

| Variable |
| ---------- |
| `$ARGUMENTS` |
| `$0`, `$1`, `$2` |
| `${CLAUDE_SESSION_ID}` |
| `` !`cmd` `` |

## File Structure

```text
skills/<name>/
  SKILL.md         # Entry point. Keep under ~500 lines / 5k tokens.
  CLAUDE.md        # Local maintenance context (tracked in git)
  references/      # Supporting docs — loaded on demand, no size limit
  scripts/         # Pre-written scripts > asking Claude to generate inline
```

**Progressive disclosure:**

| Level | Content | When loaded |
| ------- | --------- | ------------ |
| 1 — Metadata | `name` + `description` | Always, at startup |
| 2 — Instructions | SKILL.md body | On invoke |
| 3 — Resources | `references/` files | When accessed |

## Content Principles

- **Single default** over multiple options: "use pdfplumber; for OCR use pdf2image instead"
- **High freedom** (guidelines) for flexible tasks; **low freedom** (exact commands) for fragile ops
- **File references one level deep** — avoid nested chains; Claude may `head -100` partial reads
- **Reference files explicitly** — state what each file contains and when to load it
- **Consistent terminology** — pick one term and never vary it
- **Pre-written scripts** beat asking Claude to generate code inline
- **No time-sensitive info** — don't write "before August 2025 use X"
- **Include a feedback loop** — run validator → fix → repeat pattern in workflows

## Skill Discovery / Installation

Precedence (highest wins): Enterprise → Personal `~/.claude/skills/` → Project `.claude/skills/` → Plugin

```bash
bash scripts/link-skill.sh <name>   # install one
bash scripts/link-skill.sh          # install all
bash scripts/link-skill.sh --list   # check symlink status
```
