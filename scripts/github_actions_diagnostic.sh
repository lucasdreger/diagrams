#!/bin/bash
# github_actions_diagnostic.sh - Diagnose issues with GitHub Actions workflows
#
# This script collects system information, checks for common issues,
# and provides recommendations for fixing GitHub Actions workflow problems.

echo "====================== GITHUB ACTIONS DIAGNOSTIC ======================"
echo "Date: $(date)"
echo "Hostname: $(hostname)"

# System information
echo "------------------------"
echo "SYSTEM INFORMATION"
echo "------------------------"
echo "OS: $(uname -a)"
cat /etc/os-release 2>/dev/null || echo "OS release information not available"
echo "CPU: $(cat /proc/cpuinfo | grep "model name" | head -n1 | cut -d':' -f2 | xargs) ($(nproc) cores)"
echo "Memory: $(free -h | grep Mem: | awk '{print $2}')"
echo "Disk space: $(df -h / | grep / | awk '{print $4}') available"

# GitHub specific information
echo "------------------------"
echo "GITHUB ENVIRONMENT"
echo "------------------------"
echo "GITHUB_WORKFLOW: $GITHUB_WORKFLOW"
echo "GITHUB_RUN_ID: $GITHUB_RUN_ID"
echo "GITHUB_REF: $GITHUB_REF"
echo "GITHUB_SHA: $GITHUB_SHA"
echo "GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
echo "GITHUB_ACTOR: $GITHUB_ACTOR"
echo "RUNNER_OS: $RUNNER_OS"
echo "RUNNER_NAME: $RUNNER_NAME"
echo "RUNNER_TOOL_CACHE: $RUNNER_TOOL_CACHE"

# Check for resource limits
echo "------------------------"
echo "RESOURCE LIMITS"
echo "------------------------"
echo "Process limits:"
ulimit -a
echo 
echo "Memory usage:"
free -h
echo
echo "Running processes: $(ps aux | wc -l)"
echo "Top 5 memory-consuming processes:"
ps aux --sort=-%mem | head -6

# Network checks
echo "------------------------"
echo "NETWORK CHECKS"
echo "------------------------"
echo "Testing GitHub connection:"
curl -s -o /dev/null -w "Status code: %{http_code}\n" https://api.github.com/
echo "DNS resolution:"
dig github.com +short
echo "Network interfaces:"
ip addr 2>/dev/null || ifconfig

# Xvfb specific checks
echo "------------------------"
echo "XVFB CHECKS"
echo "------------------------"
echo "Xvfb installed: $(command -v Xvfb >/dev/null 2>&1 && echo "Yes" || echo "No")"
if command -v Xvfb >/dev/null 2>&1; then
  echo "Xvfb version: $(Xvfb -version 2>&1 | head -1)"
fi
echo "X11 sockets:"
ls -la /tmp/.X11-unix/ 2>/dev/null || echo "No X11 sockets found"
echo "X displays:"
ps aux | grep Xvfb | grep -v grep || echo "No Xvfb processes running"

# Drawio specific checks
echo "------------------------"
echo "DRAW.IO CHECKS"
echo "------------------------"
echo "Drawio installed: $(command -v drawio >/dev/null 2>&1 && echo "Yes" || echo "No")"
if command -v drawio >/dev/null 2>&1; then
  echo "Drawio version: $(drawio --version 2>&1 || echo "Unable to determine version")"
fi
echo "Checking required libraries:"
for lib in libgtk-3-0 libnotify4 libnss3 libxss1 libasound2 libsecret-1-0; do
  echo -n "$lib: "
  dpkg -s $lib >/dev/null 2>&1 && echo "Installed" || echo "Not installed"
done

# Dependency graph
echo "------------------------"
echo "DEPENDENCY GRAPH"
echo "------------------------"
if command -v drawio >/dev/null 2>&1; then
  echo "Dependencies for drawio binary:"
  ldd $(which drawio) 2>/dev/null || echo "Unable to get dependencies"
fi

# GitHub Actions limits
echo "------------------------"
echo "GITHUB ACTIONS LIMITS"
echo "------------------------"
echo "Note: GitHub Actions has the following limits:"
echo "- Workflow run time: max 6 hours"
echo "- Job queue time: max 24 hours"
echo "- API requests: 1000 per hour per repository"
echo "- Concurrent jobs: depends on GitHub plan"
echo "  - Free: 20 jobs"
echo "  - Pro: 40 jobs"
echo "  - Team: 60 jobs"
echo "  - Enterprise: 180 jobs"

# Recommendations
echo "------------------------"
echo "RECOMMENDATIONS"
echo "------------------------"
echo "1. If the workflow is queuing indefinitely:"
echo "   - Check GitHub status: https://www.githubstatus.com/"
echo "   - Reduce workflow complexity"
echo "   - Use specific runner version (ubuntu-22.04) instead of latest"
echo "   - Add timeouts for jobs and steps"

echo "2. If Xvfb is failing:"
echo "   - Ensure X11 dependencies are installed"
echo "   - Use 'xvfb-run' with '--auto-servernum' option"
echo "   - Try different screen configurations"

echo "3. If Draw.io conversion is failing:"
echo "   - Try extracting SVG directly from XML"
echo "   - Use shorter timeout values for conversion commands"
echo "   - Implement better failure handling"

echo "4. General improvements:"
echo "   - Split the workflow into smaller jobs"
echo "   - Cache dependencies when possible"
echo "   - Add better error reporting"

echo "====================== END OF DIAGNOSTIC ======================"
