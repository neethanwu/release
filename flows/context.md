# Context Flow

Read-only status report. Gathers and displays release-relevant information
without modifying any files.

---

## Gather Information

Collect all of the following. If any step fails, note the failure and continue
with the remaining steps.

### 1. Current Version

Use the adapter's `read_version` command to get the current version from the
manifest file.

### 2. Target Versions

Compute what each bump type would produce:

```
Current: 1.2.3
  patch → 1.2.4
  minor → 1.3.0
  major → 2.0.0
```

### 3. Last Tag

```bash
last_tag=$(git describe --tags --abbrev=0 --match "v*" 2>/dev/null)
```

If no tags exist, note: "No version tags found. This appears to be a first release."

### 4. Version Mismatch

If both a tag and manifest version exist, compare them. If they differ, note:
"Version mismatch: manifest says X.Y.Z, latest tag is vA.B.C."

### 5. Working Directory Status

```bash
git status --short
```

If clean, note: "Working directory is clean."
If dirty, list the changed files.

### 6. Commits Since Last Tag

```bash
# If tags exist:
git log <last_tag>..HEAD --oneline

# If no tags exist:
git log --oneline
```

Print the count and the list.

### 7. Files Changed Since Last Tag

```bash
# If tags exist:
git diff --stat <last_tag>..HEAD

# If no tags exist, show all tracked files:
git ls-files
```

### 8. Changelog Status

Check for CHANGELOG.md:
- If missing: "CHANGELOG.md not found."
- If present: extract and display the `## [Unreleased]` section content.
- If `[Unreleased]` is empty: "The [Unreleased] section is empty."

### 9. Infrastructure Status

Report on release infrastructure:

| Component | Check | Status |
|-----------|-------|--------|
| CHANGELOG.md | File exists with `[Unreleased]` | Present / Missing / Empty |
| Pre-push hook | `.git/hooks/pre-push` contains version validation | Installed / Not installed |
| CI workflows | `.github/workflows/` contains publish workflow | Found / Not found |

### 10. Package Contents (npm)

If the ecosystem is npm:

```bash
npm pack --dry-run 2>&1
```

Show the file list and total package size.

---

## Display Report

Present all gathered information in a structured format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Release Context: <package-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Version:      1.2.3
Last tag:     v1.2.3 (3 days ago)
Branch:       main
Working dir:  clean

Next versions:
  patch → 1.2.4
  minor → 1.3.0
  major → 2.0.0

Commits since v1.2.3 (5):
  abc1234 feat: add new feature
  def5678 fix: resolve edge case
  ...

Changelog [Unreleased]:
  ### Added
  - New feature description

  ### Fixed
  - Edge case resolution

Infrastructure:
  CHANGELOG.md   ✓ present, has content
  Pre-push hook  ✗ not installed
  CI publish     ✓ found at .github/workflows/publish.yml

Package contents:
  <npm pack --dry-run output>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
