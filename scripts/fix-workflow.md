# How to Fix the Draw.io Workflow

To fix the SVG conversion issues in the workflow, follow these steps:

## 1. Replace the conversion code in `drawio-convert.yml`

Find the section that starts with:
```yaml
              # Standard conversion process for non-empty diagrams
              echo "Trying conversion method 1: convert-drawio.sh script"
              timeout 90s xvfb-run --server-args="-screen 0 1280x1024x24" /tmp/convert-drawio.sh "$file_to_process" "$output_svg" 2>/tmp/conversion_error.log
```

And replace it with:
```yaml
              # Standard conversion process with multiple fallbacks
              echo "Trying multiple conversion methods..."
              # First make the conversion script executable
              chmod +x ./scripts/fix_drawio_conversion.sh
              
              # Run our enhanced conversion script with timeout
              timeout 120s ./scripts/fix_drawio_conversion.sh "$file_to_process" "$output_svg" 2>/tmp/conversion_error.log
              
              # Check if conversion succeeded
              if [ ! -f "$output_svg" ] || [ ! -s "$output_svg" ]; then
                echo "All conversion methods failed!"
                # Create a minimal valid SVG so the workflow can continue
                echo '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="480" viewBox="0 0 640 480"><rect width="100%" height="100%" fill="#ffffcc"/><text x="10" y="20" font-family="Arial" font-size="16">Error: Failed to convert diagram</text><text x="10" y="45" font-family="Arial" font-size="12">Please check the file and try again</text></svg>' > "$output_svg"
                echo "Created placeholder SVG to allow workflow to continue"
              else
                echo "Successfully converted to SVG!"
              fi
```

## 2. Test the workflow from the command line

Before committing your changes, test the conversion script on a problematic file:

```bash
./scripts/fix_drawio_conversion.sh drawio_files/untitled12.drawio /tmp/test.svg
```

## 3. Implement the ID assignment in a separate commit

This keeps your changes manageable and easier to debug.

## 4. Keep the improved placeholder SVGs for error cases

The enhanced fallback SVGs make it clear to users when there's a conversion issue but still allow the workflow to complete successfully.
