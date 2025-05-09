#!/bin/bash
#
# Test script to verify the improved modify/delete conflict resolution
#
# This script simulates the scenario where:
# 1. A file is renamed in one branch (by adding ID)
# 2. The same file is modified in another branch
# 3. The branches are merged, creating a modify/delete conflict
# 4. The improved conflict resolution strategy is applied

# Set up test environment
TEST_DIR="/tmp/diagram_conflict_test_$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Setting up test environment in: $TEST_DIR"

# Initialize Git repository
git init
git config --local user.name "Test User"
git config --local user.email "test@example.com"

# Create initial file structure
mkdir -p drawio_files svg_files html_files

# Create test diagram files
echo "<diagram id='test-diagram'>Initial content</diagram>" > drawio_files/test_diagram.drawio
echo "<svg>Initial SVG content</svg>" > svg_files/test_diagram.svg
echo "<html><body>Initial HTML content</body></html>" > html_files/test_diagram.html

# Create a changelog
echo "Date,Time,User,Diagram,Action,File,Commit Message,Version,Commit Hash,ID" > html_files/CHANGELOG.csv
echo "$(date +"%d.%m.%Y"),$(date +"%H:%M:%S"),\"Test User\",\"test_diagram\",\"New\",\"test_diagram.drawio\",\"Initial commit\",\"1.0\",\"abcd123\",\"\"" >> html_files/CHANGELOG.csv

# Initial commit
git add .
git commit -m "Initial commit with test diagram"

# Create feature branch for renaming
git checkout -b feature/rename-files

# Rename files by adding ID
mv drawio_files/test_diagram.drawio "drawio_files/test_diagram (ID 001).drawio"
mv svg_files/test_diagram.svg "svg_files/test_diagram (ID 001).svg"
mv html_files/test_diagram.html "html_files/test_diagram (ID 001).html"

# Update changelog
echo "$(date +"%d.%m.%Y"),$(date +"%H:%M:%S"),\"Test User\",\"test_diagram (ID 001)\",\"Modified (Update)\",\"test_diagram.drawio\",\"Added ID\",\"1.1\",\"efgh456\",\"001\"" >> html_files/CHANGELOG.csv

# Commit changes
git add .
git commit -m "Renamed test diagram with ID 001"

# Go back to main branch
git checkout master

# Modify original files in master branch
echo "<diagram id='test-diagram'>Modified content</diagram>" > drawio_files/test_diagram.drawio
echo "<svg>Modified SVG content</svg>" > svg_files/test_diagram.svg
echo "<html><body>Modified HTML content</body></html>" > html_files/test_diagram.html

# Update changelog on master
echo "$(date +"%d.%m.%Y"),$(date +"%H:%M:%S"),\"Test User\",\"test_diagram\",\"Modified (Update)\",\"test_diagram.drawio\",\"Modified content\",\"1.1\",\"ijkl789\",\"\"" >> html_files/CHANGELOG.csv

# Commit changes to master
git add .
git commit -m "Modified test diagram"

echo "=== Test Setup Complete ==="
echo "Main branch has modified files"
echo "Feature branch has renamed files with IDs"
echo ""
echo "=== Simulating merge conflict ==="

# Try to merge feature branch into master
if git merge feature/rename-files; then
    echo "No conflicts occurred - this is unexpected!"
else
    echo "Merge conflict occurred - this is the expected behavior"
    
    echo "=== Git Status ==="
    git status
    
    echo "=== List of unmerged files ==="
    git diff --name-only --diff-filter=U
    echo "==========================="
    
    echo "=== Testing conflict resolution ==="
    
    # Apply our improved conflict resolution
    UNMERGED_FILES=$(git diff --name-only --diff-filter=U | grep -v "html_files/CHANGELOG.csv" || echo "")
    if [ -n "$UNMERGED_FILES" ]; then
        echo "Resolving conflicts in other files..."
        echo "$UNMERGED_FILES" | while read -r file; do
            echo "Resolving conflict in: $file"
            
            # Check if the file is a modify/delete conflict
            if git status | grep -q "deleted by us:.*$file"; then
                echo "Detected modify/delete conflict for $file \(file deleted in our changes\)"
                # Check if we have a renamed version (with ID) of this file
                BASE_NAME=$(basename "$file" | sed 's/\.[^.]*$//')
                
                # Look for renamed files with ID pattern
                if find . -name "${file%.*} (ID*" 2>/dev/null | grep -q .; then
                    echo "Found renamed version with ID, accepting our deletion of the original"
                    git rm -f "$file" || true
                else
                    echo "No renamed version found, keeping the remote version"
                    git add "$file" || true
                fi
            elif git status | grep -q "deleted by them:.*$file"; then
                echo "Detected modify/delete conflict for $file \(file deleted in their changes\)"
                # We modified it but they deleted it - keep our version
                git add "$file"
            else
                # For standard conflicts, prefer our changes
                git checkout --ours "$file" || true
                git add "$file" || true
            fi
        done
        echo "Other conflicts resolved"
    fi
    
    # Handle CHANGELOG.csv specially
    if git status | grep -q "CHANGELOG.csv"; then
        echo "Resolving CHANGELOG.csv conflict..."
        
        # Extract header and sort entries excluding conflict markers
        HEADER=$(grep -m 1 "^Date,Time" html_files/CHANGELOG.csv || 
                echo "Date,Time,User,Diagram,Action,File,Commit Message,Version,Commit Hash,ID")
        
        # Save header as first line
        echo "$HEADER" > html_files/CHANGELOG.csv.resolved
        
        # Extract all entries that are not conflict markers and not the header
        grep -v "^<<<<" html_files/CHANGELOG.csv | grep -v "^====" | grep -v "^>>>>" | grep -v "^Date,Time" | sort | uniq >> html_files/CHANGELOG.csv.resolved
        
        # Replace conflicted file with resolved version
        cp html_files/CHANGELOG.csv.resolved html_files/CHANGELOG.csv
        git add html_files/CHANGELOG.csv
    fi
    
    # Finish the merge
    git commit -m "Merge with conflict resolution"
    
    echo "=== Verifying results ==="
    echo "Files in drawio_files directory:"
    ls -la drawio_files/
    
    echo "Files in svg_files directory:"
    ls -la svg_files/
    
    echo "Files in html_files directory:"
    ls -la html_files/
    
    echo "=== Test Results ==="
    if [ -f "drawio_files/test_diagram (ID 001).drawio" ] && [ ! -f "drawio_files/test_diagram.drawio" ]; then
        echo "✅ SUCCESS: Original drawio file was properly removed and only the ID version exists"
    else
        echo "❌ FAILURE: Both drawio files exist or ID version is missing"
    fi
    
    if [ -f "svg_files/test_diagram (ID 001).svg" ] && [ ! -f "svg_files/test_diagram.svg" ]; then
        echo "✅ SUCCESS: Original SVG file was properly removed and only the ID version exists"
    else
        echo "❌ FAILURE: Both SVG files exist or ID version is missing"
    fi
    
    if [ -f "html_files/test_diagram (ID 001).html" ] && [ ! -f "html_files/test_diagram.html" ]; then
        echo "✅ SUCCESS: Original HTML file was properly removed and only the ID version exists"
    else
        echo "❌ FAILURE: Both HTML files exist or ID version is missing"
    fi
fi

echo "=== Test complete ==="
echo "You can examine the results in: $TEST_DIR"
echo "When finished, you can remove the test directory with: rm -rf $TEST_DIR"
