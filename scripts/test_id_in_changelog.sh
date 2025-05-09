#!/bin/bash
#
# test_id_in_changelog.sh
#
# This script tests the ID extraction and inclusion in CHANGELOG.csv entries.
# It creates a temporary test environment and verifies that:
# 1. IDs are correctly extracted from filenames with "(ID XXX)" format
# 2. IDs are properly included in the CHANGELOG.csv entries
# 3. Files are correctly identified as "New" or "Modified"
echo "Running test for ID inclusion in CHANGELOG.csv..."

# Create test directory
TEST_DIR="/tmp/diagrams_test_$(date +%s)"
mkdir -p "$TEST_DIR"
echo "Test directory: $TEST_DIR"

# Create required structure
mkdir -p "$TEST_DIR/drawio_files" "$TEST_DIR/html_files" "$TEST_DIR/svg_files"

# Create a sample drawio file (ID in filename)
TEST_FILE_NAME="Test Diagram (ID 123).drawio"
echo "<sample drawio content>" > "$TEST_DIR/drawio_files/$TEST_FILE_NAME"

# Create a sample drawio file (No ID in filename)
TEST_FILE_NO_ID="Test Diagram No ID.drawio"
echo "<sample drawio content>" > "$TEST_DIR/drawio_files/$TEST_FILE_NO_ID"

# Create CHANGELOG.csv with header
echo "Date,Time,User,Diagram,Action,File,Commit Message,Version,Commit Hash,ID" > "$TEST_DIR/html_files/CHANGELOG.csv"

# Setup Git
cd "$TEST_DIR"
git init -q
git config --local user.name "Test User"
git config --local user.email "test@example.com"
git add .
git commit -m "Initial commit" -q

# Test function to extract ID and create entry
extract_id_and_add_entry() {
  local base="$1"
  local file="$2"
  
  # Extract ID from the filename if present
  FILE_ID=""
  if [[ "$base" =~ \(ID[[:space:]]+([0-9]+)\)$ ]]; then
    FILE_ID="${BASH_REMATCH[1]}"
  fi
  
  # Determine if file is new or modified
  if git ls-files --error-unmatch "$file" &>/dev/null; then
    ACTION="Modified (Update)"
  else
    ACTION="New"
  fi
  
  # Add changelog entry
  echo "$(date +"%d.%m.%Y"),$(date +"%H:%M:%S"),\"$base\",\"$file\",\"$ACTION\",\"$file\",\"Test commit\",\"1.0\",\"abcd123\",\"$FILE_ID\"" >> "html_files/CHANGELOG.csv"
}

# Run tests
cd "$TEST_DIR"
echo -e "\nTest 1: File with ID"
extract_id_and_add_entry "Test Diagram (ID 123)" "drawio_files/Test Diagram (ID 123).drawio"

echo -e "\nTest 2: File without ID"
extract_id_and_add_entry "Test Diagram No ID" "drawio_files/Test Diagram No ID.drawio"

# Show results
echo -e "\nResults in CHANGELOG.csv:"
cat "$TEST_DIR/html_files/CHANGELOG.csv"

echo -e "\nTest complete."
