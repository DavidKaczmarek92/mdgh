#!/usr/bin/env bash
#
# update.sh — Update mdgh to the latest version from GitHub.
#
# Re-downloads the latest md-to-issues.sh from the repo's main branch
# and reinstalls it over whatever is currently on your PATH — same
# install location, no need to remember where it went.
#
# Usage:
#   ./update.sh
#
# If you're not running this from inside a clone of the repo, set
# REPO_URL below to point at the raw script on GitHub.
#
set -euo pipefail

SCRIPT_NAME="mdgh"

# Raw URL to the latest md-to-issues.sh on the main branch.
# Update <your-username> once you've pushed the repo to GitHub.
REPO_URL="https://raw.githubusercontent.com/<your-username>/md-to-gh-issues/main/md-to-issues.sh"

# ─────────────────────────────────────────────────────────────
# Find where mdgh is currently installed.
# ─────────────────────────────────────────────────────────────

current_path="$(command -v "$SCRIPT_NAME" 2>/dev/null || true)"

if [[ -z "$current_path" ]]; then
  echo "✗ $SCRIPT_NAME is not currently installed (not found on PATH)."
  echo "  Run install.sh first."
  exit 1
fi

echo "→ Found $SCRIPT_NAME at: $current_path"

# ─────────────────────────────────────────────────────────────
# Download the latest version to a temp file first, so a failed
# download never leaves you with a half-written, broken script.
# ─────────────────────────────────────────────────────────────

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

echo "→ Downloading latest version..."

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$REPO_URL" -o "$tmp_file"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$REPO_URL" -O "$tmp_file"
else
  echo "✗ Neither curl nor wget found. Install one of them first."
  exit 1
fi

if [[ ! -s "$tmp_file" ]]; then
  echo "✗ Download failed or returned an empty file."
  exit 1
fi

# Sanity check: the file should at least look like our script.
if ! grep -q "md-to-issues" "$tmp_file"; then
  echo "✗ Downloaded file doesn't look like mdgh. Aborting, nothing was changed."
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# Compare versions before overwriting — skip the no-op case.
# ─────────────────────────────────────────────────────────────

if cmp -s "$tmp_file" "$current_path"; then
  echo "✓ Already up to date."
  exit 0
fi

# ─────────────────────────────────────────────────────────────
# Install over the existing copy, using sudo only if needed —
# same logic as install.sh.
# ─────────────────────────────────────────────────────────────

install_dir="$(dirname "$current_path")"

if [[ -w "$install_dir" ]]; then
  cp "$tmp_file" "$current_path"
  chmod +x "$current_path"
else
  echo "  (needs admin password to write to $install_dir)"
  sudo cp "$tmp_file" "$current_path"
  sudo chmod +x "$current_path"
fi

echo "✓ Updated $SCRIPT_NAME at $current_path"
echo ""
"$current_path" --help | head -1