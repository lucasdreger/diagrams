#!/bin/zsh
# test_auto_id.sh - Test the auto ID assignment for diagrams
#
# This script creates a test diagram file with a partial name pattern
# and then uses the auto_id_diagram.sh script to assign an ID.

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

# Create a test diagram file (partial naming)
TEST_FILE="drawio_files/${CATEGORY}.${DETAIL}. ${NAME} ${TIMESTAMP}.drawio"

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

# Add the file to git
git add "$TEST_FILE"
echo "Added to git for tracking."

# Now run the auto ID script
echo "Running auto ID assignment script..."
./scripts/auto_id_diagram.sh "$TEST_FILE"

# Show what happened
echo ""
echo "Check the drawio_files directory to see the renamed file!"
echo "The script has committed the change for you."
