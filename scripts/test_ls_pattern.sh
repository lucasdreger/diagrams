#!/bin/bash
# test_ls_pattern.sh
#
# This script tests the ls command with escaped parentheses

# Create a temporary test directory
TEST_DIR="/tmp/ls_test_$(date +%s)"
echo "Creating test directory: $TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Create files with different names
echo "test" > "file.txt"
echo "test" > "file (ID 001).txt"

# Test the ls command with escaped parentheses
echo "Testing ls command with escaped parentheses:"
echo 'Command: ls "${file%.*} \(ID "*"'

file="file.txt"
if ls "${file%.*} \(ID "*" 2>/dev/null; then
    echo "Found files matching pattern!"
else
    echo "No files found matching pattern"
fi

# Show what files exist
echo "Files in the directory:"
ls -la

# Cleanup
cd - > /dev/null
echo "Test completed. Test directory: $TEST_DIR"
echo "To clean up: rm -rf $TEST_DIR"
