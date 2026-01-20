#!/bin/bash
set -e

# Xcode Cloud sets CI_PRIMARY_REPOSITORY_PATH to the repo root
# For local testing, default to current directory
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
cd "$REPO_ROOT"

CHANGELOG="TCZApp/CHANGELOG.md"
OUTPUT_DIR="TestFlight"
OUTPUT_FILE="$OUTPUT_DIR/WhatToTest.en-GB.txt"

# Verify changelog exists
if [ ! -f "$CHANGELOG" ]; then
    echo "Error: $CHANGELOG not found"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

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

echo "TestFlight notes written to $OUTPUT_FILE"
echo "---"
cat "$OUTPUT_FILE"
