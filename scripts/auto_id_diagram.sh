#!/bin/bash
# auto_id_diagram.sh
#
# This script automatically assigns incremental IDs to Draw.io diagrams 
# based on the existing diagrams in the repository.
#
# The naming convention is:
#   1.2.3.DiagramName
#   Where:
#   1 - Category (1=Cloud, 2=Network, 3=SAP)
#   2 - ID of the diagram (counting up)
#   3 - Detail level (1=Big landscape, 2=Solution undetailed, 3=Solution detailed)
#   DiagramName - Specification of the diagram

# Set up error handling
set -e

# Find diagrams matching the pattern and extract the highest ID value
find_highest_id() {
    local prefix="$1"  # e.g., "3.1."
    local highest_id=0
    
    # Look in the drawio_files directory
    if [ -d "drawio_files" ]; then
        for file in drawio_files/*.drawio; do
            # Skip if no files match
            [ -e "$file" ] || continue
            
            # Extract the base filename
            base_name=$(basename "$file" .drawio)
            
            # Check if the file starts with our prefix
            if [[ "$base_name" == "$prefix"* ]] || [[ "$base_name" == "${prefix%.*}"*"."* ]]; then
                # Extract the ID part and compare
                if [[ "$base_name" =~ ^${prefix%.*}\.([0-9]+)\. ]]; then
                    id_value="${BASH_REMATCH[1]}"
                    if [[ "$id_value" -gt "$highest_id" ]]; then
                        highest_id="$id_value"
                    fi
                elif [[ "$base_name" =~ ^${prefix%.*}\.([0-9]+)\. ]]; then
                    id_value="${BASH_REMATCH[1]}"
                    if [[ "$id_value" -gt "$highest_id" ]]; then
                        highest_id="$id_value"
                    fi
                fi
            fi
        done
    fi
    
    echo "$highest_id"
}

# Rename a diagram file with the next available ID
process_diagram() {
    local file_path="$1"
    
    # Extract base components
    local dir_name=$(dirname "$file_path")
    local base_name=$(basename "$file_path" .drawio)
    
    # Parse the filename and extract the prefix
    if [[ "$base_name" =~ ^([0-9]+\.[0-9]+)\. ]]; then
        local prefix="${BASH_REMATCH[1]}"
        local remainder="${base_name#${prefix}.}"
        
        # Find the highest existing ID for this prefix
        local highest_id=$(find_highest_id "$prefix")
        
        # Calculate the next ID
        local next_id=$((highest_id + 1))
        
        # Generate the new filename
        local new_name="${prefix}.${next_id}. ${remainder}"
        local new_path="$dir_name/${new_name}.drawio"
        
        # Rename the file
        echo "Renaming diagram:"
        echo "  From: $file_path"
        echo "  To:   $new_path"
        
        # Generate commit message
        local commit_message="Auto-assigned ID ${next_id} to ${base_name}"
        
        # Move the file
        git mv "$file_path" "$new_path"
        
        # Commit the change
        git add "$new_path"
        git commit -m "$commit_message"
        
        echo "Successfully renamed diagram with next available ID: $next_id"
        echo "Commit message: $commit_message"
        
        # Return the new name for use in other scripts
        echo "$new_name"
    else
        echo "Error: Filename does not match the expected pattern (e.g., '3.1. SAP Overview')"
        echo "Expected format: CategoryID.DetailLevel. DiagramName"
        echo "Example: 3.1. SAP Overview (which would become 3.1.4. SAP Overview)"
        return 1
    fi
}

# Main execution
if [ $# -ne 1 ]; then
    echo "Usage: $0 <diagram_file_path>"
    echo "Example: $0 drawio_files/3.1.\ SAP\ Overview.drawio"
    exit 1
fi

# Check if the file exists
if [ ! -f "$1" ]; then
    echo "Error: File not found: $1"
    exit 1
fi

# Process the diagram
process_diagram "$1"
