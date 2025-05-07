#!/bin/bash
# rename_test.sh - Test script for renaming files with ID
#
# This script picks a single file and attempts to add an ID to it

set -x  # Enable debug output

echo "Running rename test script with $(id -un)"
echo "Current directory: $(pwd)"
echo "File permissions:"
ls -la drawio_files/

# Select a file to rename
TEST_FILE="drawio_files/222.drawio"

if [ ! -f "$TEST_FILE" ]; then
  echo "Test file not found: $TEST_FILE"
  exit 1
fi

echo "Test file exists: $TEST_FILE"
base_name=$(basename "$TEST_FILE" .drawio)
echo "Base name: $base_name"

# Format the ID
ID="001"
echo "Using ID: $ID"

# Create new filename with ID
NEW_NAME="${base_name} (ID ${ID})"
NEW_PATH="$(dirname "$TEST_FILE")/${NEW_NAME}.drawio"
echo "New path: $NEW_PATH"

# Check file permissions
echo "File permissions for original file:"
ls -la "$TEST_FILE"
echo "Parent directory permissions:"
ls -la "$(dirname "$TEST_FILE")"

# Try to rename the file
echo "Attempting to rename..."
cp -v "$TEST_FILE" "$NEW_PATH" && echo "✅ Copy successful"
rm -v "$TEST_FILE" && echo "✅ Original file removed"

# Verify the rename
if [ -f "$NEW_PATH" ]; then
  echo "✅ Successfully renamed file"
  ls -la "$NEW_PATH"
else
  echo "❌ New file doesn't exist"
fi

if [ -f "$TEST_FILE" ]; then
  echo "❌ Original file still exists"
  ls -la "$TEST_FILE"
else
  echo "✅ Original file is gone"
fi

set +x  # Disable debug output
