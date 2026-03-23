# Version Detector

Auto-detect the project's version file, read the current version, compute the next version, write it
back, verify the write, and capture the version bump commit SHA. No user prompt — abort with a clear
error if no supported version file is found.

---

## Step 1: Detect version file

Check for supported files in priority order:

```bash
# 1. Node.js
[ -f package.json ] && node -e "console.log(require('./package.json').version)" && echo "file:package.json"

# 2. Python (pyproject.toml)
[ -f pyproject.toml ] && grep -m1 '^version' pyproject.toml | sed 's/version = "\(.*\)"/\1/' && echo "file:pyproject.toml"

# 3. Python (setup.cfg)
[ -f setup.cfg ] && grep -m1 '^version' setup.cfg | sed 's/version = //' && echo "file:setup.cfg"
```

Run each in order — stop at the first match. Store the detected version as `{current_version}` and the
file path as `{version_file}`.

If none found → abort:

```text
Cannot detect version file. Supported: package.json, pyproject.toml, setup.cfg
```

---

## Step 2: Compute next version

Parse `{current_version}` as `MAJOR.MINOR.PATCH`:

| Mode | Rule | Example |
| --- | --- | --- |
| Mode 2 (hotfix) | Increment PATCH, keep MAJOR.MINOR | 1.2.3 → 1.2.4 |
| Mode 3 (release) | Increment MINOR, reset PATCH to 0 | 1.2.3 → 1.3.0 |

Store result as `{next_version}`.

---

## Step 3: Write back

Edit `{version_file}` using the Edit tool:

| File | Pattern to replace |
| --- | --- |
| `package.json` | `"version": "{current_version}"` → `"version": "{next_version}"` |
| `pyproject.toml` | `version = "{current_version}"` → `version = "{next_version}"` |
| `setup.cfg` | `version = {current_version}` → `version = {next_version}` |

Do NOT use `npm version` — it auto-commits and would capture the version bump SHA prematurely.

---

## Step 4: Verify write-back

Read `{version_file}` back and extract the version string:

| File | Verification command |
| --- | --- |
| `package.json` | `node -e "console.log(require('./package.json').version)"` |
| `pyproject.toml` | `grep -m1 '^version' pyproject.toml \| sed 's/version = "\(.*\)"/\1/'` |
| `setup.cfg` | `grep -m1 '^version' setup.cfg \| sed 's/version = //'` |

If the extracted version does not match `{next_version}` → abort:

```text
Version write-back failed — expected {next_version}, got {actual}. Check file format.
```

---

## SHA capture note

After `git commit -am "chore: bump version to {next_version}"` (performed in `workflow-deploy.md`
Step 6), capture:

```bash
git rev-parse HEAD
```

Store as `{version_bump_sha}`. Required for Mode 3 backport cherry-pick.
