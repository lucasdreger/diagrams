#!/bin/bash
# debug_id_workflow.sh - Debug script to diagnose auto-ID issues
#
# This script simulates what the workflow does but in a controlled local environment
# for easier debugging

echo "==========================================="
echo "DEBUG AUTO-ID ASSIGNMENT WORKFLOW SIMULATION"
echo "==========================================="

# First, check if we're in the right directory
if [[ ! -d "drawio_files" || ! -d "html_files" ]]; then
  echo "❌ ERROR: This script must be run from the repository root"
  echo "Current directory: $(pwd)"
  echo "Expected directories drawio_files and html_files not found"
  exit 1
fi

echo "✓ Directory structure looks correct"

# Step 1: Check for existing IDs
echo "Step 1: Checking existing files for IDs..."
HIGHEST_ID=0

for existing in drawio_files/*.drawio; do
  [ -f "$existing" ] || continue
  
  existing_base=$(basename "$existing" .drawio)
  echo "  Checking: $existing_base"
  
  # Check if the filename contains "(ID XXX)" pattern
  if [[ "$existing_base" =~ \(ID\ ([0-9]+)\) ]]; then
    CURRENT_ID="${BASH_REMATCH[1]}"
    echo "  ✓ Found ID $CURRENT_ID in $existing_base"
    
    # Convert potential leading zeros
    CURRENT_ID=$((10#$CURRENT_ID))
    
    if [ "$CURRENT_ID" -gt "$HIGHEST_ID" ]; then
      HIGHEST_ID="$CURRENT_ID"
      echo "  → New highest ID: $HIGHEST_ID"
    fi
  else
    echo "  ✗ No ID found in filename"
  fi
done

echo "Highest existing ID found: $HIGHEST_ID"

# Step 2: Find files that need ID assignment
echo "Step 2: Finding files that need ID assignment..."
FILES_TO_PROCESS=()

for file in drawio_files/*.drawio; do
  [ -f "$file" ] || continue
  
  base_name=$(basename "$file" .drawio)
  echo "  Checking: $base_name"
  
  # Check if this file already has an ID assigned
  if [[ "$base_name" =~ \(ID\ ([0-9]+)\) ]]; then
    echo "  ✗ File already has ID ${BASH_REMATCH[1]}, skipping"
  else
    echo "  ✓ File needs ID assignment"
    FILES_TO_PROCESS+=("$file")
  fi
done

# Step 3: Process files that need ID assignment
echo "Step 3: Processing files that need ID assignment..."
RENAMED_FILES=0

for file in "${FILES_TO_PROCESS[@]}"; do
  base_name=$(basename "$file" .drawio)
  echo "  Processing: $base_name"
  
  # Assign the next ID
  NEXT_ID=$((HIGHEST_ID + 1))
  
  # Format the ID with leading zeros to make it 3 digits
  FORMATTED_ID=$(printf "%03d" $NEXT_ID)
  
  # Create new filename with ID
  NEW_NAME="${base_name} (ID ${FORMATTED_ID})"
  NEW_PATH="$(dirname "$file")/${NEW_NAME}.drawio"
  
  echo "  Would rename: $file → $NEW_PATH"
  
  # In a real run, we would do this:
  # mv "$file" "$NEW_PATH"
  # But for debugging, we'll just simulate it
  
  RENAMED_FILES=$((RENAMED_FILES + 1))
  HIGHEST_ID=$NEXT_ID
done

echo "Step 4: Summary"
echo "  Found $RENAMED_FILES files that need ID assignment"

# Real world workflow would commit these changes
echo "  In the actual workflow, these changes would be committed to git"

echo "==========================================="
echo "DEBUG COMPLETE"
echo "==========================================="

set -e  # Exit on error

echo "==========================================="
echo "DEBUG AUTO-ID ASSIGNMENT WORKFLOW SIMULATION"
echo "==========================================="

# First, check if we're in the right directory
if [[ ! -d "drawio_files" || ! -d "html_files" ]]; then
  echo "❌ ERROR: This script must be run from the repository root"
  echo "Current directory: $(pwd)"
  echo "Expected directories drawio_files and html_files not found"
  exit 1
fi

echo "✓ Directory structure looks correct"

# Step 1: Check for existing IDs
echo "Step 1: Checking existing files for IDs..."
HIGHEST_ID=0

for existing in drawio_files/*.drawio; do
  [ -f "$existing" ] || continue
  
  existing_base=$(basename "$existing" .drawio)
  echo "  Checking: $existing_base"
  
  # Check if the filename contains "(ID XXX)" pattern
  if [[ "$existing_base" =~ \(ID\ ([0-9]+)\) ]]; then
    CURRENT_ID="${BASH_REMATCH[1]}"
    echo "  ✓ Found ID $CURRENT_ID in $existing_base"
    
    # Convert potential leading zeros
    CURRENT_ID=$((10#$CURRENT_ID))
    
    if [ "$CURRENT_ID" -gt "$HIGHEST_ID" ]; then
      HIGHEST_ID="$CURRENT_ID"
      echo "  → New highest ID: $HIGHEST_ID"
    fi
  else
    echo "  ✗ No ID found in filename"
  fi
done

echo "Highest existing ID found: $HIGHEST_ID"

# Step 2: Find files that need ID assignment
echo "Step 2: Finding files that need ID assignment..."
FILES_TO_PROCESS=()

for file in drawio_files/*.drawio; do
  [ -f "$file" ] || continue
  
  base_name=$(basename "$file" .drawio)
  echo "  Checking: $base_name"
  
  # Check if this file already has an ID assigned
  if [[ "$base_name" =~ \(ID\ ([0-9]+)\) ]]; then
    echo "  ✗ File already has ID ${BASH_REMATCH[1]}, skipping"
  else
    echo "  ✓ File needs ID assignment"
    FILES_TO_PROCESS+=("$file")
  fi
done

# Step 3: Process files that need ID assignment
echo "Step 3: Processing files that need ID assignment..."
RENAMED_FILES=0

for file in "${FILES_TO_PROCESS[@]}"; do
  base_name=$(basename "$file" .drawio)
  echo "  Processing: $base_name"
  
  # Assign the next ID
  NEXT_ID=$((HIGHEST_ID + 1))
  
  # Format the ID with leading zeros to make it 3 digits
  FORMATTED_ID=$(printf "%03d" $NEXT_ID)
  
  # Create new filename with ID
  NEW_NAME="${base_name} (ID ${FORMATTED_ID})"
  NEW_PATH="$(dirname "$file")/${NEW_NAME}.drawio"
  
  echo "  Would rename: $file → $NEW_PATH"
  
  # In a real run, we would do this:
  # mv "$file" "$NEW_PATH"
  # But for debugging, we'll just simulate it
  
  RENAMED_FILES=$((RENAMED_FILES + 1))
  HIGHEST_ID=$NEXT_ID
done

echo "Step 4: Summary"
echo "  Found $RENAMED_FILES files that need ID assignment"

# Real world workflow would commit these changes
echo "  In the actual workflow, these changes would be committed to git"

echo "==========================================="
echo "DEBUG COMPLETE"
echo "==========================================="
