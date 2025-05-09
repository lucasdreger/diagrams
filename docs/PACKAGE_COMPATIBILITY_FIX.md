# Package Compatibility Fix for Ubuntu Noble (24.04)

## Problem Description

The GitHub Actions workflows were encountering an error when running on Ubuntu Noble (24.04), which is now being used by GitHub Actions runners. The specific error was:

```
Package libasound2 is a virtual package provided by:
  liboss4-salsa-asound2 4.2-build2020-1ubuntu3  
  libasound2t64 1.2.11-1build2 (= 1.2.11-1build2)

E: Package 'libasound2' has no installation candidate
```

This error occurred because the `libasound2` package is not directly available in Ubuntu Noble repositories. The package structure has changed in this newer Ubuntu version, and the package is now named `libasound2t64`.

## The Fix

The workflows have been updated to detect the Ubuntu version and install the appropriate package:

```bash
# Handle different package names across Ubuntu versions
if grep -q "noble" /etc/os-release; then
  echo "Detected Ubuntu Noble (24.04), using libasound2t64 package"
  sudo apt-get install -y libxshmfence1 libgbm1 libasound2t64
else
  echo "Using standard audio package for earlier Ubuntu versions"
  sudo apt-get install -y libxshmfence1 libgbm1 libasound2
fi
```

This conditional approach ensures that:

1. On Ubuntu Noble (24.04), the workflow uses `libasound2t64`
2. On earlier Ubuntu versions, the workflow continues to use `libasound2`

## Files Modified

The fix was applied to the following workflow files:

1. `.github/workflows/drawio-convert.yml`
2. `.github/workflows/simple-drawio-workflow.yml`
3. `.github/workflows/simple-drawio-workflow-fixed.yml`

## Benefits

This fix ensures that the diagrams conversion workflow continues to work correctly as GitHub Actions updates their runner images to use newer Ubuntu versions. The conditional approach provides backward compatibility with workflows running on older Ubuntu versions.

## Future Considerations

As Ubuntu and GitHub Actions runners continue to evolve:

1. Periodically check for changes in package names or dependencies
2. Consider using more abstracted installation methods like `apt-get -y install --no-install-recommends libasound2 || apt-get -y install --no-install-recommends libasound2t64` as a simpler alternative
3. Consider adding more comprehensive logging to help diagnose issues more quickly
