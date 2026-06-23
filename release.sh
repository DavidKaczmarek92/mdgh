#!/usr/bin/env bash
#
# release.sh — Maintainer tool to publish a new release.
#
# Automates the boring parts: checking version consistency,
# tagging, pushing, and creating a GitHub release with assets.
#
set -euo pipefail

VERSION=$(tr -d '[:space:]' < VERSION)
TAG="v$VERSION"

echo "→ Preparing release $TAG"

# 1. Check for uncommitted changes
if [[ -n "$(git status --porcelain)" ]]; then
  echo "✗ You have uncommitted changes. Please commit or stash them first."
  exit 1
fi

# 2. Verify that all scripts have the same version.
scripts=("md-to-issues.sh" "install.sh" "update.sh" "uninstall.sh")
for s in "${scripts[@]}"; do
  if ! grep -q "VERSION=\"$VERSION\"" "$s"; then
    echo "✗ Version mismatch in $s. Expected VERSION=\"$VERSION\""
    echo "  Update the VERSION variable in $s or run sync-version.sh (if you had one)."
    exit 1
  fi
done
echo "✓ Version consistency check passed."

# 3. Check for gh CLI
if ! command -v gh >/dev/null 2>&1; then
  echo "✗ gh CLI not found. Please install it to create releases."
  exit 1
fi

# 4. Create and push tag
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "⚠ Tag $TAG already exists."
else
  echo "→ Creating tag $TAG..."
  git tag "$TAG"
  echo "→ Pushing tag to origin..."
  git push origin "$TAG"
fi

# 5. Create GitHub release
echo "→ Creating GitHub release..."
gh release create "$TAG" \
  md-to-issues.sh \
  install.sh \
  update.sh \
  uninstall.sh \
  --title "Release $TAG" \
  --notes "Release $TAG"

echo ""
echo "✓ Release $TAG published successfully!"
