#!/bin/zsh
# test_extract.sh - Test different extraction methods

# Test files
echo "Testing file extraction methods on actual diagram files..."

for file in drawio_files/*.drawio; do
  base_name=$(basename "$file" .drawio)
  echo "==============================================="
  echo "Processing: $base_name"
  
  # Method 1: Simple splitting by space - take first part as prefix
  PREFIX_PART=${base_name%% *}
  NAME_PART=${base_name#* }
  
  # Method 2: Extract category and detail directly
  CATEGORY=$(echo "$base_name" | grep -o "^[0-9]\+")
  DETAIL=$(echo "$base_name" | grep -o "^[0-9]\+\.\([0-9]\+\)" | grep -o "[0-9]\+$")
  
  echo "Method 1 - Simple split:"
  echo "  PREFIX_PART: '$PREFIX_PART'"
  echo "  NAME_PART: '$NAME_PART'"
  
  echo "Method 2 - Direct extraction:"
  echo "  CATEGORY: '$CATEGORY'"
  echo "  DETAIL: '$DETAIL'"
  echo "  Combined: '$CATEGORY.$DETAIL'"

  # Method 3: Only match files needing ID (X.Y Name format)
  if [[ "$base_name" =~ ^([0-9]+)\.([0-9]+)\ (.*) && ! "$base_name" =~ ^[0-9]+\.[0-9]+\. ]]; then
    echo "✓ This file needs auto-ID assignment"
    NEXT_ID=1  # Just for example
    NEW_NAME="${CATEGORY}.${DETAIL}.${NEXT_ID}. ${NAME_PART}"
    echo "  Would rename to: '$NEW_NAME'"
  else
    echo "✗ This file doesn't need auto-ID assignment"
  fi
done
