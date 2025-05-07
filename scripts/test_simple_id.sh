#!/bin/zsh
# test_simple_id.sh - Test the new simple ID assignment for diagrams
#
# This script creates a test diagram file without an ID
# for testing the new ID functionality of the workflow.

set -e

# Set working directory to the repository root
cd "$(git rev-parse --show-toplevel)"

# Create test diagram directory if it doesn't exist
mkdir -p drawio_files

# Generate a timestamp to make the filename unique
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# Default test values
NAME="Simple ID Test"

# Create a test diagram file
TEST_FILE="drawio_files/${NAME} ${TIMESTAMP}.drawio"

# Create a simple diagram file
echo '<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" modified="'$(date +%Y%m%d%H%M%S)'" agent="Mozilla/5.0" version="21.1.8" type="device">
  <diagram name="Page-1" id="simple-test">
    <mxGraphModel dx="1422" dy="762" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="827" pageHeight="1169" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="2" value="Test Diagram" style="rounded=1;whiteSpace=wrap;html=1;" vertex="1" parent="1">
          <mxGeometry x="350" y="310" width="120" height="60" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>' > "$TEST_FILE"

echo "Created test diagram file: $TEST_FILE"
echo ""

# Test manual ID assignment (simulate the workflow)
echo "Running manual ID assignment test..."
./scripts/manual_auto_id.sh "$TEST_FILE"

echo ""
echo "Test completed."
echo "The workflow would do this automatically when you commit the file."
