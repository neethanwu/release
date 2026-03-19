# Swift Adapter

Covers macOS apps built with Swift Package Manager. Detected when `Package.swift`
exists with at least one `.executableTarget`.

---

## Gotchas

- **`PlistBuddy` is macOS-only.** This adapter requires a macOS host for version reading and bumping. CI templates must use `macos-*` runners.
- **`.build/release/` is the default output path.** `swift build -c release` places the binary in `.build/release/<TargetName>`, not in the project root.
- **`create-dmg` is a third-party tool.** Not included with macOS. If the Makefile uses it, it must be installed separately (`brew install create-dmg`).
- **Code signing identity is not managed by this skill.** The user's Makefile or build script handles `codesign` and `xcrun notarytool`. The adapter only invokes the build chain.
- **Tag-only mode has no file to bump.** If no Info.plist exists, the version lives only in git tags. The bump step is skipped — the tag created in Step 7 IS the version.

---

## Read Version

Detect the version source by scanning for Info.plist files:

```bash
plist=$(find . -maxdepth 3 -name "Info.plist" -not -path "./.build/*" | head -1)
```

**If a plist is found:**
```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist"
```

**If no plist exists (tag-only mode):**
```bash
git describe --tags --abbrev=0 --match "v*" 2>/dev/null | sed 's/^v//'
```

If neither source has a version, this is a first release — print:
"No version found. This appears to be a first release."

### Version Mismatch Check

Compare the plist version against the latest git tag:

```bash
latest_tag=$(git describe --tags --abbrev=0 --match "v*" 2>/dev/null)
```

If the tag version and plist version differ, warn:
"Version mismatch: Info.plist says X.Y.Z but latest tag is vA.B.C. Using Info.plist as the source of truth for bumping."

In tag-only mode, there is no mismatch to check.

---

## Bump Version

**If a plist exists:**

Bump the version in-place. Compute the new version from the current one based
on the requested bump type (patch/minor/major), then write it:

```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString X.Y.Z" "$plist"
```

Also bump `CFBundleVersion` (build number) if it exists in the plist. Use a
simple incrementing integer or match the marketing version — follow whichever
convention the project already uses.

After bumping, read the new version to confirm:
```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist"
```

Print: "Version bumped: X.Y.Z → A.B.C"

**In tag-only mode:**

Skip this step. Print: "Tag-only mode — version will be set by the git tag in Step 7."

---

## Pre-Release Version

For `/release alpha`, `/release beta`, or `/release rc`:

1. Read the current version (from plist or latest tag)
2. Determine the base version:
   - If current version is already a pre-release (e.g., `1.2.0-alpha.1`), use the same base (`1.2.0`)
   - If current version is stable (e.g., `1.2.0`), bump patch first to get the next base (`1.2.1`)
3. Scan existing git tags to determine the sequence number:
   ```bash
   git tag -l "v<base>-<type>.*" --sort=-v:refname | head -1
   ```
4. Extract N from the highest matching tag, increment by 1. If no tags match, N = 1.
5. Set version to `<base>-<type>.N` (e.g., `1.2.1-alpha.1`)
6. Update the plist with the computed version (or skip in tag-only mode)

---

## Run Checks

Run the following in order. Skip any that don't apply.

| Check | Condition | Command |
|-------|-----------|---------|
| Build | Always | `swift build` |
| Tests | `grep -q '\.testTarget' Package.swift` | `swift test` |
| Lint | `.swiftlint.yml` exists | `swiftlint` |

Abort on the first failing check. Print the failing command and its output.

Do **not** run the full release build during checks — that happens separately
in the build step so the version is already bumped when artifacts are created.

---

## Build

After version bump, run the project's build chain.

**If a Makefile exists with a `release` target:**
```bash
grep -q '^release:' Makefile
```

If yes:
```bash
make release
```

This typically handles the full chain: build, bundle, sign, notarize, DMG.

**Otherwise:**
```bash
swift build -c release
```

If the build fails, restore the plist (if it was modified):
```bash
git checkout -- "$plist"
```
Print: "Build failed. Version bump has been reverted." Stop.

---

## Publish (GitHub Release)

Unlike npm (which publishes to a registry), Swift/macOS apps are distributed
via GitHub Releases with the built artifact attached.

**Step 1: Detect the artifact**

After the build completes, scan for distributable files:

```bash
artifact=$(ls *.dmg 2>/dev/null | head -1)
[ -z "$artifact" ] && artifact=$(ls *.zip 2>/dev/null | head -1)
[ -z "$artifact" ] && artifact=$(ls *.app 2>/dev/null | head -1)
```

If no artifact is found, warn:
"No .dmg, .zip, or .app found. The GitHub Release will be created without an
artifact. You can attach files manually later."

**Step 2: Extract changelog for release notes**

The release flow has already transformed the changelog (Step 5). Extract the
new version's section to a temp file:

```bash
sed -n "/## \[X.Y.Z\]/,/## \[/p" CHANGELOG.md | sed '$d' > /tmp/release-notes.md
```

**Step 3: Create the GitHub Release**

This runs after `git push` succeeds in Step 9. Present the release summary
and wait for confirmation (consistent with Step 8's confirmation gate):

```
Ready to create GitHub Release:
  - Tag: vX.Y.Z
  - Artifact: <artifact-name> (<size>)
  - Release notes: <first 3 lines of changelog>

Proceed? (yes/no)
```

If confirmed:
```bash
gh release create vX.Y.Z \
  --title "vX.Y.Z" \
  --notes-file /tmp/release-notes.md \
  <artifact>
```

If `gh` is not available, print the manual command and the GitHub URL instead.

If declined, print: "GitHub Release skipped. Create manually at:
https://github.com/<owner>/<repo>/releases/new?tag=vX.Y.Z"

---

## Package Contents Preview

For `/release context`, show the project structure and build targets.

**If a Makefile exists:**
```bash
echo "=== Makefile targets ==="
grep '^[a-z].*:' Makefile | sed 's/:.*//'
```

**Always show the Package.swift targets:**
```bash
echo "=== Swift Package targets ==="
swift package describe --type json 2>/dev/null | grep -o '"name" *: *"[^"]*"' || echo "(run swift package describe manually)"
```

---

## CI Template Selection

When generating CI workflows, use these templates:
- CI: [templates/ci-swift.yml](../templates/ci-swift.yml)
- Release: [templates/release-swift.yml](../templates/release-swift.yml)

Adapt the templates based on the detected macOS version and Swift version.
See [flows/setup-ci.md](../flows/setup-ci.md) for the full generation process.
