#!/bin/zsh
# manual_auto_id.sh - Manual testing of the auto ID assignment functionality
#
# This script allows you to test the auto ID assignment functionality with an existing file

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file_path>"
    echo "Example: $0 drawio_files/3.1\\ SAP\\ Overview.drawio"
    exit 1
fi

FILE_PATH="$1"

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
fi

echo "===== Processing: $FILE_PATH ====="
base_name=$(basename "$FILE_PATH" .drawio)
echo "Base name: $base_name"

# Check file patterns
echo "Testing patterns..."

if [[ "$base_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.\ .* ]]; then
    echo "Pattern match: X.Y.Z. Name (already has full ID)"
    echo "No need for auto ID assignment."
    exit 0
    
elif [[ "$base_name" =~ ^[0-9]+\.[0-9]+\.\ .* ]]; then
    echo "Pattern match: X.Y. Name (has partial ID with dot)"
    echo "This format is considered already having an ID."
    exit 0
    
elecho "Testing regex directly on '$base_name'..."
echo "Regex used: ^([0-9]+)\.([0-9]+)\ (.*)"
echo "Base name length: ${#base_name} characters"

# Convert to hex to see if there are any hidden characters
echo -n "Hex representation: "
echo -n "$base_name" | xxd -p

# For very precise pattern matching
if [[ "$base_name" =~ ^([0-9]+)\.([0-9]+)\ (.*) ]]; then
    echo "Pattern match: X.Y Name (needs ID assignment)"
    
    CATEGORY="${BASH_REMATCH[1]}"
    DETAIL="${BASH_REMATCH[2]}"
    PREFIX="${CATEGORY}.${DETAIL}"
    NAME="${BASH_REMATCH[3]}"
    
    echo "Parsed components:"
    echo "  Category: $CATEGORY"
    echo "  Detail: $DETAIL"
    echo "  Prefix: $PREFIX"
    echo "  Name: $NAME"
    
    # Debug info - show what exactly matched the regex
    echo "Raw match: '${BASH_REMATCH[0]}'"
    
    # Find highest existing ID
    echo "Looking for existing diagrams with prefix $PREFIX..."
    HIGHEST_ID=0
    
    for existing in drawio_files/*.drawio; do
        existing_base=$(basename "$existing" .drawio)
        
        if [[ "$existing_base" =~ ^${PREFIX}\.([0-9]+)\.\ .* ]] || [[ "$existing_base" =~ ^${PREFIX}\.([0-9]+)\ .* ]]; then
            CURRENT_ID="${BASH_REMATCH[1]}"
            echo "  Found: $existing_base (ID: $CURRENT_ID)"
            
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
    
    echo ""
    echo "Would rename:"
    echo "  From: $FILE_PATH"
    echo "  To:   $NEW_PATH"
    
    # Ask for confirmation
    read -p "Proceed with renaming? (y/n) " CONFIRM
    
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo "Renaming file..."
        mv -f "$FILE_PATH" "$NEW_PATH"
        echo "✅ File has been renamed successfully!"
        echo ""
        echo "Note: The file has only been renamed. If you want to commit this change,"
        echo "you need to run the following commands:"
        echo ""
        echo "git add \"$NEW_PATH\""
        echo "git rm \"$FILE_PATH\" -f"
        echo "git commit -m \"Auto-assigned ID $NEXT_ID to $(basename "$FILE_PATH")\""
        echo "git push"
    else
        echo "Operation cancelled."
    fi
else
    echo "❌ File name does not match any of the expected patterns."
    echo "Expected format: X.Y Name (e.g., '3.1 SAP Overview')"
fi
