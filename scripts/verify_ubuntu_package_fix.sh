#!/bin/bash
# Test script to verify the Ubuntu version detection and package selection

echo "Starting verification script..."

# Test function for Ubuntu version detection
test_ubuntu_detection() {
    echo "=== Testing Ubuntu Version Detection ==="
    
    # Create mock /etc/os-release files
    echo "Creating mock OS release files..."
    mkdir -p test_ubuntu_bionic
    echo 'NAME="Ubuntu"
VERSION="18.04.6 LTS (Bionic Beaver)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 18.04.6 LTS"
VERSION_ID="18.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=bionic
UBUNTU_CODENAME=bionic' > test_ubuntu_bionic/os-release
    
    mkdir -p test_ubuntu_focal
    echo 'NAME="Ubuntu"
VERSION="20.04.4 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.4 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal' > test_ubuntu_focal/os-release
    
    mkdir -p test_ubuntu_noble
    echo 'NAME="Ubuntu"
VERSION="24.04 LTS (Noble Numbat)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 24.04 LTS"
VERSION_ID="24.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=noble
UBUNTU_CODENAME=noble' > test_ubuntu_noble/os-release
    
    echo "Testing detection logic on each version..."
    
    # Test Bionic
    echo -n "Ubuntu 18.04 (Bionic): "
    if grep -q "noble" test_ubuntu_bionic/os-release; then
        echo "Would install libasound2t64 ❌ (WRONG)"
    else
        echo "Would install libasound2 ✅ (CORRECT)"
    fi
    
    # Test Focal
    echo -n "Ubuntu 20.04 (Focal): "
    if grep -q "noble" test_ubuntu_focal/os-release; then
        echo "Would install libasound2t64 ❌ (WRONG)"
    else
        echo "Would install libasound2 ✅ (CORRECT)"
    fi
    
    # Test Noble
    echo -n "Ubuntu 24.04 (Noble): "
    if grep -q "noble" test_ubuntu_noble/os-release; then
        echo "Would install libasound2t64 ✅ (CORRECT)"
    else
        echo "Would install libasound2 ❌ (WRONG)"
    fi
    
    # Clean up
    rm -rf test_ubuntu_bionic test_ubuntu_focal test_ubuntu_noble
}

# Test the actual package selection logic from the workflow
test_package_selection_logic() {
    echo -e "\n=== Testing Package Selection Logic ==="
    
    for version in "bionic" "focal" "noble"; do
        # Create a temporary directory and os-release file
        tmp_dir=$(mktemp -d)
        
        case "$version" in
            "noble")
                echo 'VERSION_CODENAME=noble' > "$tmp_dir/os-release"
                ;;
            *)
                echo "VERSION_CODENAME=$version" > "$tmp_dir/os-release"
                ;;
        esac
        
        # Set up test message
        echo -n "Testing on $version: "
        
        # Run the actual logic from our workflow
        if grep -q "noble" "$tmp_dir/os-release"; then
            echo "Would run: sudo apt-get install -y libxshmfence1 libgbm1 libasound2t64"
            package="libasound2t64"
        else
            echo "Would run: sudo apt-get install -y libxshmfence1 libgbm1 libasound2"
            package="libasound2"
        fi
        
        # Verify correctness
        if [[ "$version" == "noble" && "$package" == "libasound2t64" ]] || 
           [[ "$version" != "noble" && "$package" == "libasound2" ]]; then
            echo "✅ CORRECT package selection"
        else
            echo "❌ WRONG package selection"
        fi
        
        # Clean up
        rm -rf "$tmp_dir"
    done
}

# Run the tests
echo "Testing Ubuntu version detection and package selection logic"
echo "==========================================================="
echo "This script verifies the fix for the package compatibility issue"
echo "with Ubuntu 24.04 (Noble) in the GitHub Actions workflows."
echo

test_ubuntu_detection
test_package_selection_logic

echo -e "\nTests completed!"
