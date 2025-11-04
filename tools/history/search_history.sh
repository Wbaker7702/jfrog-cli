#!/bin/bash
# JFrog CLI History Search Tool
# Search and filter command history

set -e

HISTORY_FILE="${JFROG_CLI_HISTORY_FILE:-$HOME/.jfrog/command-history.json}"

if [ ! -f "$HISTORY_FILE" ]; then
    echo "Error: History file not found at $HISTORY_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required. Install it first:"
    echo "  macOS: brew install jq"
    echo "  Linux: apt-get install jq or yum install jq"
    exit 1
fi

SEARCH_TERM="${1:-}"
SUCCESS_ONLY="${2:-}"
SHOW_COUNT="${3:-20}"

if [ -z "$SEARCH_TERM" ]; then
    echo "Usage: $0 <search_term> [success_only] [count]"
    echo ""
    echo "Search for commands in history"
    echo ""
    echo "Arguments:"
    echo "  search_term  - Text to search for in commands (required)"
    echo "  success_only - 'true' to show only successful commands (optional)"
    echo "  count        - Number of results to show (default: 20)"
    echo ""
    echo "Examples:"
    echo "  $0 upload"
    echo "  $0 'rt upload' true 10"
    echo "  $0 'build-publish' false 50"
    exit 1
fi

# Build jq filter
FILTER=".entries[] | select(.command | contains(\"$SEARCH_TERM\"))"

if [ "$SUCCESS_ONLY" = "true" ]; then
    FILTER="$FILTER | select(.success == true)"
elif [ "$SUCCESS_ONLY" = "false" ]; then
    FILTER="$FILTER | select(.success == false)"
fi

# Execute search
RESULTS=$(jq -r "[$FILTER] | sort_by(-.timestamp) | .[0:$SHOW_COUNT][] | \"\(.timestamp) [\(if .success then \"✓\" else \"✗\" end)] \(.command)\(if .execution_time_ms > 0 then \" (\(.execution_time_ms)ms)\" else \"\" end)\"" "$HISTORY_FILE")

if [ -z "$RESULTS" ]; then
    echo "No matching commands found."
    exit 0
fi

# Count total matches
TOTAL=$(jq -r "[$FILTER] | length" "$HISTORY_FILE")

echo "Found $TOTAL matching command(s)"
if [ "$TOTAL" -gt "$SHOW_COUNT" ]; then
    echo "Showing first $SHOW_COUNT results:"
fi
echo ""
echo "$RESULTS"
