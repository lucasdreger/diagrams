#!/bin/zsh
# regex_test.sh - Debug regex pattern matching issues

# Test with actual files
for file in /Users/lucasdreger/apps/diagrams/drawio_files/*.drawio; do
  test_string=$(basename "$file" .drawio)
echo "Testing string: '$test_string'"
echo "String length: ${#test_string}"
echo -n "Hex representation: "
echo -n "$test_string" | xxd -p
echo ""

# Test patterns
echo "Pattern 1: ^([0-9]+)\.([0-9]+)\ (.*)"
if [[ "$test_string" =~ ^([0-9]+)\.([0-9]+)\ (.*) ]]; then
    echo "✓ MATCHES"
    echo "Full match: '${BASH_REMATCH[0]}'"
    echo "Group 1: '${BASH_REMATCH[1]}'"
    echo "Group 2: '${BASH_REMATCH[2]}'"
    echo "Group 3: '${BASH_REMATCH[3]}'"
else
    echo "✗ NO MATCH"
fi
echo ""

# Test simplified pattern - just to match numbers before and after period
echo "Pattern 2: ^([0-9]+)\.([0-9]+)"
if [[ "$test_string" =~ ^([0-9]+)\.([0-9]+) ]]; then
    echo "✓ MATCHES"
    echo "Full match: '${BASH_REMATCH[0]}'"
    echo "Group 1: '${BASH_REMATCH[1]}'"
    echo "Group 2: '${BASH_REMATCH[2]}'"
else
    echo "✗ NO MATCH"
fi
echo ""

# Test character by character
echo "Character by character analysis:"
for (( i=0; i<${#test_string}; i++ )); do
    char="${test_string:$i:1}"
    hex=$(printf '%02x' "'$char")
    echo "Position $i: '$char' (hex: $hex)"
done
echo ""

# Test with alternative syntax
echo "Testing with different regex syntax:"
echo 'Using: =~'
if [[ "$test_string" =~ ^[0-9]+\.[0-9]+\ .* ]]; then
    echo "✓ Basic pattern matches"
else
    echo "✗ Basic pattern doesn't match"
fi

echo "--------------------------------------------"
echo ""

done
