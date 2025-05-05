#!/bin/zsh
# test_auto_id.sh - Test the auto ID assignment for diagrams
#
# This script creates a test diagram file with a partial name pattern
# for testing the auto-ID functionality of the workflow.

set -e

# Set working directory to the repository root
cd "$(git rev-parse --show-toplevel)"

# Create test diagram directory if it doesn't exist
mkdir -p drawio_files

# Generate a timestamp to make the filename unique
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# You can change these test values
CATEGORY="3"  # 3 for SAP
DETAIL="1"    # 1 for big landscape diagram
NAME="SAP Overview Test"

# IMPORTANT: Use the format "X.Y Name" (without dot after Y)
# This matches the format that needs auto-ID assignment
TEST_FILE="drawio_files/${CATEGORY}.${DETAIL} ${NAME} ${TIMESTAMP}.drawio"

# Create a minimal valid Draw.io diagram file
echo '<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" modified="2025-05-05T12:00:00.000Z" agent="Mozilla/5.0" version="21.0.0" etag="abcdef" type="device">
  <diagram id="test-diagram" name="Test Diagram">
    <mxGraphModel dx="1422" dy="798" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="827" pageHeight="1169" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="2" value="Test Diagram" style="rounded=0;whiteSpace=wrap;html=1;" parent="1" vertex="1">
          <mxGeometry x="320" y="240" width="120" height="60" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>' > "$TEST_FILE"

echo "Created test diagram file: $TEST_FILE"

# Simulate what the GitHub workflow would do
echo "Manual test of auto ID assignment..."

# Extract the base filename
base_name=$(basename "$TEST_FILE" .drawio)
echo "Base name: $base_name"

# Extract category and detail
if [[ "$base_name" =~ ^([0-9]+)\.([0-9]+)\ (.*) ]]; then
  CATEGORY="${BASH_REMATCH[1]}"
  DETAIL="${BASH_REMATCH[2]}"
  PREFIX="${CATEGORY}.${DETAIL}"
  NAME="${BASH_REMATCH[3]}"
  
  echo "Matched pattern:"
  echo "  Category: $CATEGORY"
  echo "  Detail: $DETAIL" 
  echo "  Prefix: $PREFIX"
  echo "  Name: $NAME"
  
  # Find highest existing ID
  HIGHEST_ID=0
  for existing in drawio_files/*.drawio; do
    existing_base=$(basename "$existing" .drawio)
    if [[ "$existing_base" =~ ^${PREFIX}\.([0-9]+)\.\ .* ]] || [[ "$existing_base" =~ ^${PREFIX}\.([0-9]+)\ .* ]]; then
      CURRENT_ID="${BASH_REMATCH[1]}"
      echo "Found existing file with ID $CURRENT_ID: $existing_base"
      
      if [[ "$CURRENT_ID" -gt "$HIGHEST_ID" ]]; then
        HIGHEST_ID="$CURRENT_ID"
      fi
    fi
  done
  
  echo "Highest existing ID: $HIGHEST_ID"
  
  # Calculate next ID
  NEXT_ID=$((HIGHEST_ID + 1))
  echo "Next ID: $NEXT_ID"
  
  # Generate new name
  NEW_NAME="${PREFIX}.${NEXT_ID}. ${NAME}"
  NEW_PATH="drawio_files/${NEW_NAME}.drawio"
  
  echo "Renaming: $TEST_FILE -> $NEW_PATH"
  
  # Rename the file
  mv -f "$TEST_FILE" "$NEW_PATH"
  
  echo "✅ File renamed successfully to:"
  echo "$NEW_PATH"
else
  echo "❌ Error: Filename doesn't match the expected pattern"
  echo "Expected format: X.Y Name (without dot after Y)"
  echo "Example: 3.1 SAP Overview"
fi

# Show what happened
echo ""
echo "Note: This is just a manual test. In the actual workflow,"
echo "the file would be committed and pushed automatically."
