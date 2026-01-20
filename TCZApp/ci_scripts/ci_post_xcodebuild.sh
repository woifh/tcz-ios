#!/bin/bash
set -e

echo "=== ci_post_xcodebuild.sh started ==="
echo "CI_ARCHIVE_PATH: ${CI_ARCHIVE_PATH:-not set}"
echo "CI_PRIMARY_REPOSITORY_PATH: ${CI_PRIMARY_REPOSITORY_PATH:-not set}"

# Only generate TestFlight notes for archive builds
if [[ -z "$CI_ARCHIVE_PATH" ]]; then
    echo "Not an archive build, skipping TestFlight notes generation"
    exit 0
fi

# Xcode Cloud sets CI_PRIMARY_REPOSITORY_PATH to the repo root
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
cd "$REPO_ROOT"

CHANGELOG="TCZApp/CHANGELOG.md"
OUTPUT_DIR="TestFlight"
OUTPUT_FILE="$OUTPUT_DIR/WhatToTest.de-DE.txt"

echo "Looking for changelog at: $REPO_ROOT/$CHANGELOG"

# Verify changelog exists
if [ ! -f "$CHANGELOG" ]; then
    echo "Error: $CHANGELOG not found"
    ls -la TCZApp/
    exit 1
fi

# Create output directory at repo root
mkdir -p "$OUTPUT_DIR"
echo "Created output directory: $REPO_ROOT/$OUTPUT_DIR"

# Extract latest version notes using awk:
# - Skip [Unreleased] section
# - Capture from first ## [X.Y] until next ## [
# - Clean up ### headers to plain text
awk '
  /^## \[Unreleased\]/ { next }
  /^## \[[0-9]/ {
    if (found) exit
    found = 1
    # Extract version number (POSIX compatible)
    version = $0
    gsub(/^## \[/, "", version)
    gsub(/\].*$/, "", version)
    print "Version " version
    print ""
    next
  }
  found && /^## \[/ { exit }
  found && /^### / {
    gsub(/^### /, "")
    print $0 ":"
    next
  }
  found && /^- / { print $0 }
  found && /^$/ { print }
' "$CHANGELOG" > "$OUTPUT_FILE"

echo "TestFlight notes written to $REPO_ROOT/$OUTPUT_FILE"
echo "=== Contents ==="
cat "$OUTPUT_FILE"
echo "=== ci_post_xcodebuild.sh completed ==="
