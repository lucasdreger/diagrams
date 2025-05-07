#!/bin/bash
# xvfb_environment_check.sh - Verify the environment for running Xvfb
#
# This script performs various checks to ensure the environment
# is properly set up for running Xvfb, and provides diagnostic
# information when issues are found. It also attempts to fix common issues.

set -e # Exit immediately if a command exits with a non-zero status

echo "==== XVFB ENVIRONMENT CHECK ===="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Host: $(hostname)"

# Print GitHub Actions runner information if available
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "GitHub Actions Environment:"
    echo "  Runner OS: $RUNNER_OS"
    echo "  GitHub Workflow: $GITHUB_WORKFLOW"
    echo "  GitHub Action: $GITHUB_ACTION"
    echo "  GitHub Actor: $GITHUB_ACTOR"
    echo "  GitHub Ref: $GITHUB_REF"
fi

# Print detailed system info
echo "System Information:"
uname -a
lsb_release -a 2>/dev/null || cat /etc/os-release

# Check for required packages and install missing ones
echo "Checking for required packages:"

# Function to check and install packages
check_and_install() {
    local pkg=$1
    local install_name=${2:-$1}
    echo -n "  Checking for $pkg: "
    if command -v $pkg &> /dev/null || dpkg -l | grep -q "$pkg"; then
        echo "✅ Found"
    else
        echo "❌ Not found"
        echo "  Installing $install_name..."
        sudo apt-get update && sudo apt-get install -y $install_name
    fi
}

# Check for Xvfb and related dependencies
check_and_install Xvfb xvfb
check_and_install drawio "draw.io dependencies (this may not exist as a command)"

# Check additional dependencies
echo "Checking for additional dependencies:"
packages=(
    "libnotify4"
    "libsecret-1-0"
    "libgtk-3-0"
    "libx11-xcb1"
    "libxtst6"
    "libasound2"
    "libgbm1"
    "libnspr4"
    "libnss3"
    "libxss1"
)

for pkg in "${packages[@]}"; do
    echo -n "  Checking for $pkg: "
    if dpkg -l | grep -q "$pkg"; then
        echo "✅ Found"
    else
        echo "❌ Not found"
        echo "  Installing $pkg..."
        sudo apt-get update && sudo apt-get install -y $pkg
    fi
done

# Ensure Draw.io can run
echo -n "Verifying Draw.io installation: "
if command -v drawio &> /dev/null; then
    echo "✅ Found $(drawio --version 2>&1 || echo 'version unknown')"
else
    echo "❌ Not found or not in PATH"
    echo "  Please make sure drawio is properly installed"
fi

# Check for X11 directory
echo -n "Checking X11 directories: "
if [ -d "/usr/share/X11" ]; then
    echo "✅ /usr/share/X11 exists"
else
    echo "❌ /usr/share/X11 missing"
fi

# Check for X server lock files
echo "Checking for X server lock files:"
ls -la /tmp/.X*-lock 2>/dev/null || echo "No X server lock files found"
ls -la /tmp/.X11-unix 2>/dev/null || echo "No X11 socket directory found"

# Check for running X processes
echo "Checking for running X processes:"
ps aux | grep -E '[X]org|[X]vfb' || echo "No X processes running"

# First, clean up any existing Xvfb processes
echo "Cleaning up existing Xvfb processes..."
pkill Xvfb || true
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* || true
sleep 1

# Make display directory if it doesn't exist
mkdir -p /tmp/.X11-unix || true
chmod 1777 /tmp/.X11-unix || true

# Function to test Xvfb with a specific display
test_xvfb() {
    local display=$1
    local width=$2
    local height=$3
    local depth=$4
    
    echo "Test with display :$display ($width×$height×$depth)"
    
    # Start Xvfb with specific settings
    Xvfb :$display -screen 0 ${width}x${height}x${depth} > /tmp/xvfb_$display.log 2>&1 &
    local xvfb_pid=$!
    sleep 3
    
    # Check if process is running
    if kill -0 $xvfb_pid 2>/dev/null; then
        echo "✅ Xvfb started successfully on display :$display"
        # Test if DISPLAY works by running a simple X command
        export DISPLAY=:$display
        if xdpyinfo >/dev/null 2>&1; then
            echo "✅ X display :$display is working properly"
            # Save this working display number for later use
            echo "$display" > /tmp/working_display
            kill $xvfb_pid
            return 0
        else
            echo "❌ X display :$display started but not working correctly"
            echo "   Error info:"
            xdpyinfo 2>&1 | head -5
        fi
        kill $xvfb_pid
    else
        echo "❌ Failed to start Xvfb on display :$display"
        echo "   Log contents:"
        cat /tmp/xvfb_$display.log
    fi
    return 1
}

# Test Xvfb with multiple configurations
echo "Testing if Xvfb can start with various configurations:"
SUCCESS=false

for display in 99 88 77 66 42 101 55; do
    for config in "1280 1024 24" "1024 768 16" "800 600 8"; do
        read -r width height depth <<< "$config"
        if test_xvfb $display $width $height $depth; then
            SUCCESS=true
            break 2  # Break out of both loops
        fi
    done
    # Small delay between attempts
    sleep 1
done

# Test xvfb-run separately since it uses a different approach
echo "Testing with xvfb-run:"
if xvfb-run --auto-servernum --server-args="-screen 0 1280x1024x24" xdpyinfo >/dev/null 2>&1; then
    echo "✅ xvfb-run is working correctly"
    SUCCESS=true
else
    echo "❌ xvfb-run test failed"
    echo "   Trying with different server arguments..."
    
    # Try with different screen configurations
    for config in "-screen 0 1024x768x16" "-screen 0 800x600x8"; do
        if xvfb-run --auto-servernum --server-args="$config" xdpyinfo >/dev/null 2>&1; then
            echo "✅ xvfb-run works with $config"
            SUCCESS=true
            break
        else
            echo "❌ xvfb-run failed with $config"
        fi
    done
fi

if [ "$SUCCESS" = false ]; then
    echo "⚠️ WARNING: All Xvfb tests failed. The workflow may fail!"
    echo "Attempting to fix common Xvfb issues..."
    
    # Try to fix permissions
    sudo chmod 1777 /tmp
    mkdir -p /tmp/.X11-unix
    sudo chmod 1777 /tmp/.X11-unix
    
    # Try with a completely different approach (Xvfb via display variable)
    echo "Testing emergency Xvfb approach:"
    Xvfb :22 -ac -screen 0 1024x768x16 & 
    XVFB_PID=$!
    sleep 3
    export DISPLAY=:22
    
    if xdpyinfo >/dev/null 2>&1; then
        echo "✅ Emergency Xvfb approach worked!"
        # Keep this process running
        echo "$XVFB_PID" > /tmp/xvfb_emergency_pid
        SUCCESS=true
    else
        echo "❌ Emergency Xvfb approach failed"
        kill $XVFB_PID 2>/dev/null || true
    fi
else
    echo "✅ At least one Xvfb configuration works!"
fi

# Check if drawio is installed and functional
echo -n "Checking for drawio: "
if command -v drawio &> /dev/null; then
    echo "✅ Found drawio"
    echo "drawio version info: $(drawio --version 2>&1 || echo 'Unable to get version')"
else
    echo "❌ drawio not found"
fi

# Check for memory and disk space
echo "System resources:"
echo "Memory:"
free -h || vmstat
echo "Disk space:"
df -h /

# Check network connectivity (important for downloading dependencies)
echo "Network connectivity:"
ping -c 1 8.8.8.8 || echo "Ping failed, but continuing"

# Test Draw.io with Xvfb if it's installed
echo "Testing Draw.io with Xvfb:"
if command -v drawio &> /dev/null; then
    # Use the working display if found
    if [ -f "/tmp/working_display" ]; then
        WORKING_DISPLAY=$(cat /tmp/working_display)
        echo "Using previously successful display :$WORKING_DISPLAY"
        
        # Start Xvfb with the working display
        Xvfb :$WORKING_DISPLAY -screen 0 1280x1024x24 > /tmp/drawio_test.log 2>&1 &
        XVFB_PID=$!
        sleep 2
        
        # Try to run a simple drawio command
        export DISPLAY=:$WORKING_DISPLAY
        if timeout 10s drawio --help > /tmp/drawio_output.log 2>&1; then
            echo "✅ Draw.io test passed!"
        else
            echo "❌ Draw.io test failed"
            echo "Draw.io output:"
            cat /tmp/drawio_output.log
        fi
        
        # Kill the Xvfb process
        kill $XVFB_PID 2>/dev/null || true
    else
        echo "No working display found in previous tests, skipping Draw.io test"
    fi
else
    echo "Draw.io not found, skipping test"
fi

echo "==== ENVIRONMENT CHECK COMPLETE ===="

# Provide a summary report
echo ""
echo "==== SUMMARY ===="
if [ "$SUCCESS" = true ]; then
    echo "✅ Xvfb environment is working correctly"
    echo "The workflow should be able to proceed."
else
    echo "⚠️ Xvfb environment has issues"
    echo "Recommendations:"
    echo "1. Make sure all required packages are installed"
    echo "2. Try using 'xvfb-run' with auto-servernum in your workflow"
    echo "3. Consider using a different runner OS if problems persist"
fi
echo "================="
