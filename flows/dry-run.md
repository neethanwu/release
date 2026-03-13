# Dry Run Flow

Simulates a release (steps 1–6) without committing, tagging, or pushing.
All file changes are reverted at the end.

---

## Before Starting

Record the current state so changes can be reverted cleanly:

```bash
# List files that are currently modified (should be none if preconditions pass)
modified_before=$(git diff --name-only)
```

Print: "[DRY RUN] Simulating release — no changes will be permanent."

---

## Run Steps 1–6

Follow the same steps as [release.md](release.md), with these labels:

1. **[DRY RUN] Validate preconditions** — same checks
2. **[DRY RUN] Run checks** — run tests, lint, typecheck
3. **[DRY RUN] Bump version** — bump in manifest (will be reverted)
4. **[DRY RUN] Build** — run build if applicable (will be reverted)
5. **[DRY RUN] Transform changelog** — transform CHANGELOG.md (will be reverted)
6. **[DRY RUN] Show changelog for review** — display the release preview

Prefix all output with `[DRY RUN]` so it's clear nothing is permanent.

---

## Revert Changes

After step 6 (or after any failure), restore all modified files:

```bash
# Restore only files that were changed during the dry run
modified_after=$(git diff --name-only)
if [ -n "$modified_after" ]; then
  git checkout -- $modified_after
fi

# Remove any untracked files created during the dry run (e.g., build artifacts)
# Only remove files that didn't exist before
untracked=$(git ls-files --others --exclude-standard)
if [ -n "$untracked" ]; then
  # Show what would be cleaned and confirm before removing
  echo "[DRY RUN] Build artifacts created during simulation:"
  echo "$untracked"
  git clean -fd --dry-run
fi
```

Do NOT use `git checkout -- .` as it could revert unrelated changes.

---

## Summary

```
[DRY RUN] Simulation complete.
  Version would be: X.Y.Z
  Changelog entry previewed above.
  No files were permanently modified.
```
