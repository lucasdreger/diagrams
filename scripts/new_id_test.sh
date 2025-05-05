#!/bin/zsh
# new_id_test.sh - Test the new ID assignment logic

echo "Testing auto-ID assignment logic..."
echo "Current directory: $(pwd)"
echo "Files found:"
ls -la drawio_files/*.drawio

for file in drawio_files/*.drawio; do
  base_name=$(basename "$file" .drawio)
  echo "==================================="
  echo "Testing file: $base_name"
  
  # Extract first part (prefix) and rest (name)
  PREFIX_PART=${base_name%% *}
  NAME_PART=${base_name#* }
  
  echo "Split Parts:"
  echo "  Prefix: '$PREFIX_PART'"
  echo "  Name: '$NAME_PART'"
  
  # Check if this is a file that needs ID assignment (X.Y Name format)
  # It should have exactly one dot, two numbers, and no dot after second number
  if [[ "$PREFIX_PART" == [0-9]*.[0-9]* && "$PREFIX_PART" != *. ]]; then
    # Count dots to make sure there's exactly one
    DOT_COUNT=$(echo "$PREFIX_PART" | tr -cd '.' | wc -c)
    if [ "$DOT_COUNT" -eq 1 ]; then
      echo "✓ FILE MATCHES PATTERN - NEEDS ID ASSIGNMENT"
      
      # Simple extraction
      CATEGORY=${PREFIX_PART%%.*}
      DETAIL=${PREFIX_PART#*.}
      PREFIX="$CATEGORY.$DETAIL"
      
      echo "Extracted Components:"
      echo "  Category: '$CATEGORY'"
      echo "  Detail: '$DETAIL'"
      echo "  Prefix: '$PREFIX'"
      
      # Example next ID
      NEXT_ID=1
      NEW_NAME="${PREFIX}.${NEXT_ID}. ${NAME_PART}"
      echo "New name would be: '$NEW_NAME'"
    else
      echo "✗ More than one dot in prefix - Not a match"
    fi
  else
    echo "✗ Not a pattern that needs ID assignment"
  fi
done
