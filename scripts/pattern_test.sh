#!/bin/bash

# Create test files
TEST_DIR="/tmp/test_ls_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

touch "file.txt" 
touch "file (ID 001).txt"

echo "Files created:"
ls -la

FILE="file.txt"
echo "Trying pattern match for ${FILE%.*}"

# Try different methods
echo "Method 1:"
find . -name "${FILE%.*}\ \(ID*" || echo "Find failed"

echo "Method 2:"
ls -la | grep "${FILE%.*} (ID" || echo "Grep failed"

echo "Method 3:"
if [ -e "${FILE%.*} (ID 001).txt" ]; then
  echo "File exists - direct check successful"
else
  echo "Direct check failed"
fi

echo "Method 4 - standard pattern matching:"
for f in *; do
  if [[ "$f" =~ ^"${FILE%.*} (ID "[0-9]+")".*$ ]]; then
    echo "Pattern match found: $f"
  fi
done

echo "Cleanup - removing $TEST_DIR"
cd /
rm -rf "$TEST_DIR"
