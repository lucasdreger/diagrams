# Draw.io-CLI Compatibility Fix

## Problem Description

The GitHub Actions workflow was encountering an error when trying to install the `draw.io-cli` package:

```
npm ERR! code E404
npm ERR! 404 Not Found - GET https://registry.npmjs.org/draw.io-cli - Not found
npm ERR! 404 
npm ERR! 404  'draw.io-cli@*' is not in this registry.
```

This error occurred because the `draw.io-cli` package is no longer available in the npm registry. The package has been superseded by `draw.io-export`, which provides similar functionality with a slightly different command interface.

## The Fix

The workflow files have been updated to use the `draw.io-export` package instead:

1. Changed package installation from `draw.io-cli` to `draw.io-export`
2. Updated command usage from `draw.io-cli --export` to `drawio --export`
3. Made the verification command more robust with a fallback message

Example changes:

```bash
# Before
npm install -g draw.io-cli
draw.io-cli --export --format svg --output "$output_svg" "$file_to_process"

# After
npm install -g draw.io-export
drawio --export --format svg --output "$output_svg" "$file_to_process"
```

## Files Modified

The fix was applied to the following files:

1. `.github/workflows/drawio-convert.yml`
2. `.github/workflows/simple-drawio-workflow.yml`

## Benefits

This fix ensures that the diagrams conversion workflow continues to function correctly by:

1. Using an actively maintained package that's available in the npm registry
2. Maintaining backward compatibility with our existing workflow functionality
3. Ensuring both SVG and HTML conversions use the same underlying tool

## Future Considerations

As dependencies continue to evolve:

1. Periodically check for updates to the `draw.io-export` package
2. Consider adding more comprehensive error handling and fallback mechanisms
3. Set specific version requirements to avoid breaking changes if the API changes
