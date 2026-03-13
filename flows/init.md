# Init Flow

Bootstraps missing release infrastructure. Called automatically when CHANGELOG.md
is missing or lacks an `[Unreleased]` section, or when the user explicitly
requests setup.

---

## CHANGELOG.md Bootstrap

### If CHANGELOG.md does not exist

1. Read the template from [templates/CHANGELOG.md](../templates/CHANGELOG.md)
2. Write it to `CHANGELOG.md` in the project root
3. Print: "Created CHANGELOG.md with an empty [Unreleased] section."

### If CHANGELOG.md exists but has no `[Unreleased]` section

1. Read the existing CHANGELOG.md
2. Insert `## [Unreleased]\n\n` at the top of the changelog, after the title
   and introductory text (after the first `# ` heading and any text before
   the first `## ` heading)
3. Print: "Added [Unreleased] section to existing CHANGELOG.md."

### Populate [Unreleased] for First Release

If this is a first release (no git tags exist):

1. Check if there are commits in the repository:
   ```bash
   git rev-list --count HEAD 2>/dev/null || echo "0"
   ```

2. If commits exist, offer to populate the changelog from commit history:
   "This appears to be a first release. Would you like to populate the
   [Unreleased] section from your commit history?"

3. If accepted, generate changelog entries:
   ```bash
   git log --oneline --no-decorate
   ```
   Group commits into Added/Changed/Fixed categories based on content analysis.
   Present the draft for review and editing before writing to CHANGELOG.md.

4. If declined, remind: "Remember to add your changes to the [Unreleased]
   section in CHANGELOG.md before running `/release`."

### Release Command Was Invoked

If the user ran `/release patch` (or minor/major) and the `[Unreleased]` section
is empty after init:

Print: "The [Unreleased] section in CHANGELOG.md is empty. Add your changes,
then run `/release <type>` again."

Stop. Do not proceed with the release flow.

---

## Pre-Push Hook Installation

Offer to install a git pre-push hook that validates releases before pushing.

### Check for existing hook

```bash
ls -la .git/hooks/pre-push 2>/dev/null
```

### If no hook exists

1. Read the template from [templates/pre-push-hook.sh](../templates/pre-push-hook.sh)
2. Replace `{{VERSION_READ_CMD}}` with the adapter-specific version read command:
   - npm: `node -p "require('./package.json').version"`
3. Write to `.git/hooks/pre-push`
4. Make executable: `chmod +x .git/hooks/pre-push`
5. Print: "Pre-push hook installed. It will validate that tag versions match
   your package.json and changelog before pushing."

### If a hook already exists

Print: "A pre-push hook already exists at .git/hooks/pre-push."

Offer three options:
1. **Append** — Add release validation to the end of the existing hook
2. **Replace** — Replace the existing hook entirely
3. **Skip** — Leave the existing hook as-is

Wait for the user to choose before proceeding.

---

## Summary

After bootstrapping, print what was set up:

```
Release infrastructure:
  CHANGELOG.md    ✓ created / ✓ already exists
  Pre-push hook   ✓ installed / ✗ skipped
```

Then return to the calling flow (release, dry-run, etc.) to continue.
