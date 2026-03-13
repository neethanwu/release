# Rollback Procedures

Exact recovery commands for every failure scenario during a release.

---

## After Step 7: User Declines Push

**State:** Commit and tag exist locally. Nothing pushed to remote.

```bash
# Remove the tag
git tag -d vX.Y.Z

# Undo the commit (keeps changes staged)
git reset --soft HEAD~1

# Unstage everything
git restore --staged .

# Restore the manifest and changelog to pre-release state
git checkout -- package.json CHANGELOG.md
```

All changes are fully reverted. The repository is back to its pre-release state.

---

## After Step 9: Push Failed Entirely

**State:** Same as above — commit and tag are local only.

Use the same commands as "User Declines Push" above.

---

## After Step 9: Commit Pushed, Tag Push Failed

**State:** The release commit is on the remote, but the tag is not. This is a
split-brain state — CI will not trigger because there's no tag.

### Option A: Retry the tag push (preferred)

```bash
git push origin vX.Y.Z
```

If this succeeds, the release is complete.

### Option B: Full revert (if tag push continues to fail)

```bash
# Revert the release commit on remote
git revert HEAD --no-edit
git push origin <branch>

# Clean up the local tag
git tag -d vX.Y.Z
```

After reverting, investigate why the tag push failed (e.g., tag protection
rules, permissions) before attempting the release again.

---

## After Step 10: CI Publish Failed

**State:** Commit and tag are both on the remote. The code and tag are correct,
but the publish step in CI failed.

### Option A: Re-trigger CI (preferred)

Fix the CI issue (missing secret, build error, etc.) and re-trigger:

```bash
gh workflow run publish.yml
# Or push an empty commit to re-trigger:
# git commit --allow-empty -m "chore: re-trigger publish" && git push
```

### Option B: Full revert (if the release itself is wrong)

```bash
# Delete the remote tag
git push --delete origin vX.Y.Z

# Delete the local tag
git tag -d vX.Y.Z

# Revert the release commit
git revert HEAD --no-edit
git push origin <branch>
```

Then fix the issue and run `/release` again.

---

## General Recovery Tips

- **Always use `--soft` reset**, not `--hard`. Soft reset preserves your changes
  as staged files so you can inspect them.
- **Push individual tags** (`git push origin vX.Y.Z`), not `--tags`. This avoids
  accidentally pushing or deleting unrelated tags.
- **Check remote state** before reverting:
  ```bash
  git log origin/<branch> --oneline -5
  git ls-remote --tags origin | grep vX.Y.Z
  ```
- If you're unsure about the state, run `/release context` to see the current
  version, tags, and changelog status.
