#!/usr/bin/env bash
#
# Pre-push hook: validates release tags before pushing.
# Installed by the /release skill.
#
# Checks:
# 1. Tag version matches the manifest version
# 2. CHANGELOG.md has a matching version entry (skipped for pre-releases)
#

set -euo pipefail

while read -r local_ref local_sha remote_ref remote_sha; do
  # Only check version tags (v*)
  [[ "$local_ref" != refs/tags/v* ]] && continue

  TAG_VERSION="${local_ref#refs/tags/v}"

  # --- Check 1: Manifest version matches tag ---
  PKG_VERSION=$({{VERSION_READ_CMD}})

  if [[ "$PKG_VERSION" != "$TAG_VERSION" ]]; then
    echo "ERROR: Tag version (v${TAG_VERSION}) does not match manifest version (${PKG_VERSION})."
    echo "  Update the manifest or delete the tag: git tag -d v${TAG_VERSION}"
    exit 1
  fi

  # --- Check 2: Changelog entry exists (skip for pre-releases) ---
  if [[ "$TAG_VERSION" != *"-"* ]]; then
    if ! grep -qi "^## \[${TAG_VERSION}\]" CHANGELOG.md 2>/dev/null; then
      echo "ERROR: No changelog entry found for version ${TAG_VERSION}."
      echo "  Add a '## [${TAG_VERSION}]' section to CHANGELOG.md."
      exit 1
    fi
  fi
done
