#!/bin/bash
set -e

echo "=== ci_post_xcodebuild.sh started ==="
echo "CI_ARCHIVE_PATH: ${CI_ARCHIVE_PATH:-not set}"
echo "CI_APP_STORE_SIGNED_APP_PATH: ${CI_APP_STORE_SIGNED_APP_PATH:-not set}"
echo "CI_XCODEBUILD_ACTION: ${CI_XCODEBUILD_ACTION:-not set}"
echo "CI_PRIMARY_REPOSITORY_PATH: ${CI_PRIMARY_REPOSITORY_PATH:-not set}"
echo "CI_PROJECT_FILE_PATH: ${CI_PROJECT_FILE_PATH:-not set}"

# Only generate TestFlight notes for archive builds that will be distributed
if [[ "$CI_XCODEBUILD_ACTION" != "archive" ]]; then
    echo "Not an archive build (CI_XCODEBUILD_ACTION=$CI_XCODEBUILD_ACTION), skipping TestFlight notes generation"
    exit 0
fi

# Repository root is where Xcode Cloud expects the TestFlight folder
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"

# Project root is where the .xcodeproj and CHANGELOG.md are located
if [[ -n "$CI_PROJECT_FILE_PATH" ]]; then
    PROJECT_ROOT=$(dirname "$CI_PROJECT_FILE_PATH")
else
    PROJECT_ROOT="$REPO_ROOT/TCZApp"
fi

echo "REPO_ROOT: $REPO_ROOT"
echo "PROJECT_ROOT: $PROJECT_ROOT"

CHANGELOG="$PROJECT_ROOT/CHANGELOG.md"
# TestFlight folder must be at repository root for Xcode Cloud to find it
OUTPUT_DIR="$REPO_ROOT/TestFlight"
# Generate for multiple locales (en-GB matches current TestFlight config, de-DE for future)
LOCALES="en-GB de-DE"

echo "Looking for changelog at: $CHANGELOG"

# Verify changelog exists
if [ ! -f "$CHANGELOG" ]; then
    echo "Error: $CHANGELOG not found"
    echo "Contents of PROJECT_ROOT:"
    ls -la "$PROJECT_ROOT/" || echo "Cannot list PROJECT_ROOT"
    exit 1
fi

# Create output directory alongside the .xcodeproj
mkdir -p "$OUTPUT_DIR"
echo "Created output directory: $OUTPUT_DIR"

# Extract latest version notes using awk:
# - Skip [Unreleased] section
# - Capture from first ## [X.Y] until next ## [
# - Clean up ### headers to plain text
TEMP_FILE="$OUTPUT_DIR/WhatToTest.tmp"
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
' "$CHANGELOG" > "$TEMP_FILE"

# Copy to all locale files
for locale in $LOCALES; do
    OUTPUT_FILE="$OUTPUT_DIR/WhatToTest.$locale.txt"
    cp "$TEMP_FILE" "$OUTPUT_FILE"
    echo "TestFlight notes written to $OUTPUT_FILE"
done
rm "$TEMP_FILE"

echo "=== Contents ==="
cat "$OUTPUT_DIR/WhatToTest.en-GB.txt"
echo "=== ci_post_xcodebuild.sh completed ==="
