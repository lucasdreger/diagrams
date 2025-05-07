#!/bin/bash
# assign_all_ids.sh - Assign IDs to all drawio files that don't have one
#
# This script will add (ID XXX) to all diagrams that don't have an ID yet

echo "==========================================="
echo "ASSIGNING IDs TO ALL DIAGRAMS"
echo "==========================================="

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
  fi
done

echo "Highest existing ID found: $HIGHEST_ID"

# Step 2: Process files without IDs
echo "Step 2: Processing files without IDs..."
RENAMED_FILES=0

for file in drawio_files/*.drawio; do
  [ -f "$file" ] || continue
  
  base_name=$(basename "$file" .drawio)
  
  # Check if this file already has an ID assigned
  if [[ "$base_name" =~ \(ID\ ([0-9]+)\) ]]; then
    echo "  • File already has ID ${BASH_REMATCH[1]}, skipping: $base_name"
    continue
  fi
  
  # Assign the next ID
  NEXT_ID=$((HIGHEST_ID + 1))
  HIGHEST_ID=$NEXT_ID
  
  # Format the ID with leading zeros to make it 3 digits
  FORMATTED_ID=$(printf "%03d" $NEXT_ID)
  
  # Create new filename with ID
  NEW_NAME="${base_name} (ID ${FORMATTED_ID})"
  NEW_PATH="$(dirname "$file")/${NEW_NAME}.drawio"
  
  echo "  • Renaming: $file → $NEW_PATH"
  
  # Perform the rename using cp+rm
  if cp -f "$file" "$NEW_PATH"; then
    if rm -f "$file"; then
      echo "    ✓ Successfully renamed"
      RENAMED_FILES=$((RENAMED_FILES + 1))
    else
      echo "    ⚠️ Copy succeeded but couldn't remove original file"
      echo "    ⚠️ You now have both $file and $NEW_PATH"
      RENAMED_FILES=$((RENAMED_FILES + 1))
    fi
  else
    echo "    ❌ Failed to rename file"
  fi
done

echo "==========================================="
echo "SUMMARY"
echo "==========================================="
echo "Assigned IDs to $RENAMED_FILES files"

if [ "$RENAMED_FILES" -gt 0 ]; then
  echo "Now you should commit these changes:"
  echo ""
  echo "git add drawio_files/*.drawio"
  echo "git commit -m \"Assign IDs to all diagram files\""
  echo "git push"
  echo ""
fi
