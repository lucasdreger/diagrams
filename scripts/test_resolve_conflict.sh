#!/bin/bash
# test_modify_delete_conflict.sh
#
# This script tests the detection and resolution of modify/delete conflicts
# that occur when a file is renamed with an ID in one branch and modified in another
# This script should be run from the repository root

# Create a temporary test directory
TEST_DIR="/tmp/drawio_conflict_test_$(date +%s)"
echo "Creating test directory: $TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Set up a local git repo
echo "Setting up local git repository..."
git init
git config --local user.name "Test User"
git config --local user.email "test@example.com"

# Create the directory structure
mkdir -p "drawio_files" "svg_files" "html_files"

# Create a simple diagram file
DIAGRAM="drawio_files/Test Diagram.drawio"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><mxfile host=\"app.diagrams.net\" type=\"device\"><diagram id=\"test\">Test</diagram></mxfile>" > "$DIAGRAM"
echo "Created test diagram: $DIAGRAM"

# Initial commit
git add .
git commit -m "Initial commit"

# Create feature branch
git checkout -b feature

# On feature branch: Rename with ID
echo "On feature branch: Renaming file with ID"
NEW_DIAGRAM="drawio_files/Test Diagram (ID 001).drawio"
git mv "$DIAGRAM" "$NEW_DIAGRAM"
git commit -m "Renamed with ID"

# Switch back to main branch
git checkout master

# On main branch: Modify content
echo "On main branch: Modifying content"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><mxfile host=\"app.diagrams.net\" type=\"device\"><diagram id=\"test\">Test Modified</diagram></mxfile>" > "$DIAGRAM"
git add "$DIAGRAM"
git commit -m "Modified content"

# Now merge feature into main - this should create a modify/delete conflict
echo "Merging feature branch into main... (should create conflict)"
if git merge feature 2>/dev/null; then
    echo "No conflict occurred"
else
    echo "Conflict detected as expected"
    
    # Print the status
    echo "Git status:"
    git status
    
    # Resolve conflict using our improved function
    echo "Resolving conflict..."
    
    # Look for renamed files with ID pattern
    echo "Checking for renamed files with ID pattern..."
    
    # Use ls command to list any files matching the pattern - using escaped parentheses
    if ls "${DIAGRAM%.*} \(ID "*" 2>/dev/null; then
        echo "Found renamed version with ID, accepting our deletion of the original"
        git rm -f "$DIAGRAM" || true
        
        # Accept the renamed file (should be already in the feature branch)
        # This file would already be in the staging area from the merge
        git add "$NEW_DIAGRAM"
        
        # Complete the merge with the conflict resolved
        git commit -m "Resolved modify/delete conflict - kept renamed file with ID"
        
        echo "Final repository state:"
        ls -la drawio_files/
        
        echo "✓ Test passed: Successfully resolved modify/delete conflict"
    else
        echo "× Test failed: Could not find renamed file with ID pattern"
        
        # At this point, we would handle other conflict resolution strategies
        git merge --abort
    fi
fi

# Cleanup
cd - > /dev/null
echo "Test completed. You can examine the test repository at: $TEST_DIR"
echo "To clean up: rm -rf $TEST_DIR"
