# Fix for workflow file - updated conversion section

**OPTION 1: Quick fix for Line 307**

1. Replace the problematic heredoc section on line 307 with a simpler approach that uses your pre-existing script:

```yaml
                      # Method 5: Try XML extraction fallback
                      if [ ! -f "$output_svg" ] || [ ! -s "$output_svg" ]; then
                        echo "Fourth conversion method failed. Trying method 5 with XML extraction..."
                        
                        # Use our pre-created extraction script instead of creating it inline
                        cp ./scripts/extract_svg.sh /tmp/extract_svg.sh
                        chmod +x /tmp/extract_svg.sh
                        
                        # Try extraction with our script
                        /tmp/extract_svg.sh "$file_to_process" "$output_svg" 2>>/tmp/conversion_error.log
```

**OPTION 2: Comprehensive fix (Recommended)**

1. Replace the entire workflow file with our improved version in `scripts/fixed-workflow.yml` that:
   - Uses external scripts instead of inline heredocs
   - Has better error handling
   - Is more maintainable going forward

2. Create helper scripts outside the workflow:

- You've already created `/Users/lucasdreger/apps/diagrams/scripts/complete_drawio_converter.sh` 
- You've already created `/Users/lucasdreger/apps/diagrams/scripts/extract_svg.sh`

These scripts contain all the logic for converting files and providing fallbacks,
which avoids having complicated heredoc sections in the workflow file.

## How to implement this fix:

1. Open `.github/workflows/drawio-convert.yml` in a text editor
2. Find the section where the conversion methods are defined (around line 294)
3. Replace the entire conditional block with the simplified version above
4. Save the file and commit the changes

The complete_drawio_converter.sh script you've already created handles:
- Multiple conversion methods with fallbacks
- Error handling and logging
- Creating a fallback SVG if no method succeeded

This approach avoids complex YAML heredoc structures that cause parsing errors.
