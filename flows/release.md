# Release Flow

The full 10-step release process for stable versions (patch, minor, major).

Before starting, confirm you have loaded the appropriate adapter file for
ecosystem-specific commands.

---

## Step 1: Validate Preconditions

All three checks must pass before proceeding.

### Clean working directory

```bash
git diff --quiet && git diff --cached --quiet
```

If dirty: "Working directory has uncommitted changes. Please commit or stash them before releasing." Stop.

### On default branch

For stable releases, verify the current branch is the default branch:

```bash
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
# Fallback if remote HEAD is not set
if [ -z "$default_branch" ]; then
  default_branch=$(git rev-parse --verify origin/main >/dev/null 2>&1 && echo "main" || echo "master")
fi
current_branch=$(git branch --show-current)
```

If not on default branch: "Stable releases should be made from the `<default>` branch. You are on `<current>`. Switch branches or use `/release alpha` for a pre-release." Stop.

If no remote is configured, skip this check and note: "No remote configured — skipping branch check."

### Changelog has content

Read CHANGELOG.md and find the `## [Unreleased]` section (case-insensitive). Extract
the content between `## [Unreleased]` and the next `## [` heading.

If the section is missing: route to [init.md](init.md) and return here after.

If the section exists but contains only whitespace: "The [Unreleased] section in CHANGELOG.md is empty. Add your changes before releasing." Stop.

---

## Step 2: Run Checks

Run the adapter's check commands (test, lint, typecheck). Each check runs in
sequence. Abort on the first failure.

Print each check as it starts: "Running tests..." / "Running lint..."

If a check fails:
- Print the failing command and its output
- Print: "Checks failed. Fix the issues and try again."
- Stop. No rollback needed — nothing has been modified yet.

---

## Step 3: Bump Version

Run the adapter's bump command for the requested type (patch/minor/major).

- Modify only the manifest file (e.g., `package.json`)
- Do not create any git commits or tags
- Print: "Version bumped: 1.2.3 → 1.2.4"

---

## Step 4: Build

Run the adapter's build command if one exists.

This step runs *after* the version bump so that build artifacts contain the
correct new version number. If no build step is defined, skip this step.

If the build fails:
- Print the error output
- Restore the manifest file: `git checkout -- <manifest>`
- Print: "Build failed. Version bump has been reverted."
- Stop.

---

## Step 5: Transform Changelog

Read CHANGELOG.md and perform this transformation:

**Find** (case-insensitive):
```
## [Unreleased]
```

**Replace with:**
```
## [Unreleased]

## [X.Y.Z] - YYYY-MM-DD
```

Where `X.Y.Z` is the new version and `YYYY-MM-DD` is today's date.

The content that was under `[Unreleased]` now falls under the new version heading.
The new `[Unreleased]` section starts empty.

**Validate the transformation:** Read the file back and confirm:
- A `## [X.Y.Z]` heading exists
- It has content beneath it (not just whitespace)
- The `## [Unreleased]` heading still exists above it

If validation fails, restore CHANGELOG.md and the manifest, then stop with an error.

---

## Step 6: Show Changelog for Review

Present the release summary for human review:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Release: <package-name> v<version>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## [X.Y.Z] - YYYY-MM-DD

<changelog content for this version>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files to commit:
  - <manifest file>
  - CHANGELOG.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for confirmation before proceeding. This is the primary review checkpoint.

---

## Step 7: Commit and Tag

Stage the modified files and create the release commit and tag:

```bash
git add <manifest> CHANGELOG.md
git commit -m "chore(release): vX.Y.Z"
git tag -a vX.Y.Z -m "Release vX.Y.Z"
```

If build artifacts need to be committed (rare — most projects gitignore them),
the adapter should specify which files to include.

---

## Step 8: Confirm Before Push

Present the final confirmation before pushing to the remote:

```
Ready to push:
  - Commit: chore(release): vX.Y.Z
  - Tag: vX.Y.Z
  - Remote: origin/<branch>

Proceed? (yes/no)
```

**If declined:**
Print rollback commands from [reference/rollback.md](../reference/rollback.md):
```bash
git tag -d vX.Y.Z
git reset --soft HEAD~1
git restore --staged .
git checkout -- <manifest> CHANGELOG.md
```
Stop.

---

## Step 9: Push

Push the commit and tag separately (avoids pushing unrelated tags):

```bash
git push origin <branch>
git push origin vX.Y.Z
```

**If the commit push fails:**
Print the error and the rollback commands. Stop.

**If the commit pushed but the tag push fails:**
Print: "Commit pushed successfully, but tag push failed. Retry with:"
```bash
git push origin vX.Y.Z
```
Also print full rollback commands in case retry doesn't work.
See [reference/rollback.md](../reference/rollback.md) for the split-brain recovery procedure.

---

## Step 10: Watch CI (Optional)

Best-effort CI monitoring. Skip gracefully if unavailable.

```bash
# Check if gh CLI is available
command -v gh >/dev/null 2>&1
```

**If `gh` is available:**
```bash
gh run list --branch <branch> --limit 1 --json status,url
gh run watch
```

**If `gh` is not available:**
Construct the Actions URL from the remote:
```bash
remote_url=$(git remote get-url origin 2>/dev/null)
```
Parse the owner/repo from the URL and print:
"Watch CI at: https://github.com/<owner>/<repo>/actions"

**If not on GitHub** (no github.com in remote URL):
Print: "Release complete! Check your CI system for publish status."

---

## Summary

After all steps complete, print:

```
✓ Released <package-name> vX.Y.Z
  - Commit: <short-hash>
  - Tag: vX.Y.Z
  - Branch: <branch>
```
