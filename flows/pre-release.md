# Pre-Release Flow

Handles alpha, beta, and rc releases. Same structure as the full release flow
with key differences noted below.

---

## Differences from Stable Release

| Aspect | Stable release | Pre-release |
|--------|---------------|-------------|
| Branch | Must be on default branch | Any branch allowed |
| Version | `X.Y.Z` | `X.Y.Z-<type>.N` |
| Changelog | Transforms `[Unreleased]` → `[X.Y.Z]` | Skips transformation entirely |
| Publish tag | `latest` | `alpha`, `beta`, `rc`, or `next` |

---

## Step 1: Validate Preconditions

Same as the release flow, with one change:

- **Clean working directory** — same check
- **Branch check** — SKIP. Pre-releases are allowed from any branch.
- **Changelog check** — SKIP. Pre-releases do not consume changelog entries.

---

## Step 2: Run Checks

Same as the release flow. Run tests, lint, and typecheck via the adapter.

---

## Step 3: Compute Pre-Release Version

Use the adapter's pre-release versioning:

1. Read the current version from the manifest
2. Determine the base version for the pre-release:
   - If the current version is stable (e.g., `1.2.3`), bump patch to get the base: `1.2.4`
   - If the current version is already a pre-release (e.g., `1.2.4-alpha.1`), keep the same base: `1.2.4`
3. Scan existing git tags to find the next sequence number:
   ```bash
   git tag -l "v<base>-<type>.*" --sort=-v:refname | head -1
   ```
4. Extract N from the highest matching tag, add 1. If none exist, N = 1.
5. Set the version to `<base>-<type>.N`
6. Update the manifest with this version

Print: "Pre-release version: X.Y.Z-alpha.N"

---

## Step 4: Build

Same as the release flow. Run build if defined by the adapter.

---

## Step 5: Skip Changelog Transformation

Do nothing. Pre-releases do not modify CHANGELOG.md.

The `[Unreleased]` section remains untouched — its contents will be consumed
by the next stable release.

---

## Step 6: Show Pre-Release Summary

Present the pre-release summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pre-release: <package-name> v<version>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Version:  X.Y.Z-alpha.N
Branch:   <current-branch>
Dist-tag: alpha

Files to commit:
  - <manifest>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for confirmation.

---

## Steps 7–10: Commit, Confirm, Push, Watch CI

Same as the release flow:

- **Step 7:** `git add <manifest>` (no CHANGELOG.md since it wasn't modified)
  - Commit: `chore(release): vX.Y.Z-<type>.N`
  - Tag: `git tag -a vX.Y.Z-<type>.N -m "Pre-release vX.Y.Z-<type>.N"`
- **Step 8:** Confirm before push
- **Step 9:** Push commit and tag
- **Step 10:** Watch CI (same best-effort approach)

---

## Summary

```
✓ Pre-released <package-name> vX.Y.Z-alpha.N
  - Commit: <short-hash>
  - Tag: vX.Y.Z-alpha.N
  - Branch: <branch>
  - Dist-tag: alpha
```
