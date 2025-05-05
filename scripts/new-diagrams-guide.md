# Handling New Empty Diagrams

## Overview

The Draw.io conversion workflow has been enhanced to properly handle new empty diagrams. This document explains how the system works with newly created Draw.io files.

## How New Diagrams Are Detected

When a Draw.io file is initially created, it typically has these characteristics:

1. Small file size (usually less than 500 bytes)
2. Contains the `<mxfile>` and `<diagram>` XML elements
3. Does not contain any `<mxCell>` elements (which would represent actual diagram content)

The workflow detects these characteristics and applies special handling for new empty diagrams.

## Special Handling for New Diagrams

When a new empty diagram is detected:

1. The workflow skips the standard conversion process (which might fail for empty diagrams)
2. Instead, it creates a placeholder SVG image with the text "New Empty Diagram"
3. This ensures the workflow continues without errors
4. A blue Teams notification is sent indicating that a new diagram was created

## Team Notifications

The workflow sends different notifications depending on whether diagrams are new or updated:

### New Diagram Notification (Blue)
- Title: "✅ New Draw.io Diagram Created"
- Lists the names of the new diagrams
- Uses a blue color theme
- Mentions the Architects team

### Updated Diagram Notification (Green)
- Title: "✅ Draw.io Diagrams Updated"
- Shows the updated diagrams
- Uses a green color theme
- Mentions the Architects team

## Best Practices

When creating new diagrams:

1. **Add Basic Content**: After creating a new file, add at least one shape or element before committing
2. **Use Descriptive Names**: Name diagrams according to your team's naming conventions
3. **Commit Separately**: Ideally commit new empty diagrams separately from updates to existing diagrams

## Troubleshooting

If you encounter issues with new diagrams:

1. Check that the file is properly saved with the `.drawio` extension
2. Verify that the file contains the basic Draw.io XML structure
3. Review the workflow logs for any specific error messages
4. Contact your workflow administrator if issues persist
