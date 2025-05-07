#!/bin/zsh
# simple_id_test.sh - A very simple test for the ID assignment

# Configure file to test
TEST_FILE="drawio_files/222.drawio"

echo "Testing simple ID assignment on: $TEST_FILE"

# Make sure file exists
if [ ! -f "$TEST_FILE" ]; then
    echo "Error: Test file not found"
    exit 1
fi

# Get the base name
base_name=$(basename "$TEST_FILE" .drawio)
echo "Base name: $base_name"

# Create new name with ID
NEW_NAME="${base_name} (ID 001)"
NEW_PATH="$(dirname "$TEST_FILE")/${NEW_NAME}.drawio"

echo "Would rename:"
echo "  From: $TEST_FILE"
echo "  To:   $NEW_PATH"

# Just do the rename directly for testing
cp "$TEST_FILE" "$NEW_PATH"

if [ -f "$NEW_PATH" ]; then
    echo "✅ Test file copied successfully with ID!"
    ls -la "$NEW_PATH"
else  
    echo "❌ Failed to create test file with ID"
fi
