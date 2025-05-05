# Automatic Diagram ID Assignment

## Overview

The Draw.io workflow now includes automatic ID assignment for diagrams following our standard naming convention. This feature saves time and ensures consistent naming without manual ID tracking.

## Naming Convention

Our diagrams follow this structure:

```
X.Y.Z. DiagramName
```

Where:
- **X**: Category (1=Cloud, 2=Network, 3=SAP)
- **Y**: Detail level (1=Big landscape, 2=Solution undetailed, 3=Solution detailed)
- **Z**: Sequential ID number (automatically assigned)
- **DiagramName**: Descriptive name for the diagram

## How to Use It

1. Create a new Draw.io file using only the first two parts of the name:
   ```
   3.1. SAP Overview.drawio
   ```

2. Commit and push this file

3. The GitHub workflow will:
   - Detect that the diagram needs an ID
   - Find the highest existing ID for that category and detail level
   - Assign the next sequential ID
   - Rename the file (e.g., `3.1.4. SAP Overview.drawio`)
   - Commit the renamed file automatically

## Examples

- You create: `1.2. Cloud Solution.drawio`
- If IDs 1, 2, and 3 already exist for "1.2." prefix:
- System renames to: `1.2.4. Cloud Solution.drawio`

## Manual Testing

You can test this functionality locally using the provided test script:

```bash
./scripts/test_auto_id.sh
```

This will:
1. Create a test diagram with a partial name
2. Run the auto ID script to assign the next available ID
3. Show you the result

## Troubleshooting

If the auto-assignment doesn't work:

- Ensure your filename follows the exact format `X.Y. DiagramName.drawio`
- Verify that you have the necessary permissions to push to the repository
- Check the GitHub Actions logs for any errors in the ID assignment process

## Technical Details

The auto ID assignment is handled by:

1. A shell script (`auto_id_diagram.sh`) that:
   - Parses the filename to extract the category and detail level
   - Searches existing diagrams for the highest current ID
   - Calculates the next available ID
   - Renames the file and commits the change

2. GitHub Actions workflow integration that:
   - Detects files with incomplete naming patterns
   - Applies the auto ID assignment logic
   - Handles git operations automatically
