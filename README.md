# release

A release management skill for AI coding agents. One command to bump, changelog, tag, push, and publish any package.

## How It Works

```
detect ecosystem → run checks → bump version → update changelog → commit + tag → push → watch CI
```

The agent detects your project type, runs your quality gates, bumps the version, transforms your changelog, and pushes — with a confirmation prompt before anything leaves your machine.

## Install

```bash
npx skills add https://github.com/neethanwu/release --skill release
```

After installation, `/release` is available in any repository.

## Usage

### Release a new version

```
/release patch    # 1.2.3 → 1.2.4
/release minor    # 1.2.3 → 1.3.0
/release major    # 1.2.3 → 2.0.0
```

### Pre-release

```
/release alpha    # 1.2.4-alpha.1
/release beta     # 1.2.4-beta.1
/release rc       # 1.2.4-rc.1
```

Pre-releases can be cut from any branch and don't consume changelog entries.

### Check status

```
/release context
```

Shows current version, commits since last release, changelog status, and infrastructure health.

### Simulate

```
/release dry
```

Runs the full release flow (checks, bump, changelog preview) without committing, tagging, or pushing. All changes are reverted afterward.

### Set up CI

```
/release setup-ci
```

Generates GitHub Actions workflows for CI testing and automated publishing on tag push.

## Supported Ecosystems

| Ecosystem | Status | Manifest |
|-----------|--------|----------|
| npm / Node.js / Bun | Supported | `package.json` |
| Python | Coming soon | `pyproject.toml` |
| Go | Coming soon | `go.mod` |

The npm adapter auto-detects your package manager (npm, pnpm, yarn, bun) from lock files.

## What It Handles

- **Brand-new packages** — creates CHANGELOG.md, offers CI setup, guides first release
- **Existing packages** — detects current state and picks up the workflow seamlessly
- **Pre-releases** — alpha/beta/rc with automatic sequencing and dist-tags
- **Changelogs** — [Keep a Changelog](https://keepachangelog.com/) format, human-written
- **Safety** — optional pre-push hook validates tag/version/changelog consistency
- **Rollback** — exact recovery commands for every failure scenario

## Key Design Decisions

- **Human-written changelogs.** No auto-generation from commits. The skill manages the format; you write the content.
- **Confirm before push.** Every release shows a summary and waits for your explicit approval.
- **Direct-push model.** Not PR-based. Simple and fast for single-maintainer or small-team packages.
- **No configuration files.** Detects everything from manifest files and lock files. No `.releaserc` or `release.config.js` needed.
- **Ecosystem adapters.** Adding support for a new ecosystem is one markdown file — same flow, different commands.

## License

MIT
