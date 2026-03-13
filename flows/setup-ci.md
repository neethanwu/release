# Setup CI Flow

Generates GitHub Actions workflow files for CI testing and automated publishing.

---

## Step 1: Detect CI Platform

Check whether the project is hosted on GitHub:

```bash
remote_url=$(git remote get-url origin 2>/dev/null)
```

**If no remote is configured:**
The project has no remote — workflows can still be generated locally. Note this and continue.

**If the remote contains `github.com`:**
Continue to Step 2.

**If the remote does NOT contain `github.com`:**
The project is hosted on a non-GitHub platform. Use the `AskUserQuestion` tool to ask the user whether to proceed, with two options:

- **"Generate anyway"** — create GitHub Actions workflow files despite non-GitHub remote
- **"Skip"** — skip CI workflow generation for now

If the user selects **"Skip"**, stop. If **"Generate anyway"**, continue to Step 2.

---

## Step 2: Check for Existing Workflows

Scan `.github/workflows/` for existing workflow files:

```bash
ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null
```

For each file found, check if it contains a publish step:

```bash
grep -l "npm publish\|yarn publish\|pnpm publish\|bun publish" .github/workflows/*.yml 2>/dev/null
```

**If a publish workflow exists:**
Print: "Publish workflow already exists at `.github/workflows/<name>`. Skipping publish workflow generation."

**If a CI workflow exists** (contains `test` or `lint` steps but no publish):
Print: "CI workflow found at `.github/workflows/<name>`. Skipping CI workflow generation."

Only generate workflows that don't already exist.

---

## Step 3: Detect Project Configuration

Gather the information needed to fill in template placeholders:

### Node.js Version

Check in this order. Use the first match:

1. `.nvmrc` file: `cat .nvmrc 2>/dev/null`
2. `.node-version` file: `cat .node-version 2>/dev/null`
3. `engines.node` in package.json (use the minimum version from the range)
4. Default: `lts/*`

### Package Manager

Already detected in SKILL.md (from lock file). Map to workflow values:

| Package manager | Setup action | Install command | Extra setup |
|----------------|-------------|-----------------|-------------|
| npm | `actions/setup-node@v4` | `npm ci` | None |
| pnpm | `actions/setup-node@v4` | `pnpm install --frozen-lockfile` | `- uses: pnpm/action-setup@v4` |
| yarn | `actions/setup-node@v4` | `yarn install --frozen-lockfile` | None |
| bun | `oven-sh/setup-bun@v2` | `bun install --frozen-lockfile` | None |

### Publish Command

Use the adapter's `publish_cmd()` output. Adjust for scoped packages.

### Registry URL

Default: `https://registry.npmjs.org`

Check `publishConfig.registry` in package.json for custom registries.

---

## Step 4: Generate Workflows

Read the templates and replace all placeholders:

### CI Workflow

1. Read [templates/ci-npm.yml](../templates/ci-npm.yml)
2. Replace placeholders:
   - `{{NODE_VERSION}}` → detected Node.js version
   - `{{PACKAGE_MANAGER}}` → detected package manager
   - `{{SETUP_ACTION}}` → setup action from table above
   - `{{INSTALL_CMD}}` → install command from table above
   - `{{EXTRA_SETUP}}` → extra setup step, or remove the comment line if none
3. Remove any `run:` steps for scripts that don't exist in package.json
   (e.g., if there's no `lint` script, remove the lint step)

### Publish Workflow

1. Read [templates/publish-npm.yml](../templates/publish-npm.yml)
2. Replace placeholders:
   - Same as CI workflow, plus:
   - `{{PUBLISH_CMD}}` → from adapter
   - `{{REGISTRY_URL}}` → detected registry URL
3. Ensure `id-token: write` permission is set (required for `--provenance`)

---

## Step 5: Write Workflow Files

```bash
mkdir -p .github/workflows
```

Write the generated workflows. Only write files that weren't skipped in step 1.

- `.github/workflows/ci.yml`
- `.github/workflows/publish.yml`

---

## Step 6: Show Results

Print what was generated:

```
Generated CI workflows:
  .github/workflows/ci.yml      — runs tests, lint, and build on push/PR
  .github/workflows/publish.yml  — publishes to npm on v* tag push

Next steps:
  1. Review the generated files
  2. Add NPM_TOKEN to your repository secrets:
     Settings → Secrets → Actions → New repository secret
     Name: NPM_TOKEN
     Value: your npm access token (create at https://www.npmjs.com/settings/~/tokens)
  3. Commit the workflow files
  4. Push to trigger your first CI run
```

If the publish workflow uses `--provenance`, add:
"Note: The `--provenance` flag requires npm v9.5+ and `id-token: write` permission
(already configured in the workflow)."
