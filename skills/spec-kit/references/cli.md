# specify CLI Reference

Version: 0.1.6 | Template: 0.1.7 | Requires: Python 3.11+, uv, Git

## specify init

Bootstrap a new project with spec-kit templates and slash commands.

```bash
# Typical usage
specify init my-project --ai claude
specify init . --ai claude                    # current directory
specify init --here --ai claude               # current directory (alt)
specify init --here --ai claude --ai-skills   # + install as agent skills
specify init --here --force                   # skip confirmation if dir not empty
```

### --ai \<agent\> options

| Value |
| ------- |
| `claude` |
| `gemini` |
| `copilot` |
| `cursor-agent` |
| `codex` |
| `windsurf` |
| `qwen` |
| `opencode` |
| `amp` |
| `kilocode` |
| `auggie` |
| `codebuddy` |
| `shai` |
| `q` |
| `agy` |
| `bob` |
| `qodercli` |
| `roo` |
| `generic` |

### All flags

| Flag |
| ------ |
| `--ai <agent>` |
| `--here` |
| `--force` |
| `--no-git` |
| `--ai-skills` |
| `--ai-commands-dir <path>` |
| `--script sh\|ps` |
| `--github-token <token>` |
| `--skip-tls` |
| `--ignore-agent-tools` |
| `--debug` |

---

## specify check

Check which AI agent tools are installed on the current machine.

```bash
specify check
```

---

## specify version

Show version and system info.

```bash
specify version
```

---

## specify extension

Manage spec-kit extensions (community/third-party add-ons).

```bash
specify extension list                    # list installed extensions
specify extension search <query>          # search catalog
specify extension info <name>             # show extension details
specify extension add <name>              # install extension
specify extension remove <name>           # uninstall extension
specify extension update [name]           # update one or all extensions
specify extension enable <name>           # enable a disabled extension
specify extension disable <name>          # disable without removing
```

---

## Environment Variables

| Variable |
| ---------- |
| `GH_TOKEN` / `GITHUB_TOKEN` |
| `SPECIFY_FEATURE` |

---

## Installation & Upgrade

```bash
# Persistent install (recommended)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Upgrade to latest version
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# One-time use without installing
uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME>
```
