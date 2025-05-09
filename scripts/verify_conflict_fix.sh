#!/bin/bash
# verify_conflict_fix.sh
#
# This script tests the fix for the shell syntax error with parentheses in the conflict resolution logic
# It verifies that the find command works correctly with file paths containing parentheses

echo "Verifying the conflict resolution fix for parentheses in file paths..."

# Create a test directory
TEST_DIR="/tmp/verify_conflict_fix_$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "Failed to create and enter test directory"; exit 1; }

echo "=== Test Setup ==="
echo "Creating test files with ID pattern..."

# Create test files
mkdir -p "drawio_files" "svg_files" "html_files"
touch "drawio_files/test.drawio"
touch "drawio_files/test (ID 001).drawio"
touch "svg_files/test.svg" 
touch "svg_files/test (ID 001).svg"
touch "html_files/test.html"
touch "html_files/test (ID 001).html"

# Test the pattern matching
echo "=== Testing pattern match ==="
file="drawio_files/test.drawio"
base_file=$(basename "$file" .drawio)
base_path="${file%.*}"

echo "File: $file"
echo "Base name: $base_file" 
echo "Base path: $base_path"

# Try original approach with ls (would fail in complex cases)
echo ""
echo "TESTING ORIGINAL APPROACH:"
echo "Original command: ls \"${file%.*} (ID \"*"
# This might work in simple test cases but fails in more complex scenarios
ls "${file%.*} (ID "* 2>/dev/null || echo "Pattern failed as expected in complex scenarios"

echo ""
echo "TESTING OUR FIX:"
echo "New command: find . -name \"${file%.*} (ID*\""

# Try the fixed approach with find
if find . -name "${base_path} (ID*" 2>/dev/null | grep -q .; then
    echo "✅ SUCCESS: Found file matching pattern"
    find . -name "${base_path} (ID*" 2>/dev/null | while read -r match; do
        echo "  Found: $match"
    done
else 
    echo "❌ FAILURE: No match found for pattern"
    ls -la drawio_files/
fi

# Create a test script with the workflow pattern
echo ""
echo "=== Complete verification ==="
echo "Testing with pattern from workflow file:"

cat > test_workflow.sh << 'EOF'
#!/bin/bash
test_workflow() {
    local file="$1"
    echo "Testing conflict resolution for: $file"
    
    # This is the fixed pattern we're using in the workflow:
    if find . -name "${file%.*} (ID*" 2>/dev/null | grep -q .; then
        echo "✅ Found renamed version with ID"
        find . -name "${file%.*} (ID*" 2>/dev/null | while read -r match; do
            echo "  Found: $match"
        done
        return 0
    else
        echo "❌ No renamed version found"
        return 1
    fi
}

# Run the test
echo "Running with correct file path:"
test_workflow "drawio_files/test.drawio"
EOF

chmod +x test_workflow.sh
echo ""
echo "Running workflow test function:"
./test_workflow.sh

# Cleanup
cd - > /dev/null || true
echo ""
echo "=== Test complete ==="
echo "Test directory: $TEST_DIR"
echo "You can clean up with: rm -rf $TEST_DIR"
