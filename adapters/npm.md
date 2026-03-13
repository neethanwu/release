# npm Adapter

Covers npm, pnpm, yarn, and bun projects. Detected when `package.json` exists
with a `version` field.

---

## Read Version

Read the `version` field from `package.json`. Parse it as JSON — do not use regex.

```bash
node -p "require('./package.json').version"
```

### Version Mismatch Check

Compare the manifest version against the latest git tag:

```bash
latest_tag=$(git describe --tags --abbrev=0 --match "v*" 2>/dev/null)
```

If the tag version and manifest version differ, warn:
"Version mismatch: package.json says X.Y.Z but latest tag is vA.B.C. Using package.json as the source of truth for bumping."

---

## Bump Version

Bump the version in `package.json` without creating a git commit or tag.

**npm or bun:**
```bash
npm version <patch|minor|major> --no-git-tag-version
```

**pnpm:**
```bash
pnpm version <patch|minor|major> --no-git-tag-version
```

**yarn:**
Yarn classic does not support `--no-git-tag-version` reliably. Edit `package.json`
directly — read the file, increment the version string, write it back.

After bumping, read the new version to confirm:
```bash
node -p "require('./package.json').version"
```

Print: "Version bumped: X.Y.Z → A.B.C"

---

## Pre-Release Version

For `/release alpha`, `/release beta`, or `/release rc`:

1. Read the current version from `package.json`
2. Determine the base version:
   - If current version is already a pre-release (e.g., `1.2.0-alpha.1`), use the same base (`1.2.0`)
   - If current version is stable (e.g., `1.2.0`), bump patch first to get the next base (`1.2.1`)
3. Scan existing git tags to determine the sequence number:
   ```bash
   git tag -l "v<base>-<type>.*" --sort=-v:refname | head -1
   ```
4. Extract N from the highest matching tag, increment by 1. If no tags match, N = 1.
5. Set version to `<base>-<type>.N` (e.g., `1.2.1-alpha.1`)
6. Update `package.json` directly with the computed version

---

## Run Checks

Read the `scripts` field from `package.json`. Run the following scripts **in order**,
but only if they exist. Skip any that are not defined.

| Script name | Purpose |
|------------|---------|
| `test` | Run tests |
| `lint` or `check` | Run linting (prefer `lint`, fall back to `check`) |
| `typecheck` | Run type checking |

Use the detected package manager's run command:

| Package manager | Run command |
|----------------|-------------|
| npm | `npm run <script>` |
| pnpm | `pnpm run <script>` |
| yarn | `yarn run <script>` |
| bun | `bun run <script>` |

Abort on the first failing script. Print the failing command and its output.

Do **not** run `build` during checks — that happens separately in the build step
so the version is already bumped when artifacts are created.

---

## Build

After version bump, run the `build` script if it exists in `package.json`:

```bash
<pm> run build
```

This ensures build artifacts (if any) contain the correct new version. If no
`build` script exists, skip this step.

---

## Publish Command

The publish command is used in CI workflows, not run directly by the skill.
Generate it based on the project configuration:

**Scoped packages** (name starts with `@`):
```bash
npm publish --provenance --access public
```

**Unscoped packages:**
```bash
npm publish --provenance
```

**Pre-release versions** (version contains `-`):
Append the appropriate dist-tag:

| Version contains | Flag |
|-----------------|------|
| `-alpha` | `--tag alpha` |
| `-beta` | `--tag beta` |
| `-rc` | `--tag rc` |
| Other pre-release | `--tag next` |

Example: `npm publish --provenance --tag alpha`

---

## Package Contents Preview

For `/release context`, show what will be published:

```bash
npm pack --dry-run 2>&1
```

This lists all files that would be included in the package, helping catch
accidentally included files or missing files.

---

## CI Template Selection

When generating CI workflows, use these templates:
- CI: [templates/ci-npm.yml](../templates/ci-npm.yml)
- Publish: [templates/publish-npm.yml](../templates/publish-npm.yml)

Adapt the templates based on detected package manager and Node.js version.
See [flows/setup-ci.md](../flows/setup-ci.md) for the full generation process.
