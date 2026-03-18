# claude-code-skills

A Claude Code plugin — 8 workflow skills, 7 custom agents, 13 lifecycle hooks, and 2 output styles for structured development and PR review workflows.

**Plugin name:** `claude-code-skills` · **Repo:** `wasikarn/claude-code-skills`

---

## Prerequisites

| Tool | Required by | Install |
| --- | --- | --- |
| `jq` | All hooks (routing, gates, nudges, shellcheck) | `brew install jq` / `apt install jq` |
| `gh` CLI | `dlc-build`, `dlc-review`, `dlc-respond`, `dlc-debug`, `merge-pr` | `brew install gh` then `gh auth login` |
| `git` | All DLC skills, session context hook | pre-installed on most systems |
| `rtk` | DLC skills — token-optimized git/gh output | `brew install rtk` |
| `shellcheck` | `shellcheck-written-scripts` hook (optional) | `brew install shellcheck` |
| `node` / `npx` | Auto markdown lint hook (optional) | `brew install node` |

> **Hooks degrade gracefully** — if a tool is missing, the hook skips silently instead of blocking.
> **Skills require `gh` and `git`** — DLC skills will tell you if prerequisites are missing.

---

## Installation

Choose one method based on your use case:

| Method | Who | Result |
| --- | --- | --- |
| [Plugin install](#method-1-plugin-install-recommended) | Anyone who wants the skills | Skills available as `/claude-code-skills:dlc-build`, etc. |
| [Personal setup](#method-2-personal-setup-symlinks) | Developers who want to customize | Everything symlinked to `~/.claude/` — full control |

---

## Method 1: Plugin Install (recommended)

No cloning required. Claude Code handles everything.

### Step 1 — Install the plugin

```bash
claude plugin install wasikarn/claude-code-skills
```

### Step 2 — Verify installation

```bash
claude plugin list
```

Expected output includes `claude-code-skills`.

### Step 3 — Use the skills

Skills are namespaced after plugin install:

```text
/claude-code-skills:dlc-build BEP-1234
/claude-code-skills:dlc-review 42
/claude-code-skills:dlc-debug
/claude-code-skills:optimize-context
```

> **Included automatically:** skills, agents, commands, output styles, and workflow hooks (skill routing, task gates, idle nudges, session context, file protection, shellcheck).
>
> **Requires manual setup:** personal hooks (`post-compact-context`, sound notifications, QMD semantic search). See [Manual Configuration](#manual-configuration).

---

## Method 2: Personal Setup (symlinks)

For contributors or users who want to customize everything and have it symlinked to `~/.claude/` for immediate effect.

### Method 2 Prerequisites

| Tool | Required | Install |
| --- | --- | --- |
| `git` | Yes | `brew install git` |
| `jq` | Yes | `brew install jq` |
| `node` / `npm` | Optional | `brew install node` |
| `bun` | Optional | `curl -fsSL https://bun.sh/install \| bash` |
| `gh` (GitHub CLI) | Optional | `brew install gh` |
| `shellcheck` | Optional | `brew install shellcheck` |

### Step 1 — Clone the repo

```bash
git clone git@github.com:wasikarn/claude-code-skills.git ~/Codes/Personals/claude-code-skills
cd ~/Codes/Personals/claude-code-skills
```

### Step 2 — Run the install script

```bash
bash scripts/install.sh
```

The script will:

1. Check prerequisites
2. Prompt for machine-specific values (macOS username, allowed browser domains)
3. Generate `~/.claude/settings.json` from template
4. Create required `~/.claude/` directories
5. Install optional MCP binaries (dbhub, figma-mcp, sequential-thinking, context7)
6. Configure MCP servers in `~/.claude.json`
7. Install QMD (if bun is available)
8. Symlink all assets (skills, agents, hooks, output-styles, commands, scripts, dotfiles)
9. Optionally symlink `zshrc` → `~/.zshrc`

### Step 3 — Restart Claude Code

```bash
# Restart Claude Code to pick up new settings and hooks
```

### Step 4 — Verify symlinks

```bash
bash scripts/link-skill.sh --list
```

Expected: all skills, agents, hooks, commands, output-styles show as `✓ linked`.

### Step 5 — Index your codebases with QMD (optional)

QMD enables semantic code search across your projects. Run in each project root:

```bash
qmd update && qmd embed
```

---

## What's Included

### Skills (8)

| Category | Skill | Description |
| --- | --- | --- |
| **DLC Workflows** | `dlc-build` | Full dev loop — research → plan → implement → review → ship (`--quick`/`--hotfix`) |
| **DLC Workflows** | `dlc-review` | Adversarial PR review with 3-reviewer debate |
| **DLC Workflows** | `dlc-respond` | Address PR review comments as author |
| **DLC Workflows** | `dlc-debug` | Parallel root cause analysis + DX hardening |
| **Thinking** | `systems-thinking` | Causal Loop Diagram analysis for architecture decisions |
| **Utilities** | `optimize-context` | Audit and optimize CLAUDE.md files |
| **Utilities** | `env-heal` | Scan and fix environment variable mismatches |
| **Utilities** | `merge-pr` | Git-flow merge and deploy (feature/hotfix/release) |

### Agents (7)

| Agent | Model | Purpose |
| --- | --- | --- |
| `commit-finalizer` | haiku | Fast git commit with conventional commits format |
| `dev-loop-bootstrap` | haiku | Pre-gather Phase 1 context before dlc-build explorer spawns |
| `dlc-debug-bootstrap` | haiku | Pre-gather debug context before dlc-debug Investigator spawns |
| `pr-review-bootstrap` | sonnet | Fetch PR diff + Jira AC in one pass before review |
| `review-consolidator` | haiku | Dedup/sort multi-reviewer findings into single ranked table |
| `skill-validator` | sonnet | Validates SKILL.md against best practices |
| `tathep-reviewer` | sonnet | Code reviewer with persistent memory + preloaded skills |

### Hooks (13)

> **Critical:** `skill-routing.sh` is required for reliable skill auto-triggering. Without it, skills activate only ~20% of the time. `install.sh` configures this automatically.

| Hook | Event | Purpose |
| --- | --- | --- |
| `skill-routing.sh` | UserPromptSubmit | **Critical** — Forces skill evaluation before responding (~84% trigger rate) |
| `session-start-context.sh` | SessionStart | Inject git state + project detection |
| `session-start-mcp-cleanup.sh` | SessionStart | Kill orphaned MCP processes from force-closed sessions |
| `post-compact-context.sh` | SessionStart[compact] | Re-inject context after compaction (global only) |
| `bash-blockers.sh` | PreToolUse[Bash] | Block bash commands that have dedicated Claude tools |
| `protect-files.sh` | PreToolUse[Edit\|Write] | Block edits to protected config files |
| `qmd-pre-search.sh` | PreToolUse[Grep] | Inject QMD semantic search results before grep |
| `auto-test-env.sh` | PostToolUse[Edit\|Write] | Auto-detect test framework after file edits |
| `shellcheck-written-scripts.sh` | PostToolUse[Write] | Auto-validate shell scripts after writing |
| `session-summary-hook.sh` | PostToolUse[Bash] | Track session activity (requires claude-mem) |
| `idle-nudge.sh` | TeammateIdle | Nudge idle teammates (dev-loop, review-debate, respond, debug) |
| `task-gate.sh` | TaskCompleted | Gate task completions — verify file:line evidence |
| `play-sound.sh` | Notification/Stop | macOS sound feedback |

### Output Styles (2)

| Style | Description |
| --- | --- |
| `thai-tech-lead` | Thai language, concise, architecture-focused |
| `coding-mentor` | Explains decisions inline while coding |

### Commands (1)

| Command | Description |
| --- | --- |
| `analyze-claude-features` | Analyze Claude Code features and capabilities |

### Scripts (5)

| Script | Description |
| --- | --- |
| `install.sh` | New machine setup — prerequisites, settings.json from template, symlinks |
| `link-skill.sh` | Symlink manager — links all asset types + dotfiles to `~/.claude/` |
| `detect-project.sh` | Auto-detect current project type for context injection |
| `pr-context.sh` | Fetch PR context (diff, Jira, AC) for review agents |
| `fix-tables.sh` | Fix markdown table formatting (pre-commit) |

### Dotfiles

| File | Symlink Target | Description |
| --- | --- | --- |
| `global-CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions for all projects |
| `statusline.sh` | `~/.claude/statusline.sh` | Custom status line display |
| `zshrc` | `~/.zshrc` | Optimized zsh config — startup ~0.11s, evalcache, lazy NVM, atuin, fzf-tab |
| `global-settings.template.json` | *(template only)* | Settings template for new machine setup |

---

## Repo Structure

```text
claude-code-skills/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest
├── skills/               → ~/.claude/skills/
├── agents/               → ~/.claude/agents/
├── hooks/                → ~/.claude/hooks/
├── output-styles/        → ~/.claude/output-styles/
├── commands/             → ~/.claude/commands/
├── scripts/              → ~/.claude/scripts/
├── references/           # Shared reference docs (not symlinked)
├── global-CLAUDE.md      → ~/.claude/CLAUDE.md
├── statusline.sh         → ~/.claude/statusline.sh
├── zshrc                 → ~/.zshrc
└── global-settings.template.json  # Template for settings.json
```

---

## Manual Configuration

These hooks require manual setup in `~/.claude/settings.json` because they are personal or have external dependencies not bundled with the plugin:

| Hook | Event | Why manual | Requirement |
| --- | --- | --- | --- |
| `post-compact-context.sh` | SessionStart[compact] | Global scope only | None |
| `play-sound.sh` | Notification/Stop | Personal preference | macOS + sound files |
| `qmd-pre-search.sh` | PreToolUse[Grep] | External tool dependency | [QMD](https://github.com/kobig/qmd) installed and indexed |
| `session-summary-hook.sh` | PostToolUse[Bash] | External tool dependency | [claude-mem](https://github.com/wasikarn/claude-mem) |

Use `global-settings.template.json` as a reference for configuring these.

---

## Troubleshooting

### Skills not triggering automatically

The `skill-routing.sh` hook must be active. Check:

```bash
# Verify it's in settings.json
jq '.hooks.UserPromptSubmit' ~/.claude/settings.json
```

If missing, re-run `bash scripts/install.sh` or add manually via `/update-config`.

### Symlinks broken after repo move

Re-run the linker — it handles relinking automatically:

```bash
bash scripts/link-skill.sh
```

### Plugin skills show as `claude-code-skills:skill-name`

This is correct behavior for plugin-installed skills. The namespace prefix is automatic.

### QMD not finding results

Run `qmd update && qmd embed` in your project root to index/re-index the codebase.

---

## Adding a New Skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter
2. Add `skills/<name>/CLAUDE.md` with contributor context
3. Install symlink: `bash scripts/link-skill.sh <name>`
4. Lint: `npx markdownlint-cli2 "skills/<name>/**/*.md"`

See [`references/skill-creation-guide.md`](references/skill-creation-guide.md) for the full guide and frontmatter spec.
