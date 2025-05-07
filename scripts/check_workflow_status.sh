#!/bin/bash
# Workflow Status Checker Script
# This script helps diagnose issues with GitHub Actions workflows,
# particularly focusing on queued workflow runs and XKEYBOARD-related errors.

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Please install it first: https://cli.github.com/manual/installation"
    exit 1
fi

# Check if user is authenticated with gh
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}You need to authenticate with GitHub CLI first.${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Print header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}     GitHub Actions Workflow Checker    ${NC}"
echo -e "${BLUE}========================================${NC}"

# Get the repository from the current directory
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
if [ -z "$REPO" ]; then
    echo -e "${YELLOW}Not in a GitHub repository directory.${NC}"
    echo "Please enter the repository name (format: owner/repo):"
    read REPO
fi

echo -e "${GREEN}Checking workflow status for repository: ${REPO}${NC}"
echo ""

# List recent workflow runs
echo -e "${BLUE}Recent workflow runs:${NC}"
gh run list --repo "$REPO" --limit 10

# Check for queued workflows
echo ""
echo -e "${BLUE}Checking for queued workflows:${NC}"
QUEUED_RUNS=$(gh run list --repo "$REPO" --status queued --json databaseId,name,event,status,headBranch --jq '.[]')

if [ -z "$QUEUED_RUNS" ]; then
    echo -e "${GREEN}✓ No queued workflows found.${NC}"
else
    echo -e "${YELLOW}⚠ Found queued workflows:${NC}"
    gh run list --repo "$REPO" --status queued
    
    # Provide diagnosis
    echo ""
    echo -e "${YELLOW}Diagnosis for queued workflows:${NC}"
    echo "1. Workflows might be waiting for other workflows to complete"
    echo "2. Concurrency settings might be causing workflows to queue"
    echo "3. GitHub Actions might have service issues"
    
    # Offer solutions
    echo ""
    echo -e "${GREEN}Possible solutions:${NC}"
    echo "1. Update concurrency settings in workflow YAML:"
    echo "   concurrency:"
    echo "     group: \${{ github.workflow }}-\${{ github.ref }}-\${{ github.sha }}"
    echo "     cancel-in-progress: false"
    echo ""
    echo "2. Cancel queued workflow runs:"
    echo "   gh run cancel [run-id] --repo $REPO"
    echo ""
    echo "3. Check GitHub status page for service issues:"
    echo "   https://www.githubstatus.com/"
fi

# Check for failed workflows in the last week
echo ""
echo -e "${BLUE}Checking for failed workflows in the last 7 days:${NC}"
FAILED_RUNS=$(gh run list --repo "$REPO" --status failure --limit 5 --json databaseId,name,event,conclusion,headBranch,createdAt --jq '.[]')

if [ -z "$FAILED_RUNS" ]; then
    echo -e "${GREEN}✓ No failed workflows in the past 7 days.${NC}"
else
    echo -e "${YELLOW}⚠ Found failed workflows:${NC}"
    gh run list --repo "$REPO" --status failure --limit 5
    
    # Ask if user wants to see logs for a specific failed run
    echo ""
    echo "Would you like to see logs for a specific failed run? (y/n)"
    read CHECK_LOGS
    
    if [[ "$CHECK_LOGS" == "y" || "$CHECK_LOGS" == "Y" ]]; then
        echo "Enter the Run ID to check (from the first column above):"
        read RUN_ID
        
        if [ -n "$RUN_ID" ]; then
            echo -e "${BLUE}Fetching logs for run $RUN_ID...${NC}"
            # Use gh api to get job IDs for this run
            JOBS=$(gh api repos/"$REPO"/actions/runs/"$RUN_ID"/jobs --paginate)
            JOB_ID=$(echo "$JOBS" | jq -r '.jobs[0].id')
            
            if [ -n "$JOB_ID" ] && [ "$JOB_ID" != "null" ]; then
                # Search logs for XKEYBOARD errors
                echo -e "${BLUE}Searching logs for XKEYBOARD errors...${NC}"
                LOGS=$(gh run view "$RUN_ID" --repo "$REPO" --log)
                
                if echo "$LOGS" | grep -q "XKEYBOARD"; then
                    echo -e "${RED}Found XKEYBOARD errors in the logs!${NC}"
                    echo "The workflow is experiencing Xvfb keyboard mapping issues."
                    echo ""
                    echo -e "${GREEN}Recommended solution:${NC}"
                    echo "Update your Xvfb configuration in the workflow file (remove invalid -noxkbmap flag):"
                    echo "  Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp -ac +extension RANDR +render -noreset &"
                    echo "  export DISPLAY=:99"
                    echo ""
                    echo "Or use xvfb-run with standard arguments:"
                    echo "  xvfb-run --auto-servernum --server-args=\"-screen 0 1280x1024x24\" drawio -x -f svg -o ..."
                else
                    echo -e "${GREEN}No XKEYBOARD errors found in the logs.${NC}"
                fi
            else
                echo -e "${RED}Could not retrieve job information for run $RUN_ID.${NC}"
            fi
        fi
    fi
fi

# Check API rate limit
echo ""
echo -e "${BLUE}Checking GitHub API rate limits:${NC}"
RATE_LIMIT=$(gh api rate_limit)
CORE_REMAINING=$(echo "$RATE_LIMIT" | jq '.resources.core.remaining')
CORE_LIMIT=$(echo "$RATE_LIMIT" | jq '.resources.core.limit')
RESET_TIME=$(echo "$RATE_LIMIT" | jq '.resources.core.reset')
RESET_DATE=$(date -r "$RESET_TIME" 2>/dev/null || date -d "@$RESET_TIME" 2>/dev/null)

echo "API calls remaining: $CORE_REMAINING / $CORE_LIMIT"
echo "Rate limit resets at: $RESET_DATE"

if [ "$CORE_REMAINING" -lt 100 ]; then
    echo -e "${YELLOW}⚠ You're running low on API rate limit.${NC}"
fi

# Summarize
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}           Summary & Next Steps         ${NC}"
echo -e "${BLUE}========================================${NC}"

echo "1. If you have XKEYBOARD errors:"
echo "   • Update your Xvfb configuration as recommended"
echo "   • Remove any -noxkbmap flags as they are invalid"
echo ""
echo "2. If you have queued workflows:"
echo "   • Update concurrency settings to include commit SHA"
echo "   • Cancel any stuck workflow runs"
echo ""
echo "3. Check the workflow file for timeouts:"
echo "   • Consider reducing timeout-minutes from 30 to 15"
echo ""
echo "4. For Draw.io conversion issues:"
echo "   • Ensure the convert-drawio.sh script has proper error handling"
echo "   • Try different server arguments for xvfb-run"
echo ""
echo "For more help with specific errors, review the full logs with:"
echo "gh run view [run-id] --repo $REPO --log"

echo -e "${GREEN}Script completed.${NC}"
