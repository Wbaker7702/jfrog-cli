#!/bin/bash
# JFrog CLI History Analyzer
# Analyzes command history and provides insights

set -e

HISTORY_FILE="${JFROG_CLI_HISTORY_FILE:-$HOME/.jfrog/command-history.json}"
OUTPUT_FORMAT="${1:-text}"  # text, json, csv

if [ ! -f "$HISTORY_FILE" ]; then
    echo "Error: History file not found at $HISTORY_FILE"
    echo "Run some JFrog CLI commands first to generate history."
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Warning: jq is not installed. Some features may be limited."
    JQ_AVAILABLE=false
else
    JQ_AVAILABLE=true
fi

analyze_text() {
    echo "JFrog CLI History Analysis"
    echo "=========================="
    echo ""
    
    if [ "$JQ_AVAILABLE" = true ]; then
        TOTAL=$(jq '.entries | length' "$HISTORY_FILE")
        SUCCESS=$(jq '[.entries[] | select(.success == true)] | length' "$HISTORY_FILE")
        FAILED=$(jq '[.entries[] | select(.success == false)] | length' "$HISTORY_FILE")
        
        if [ "$TOTAL" -eq 0 ]; then
            echo "No history entries found."
            return
        fi
        
        SUCCESS_RATE=$(echo "scale=1; $SUCCESS * 100 / $TOTAL" | bc)
        
        echo "Summary:"
        echo "  Total Commands: $TOTAL"
        echo "  Successful: $SUCCESS ($SUCCESS_RATE%)"
        echo "  Failed: $FAILED"
        echo ""
        
        # Average execution time
        AVG_TIME=$(jq '[.entries[] | select(.execution_time_ms > 0) | .execution_time_ms] | add / length' "$HISTORY_FILE" 2>/dev/null || echo "0")
        AVG_TIME_FORMATTED=$(printf "%.2f" "$AVG_TIME")
        echo "  Average Execution Time: ${AVG_TIME_FORMATTED}ms"
        echo ""
        
        # Most used commands
        echo "Top 10 Most Used Commands:"
        echo "---------------------------"
        jq -r '.entries | group_by(.command) | map({command: .[0].command, count: length}) | sort_by(-.count) | .[0:10][] | "\(.count | tostring | ljust(4)) \(.command)"' "$HISTORY_FILE" 2>/dev/null || echo "  (requires jq)"
        echo ""
        
        # Slowest commands
        echo "Slowest Commands (> 5 seconds):"
        echo "-------------------------------"
        jq -r '.entries | map(select(.execution_time_ms > 5000)) | sort_by(-.execution_time_ms) | .[0:10][] | "\(.execution_time_ms | tostring | ljust(8))ms \(.command)"' "$HISTORY_FILE" 2>/dev/null || echo "  (requires jq)"
        echo ""
        
        # Most common failures
        echo "Most Common Failed Commands:"
        echo "----------------------------"
        jq -r '[.entries[] | select(.success == false)] | group_by(.command) | map({command: .[0].command, count: length}) | sort_by(-.count) | .[0:10][] | "\(.count | tostring | ljust(4)) \(.command)"' "$HISTORY_FILE" 2>/dev/null || echo "  (requires jq)"
        echo ""
        
        # Time distribution
        echo "Command Execution Time Distribution:"
        echo "------------------------------------"
        FAST=$(jq '[.entries[] | select(.execution_time_ms > 0 and .execution_time_ms < 1000)] | length' "$HISTORY_FILE" 2>/dev/null || echo "0")
        MEDIUM=$(jq '[.entries[] | select(.execution_time_ms >= 1000 and .execution_time_ms < 5000)] | length' "$HISTORY_FILE" 2>/dev/null || echo "0")
        SLOW=$(jq '[.entries[] | select(.execution_time_ms >= 5000)] | length' "$HISTORY_FILE" 2>/dev/null || echo "0")
        echo "  Fast (< 1s):    $FAST"
        echo "  Medium (1-5s):  $MEDIUM"
        echo "  Slow (> 5s):   $SLOW"
        echo ""
        
        # Recent activity
        echo "Recent Activity (Last 24 hours):"
        echo "-------------------------------"
        RECENT=$(jq -r --arg cutoff "$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)" \
            '[.entries[] | select(.timestamp >= $cutoff)] | length' "$HISTORY_FILE" 2>/dev/null || echo "0")
        echo "  Commands in last 24h: $RECENT"
    else
        echo "Install jq for detailed analysis:"
        echo "  macOS: brew install jq"
        echo "  Linux: apt-get install jq or yum install jq"
        echo ""
        echo "Basic info:"
        TOTAL=$(grep -c '"command"' "$HISTORY_FILE" 2>/dev/null || echo "0")
        echo "  Total entries: $TOTAL"
    fi
}

analyze_json() {
    if [ "$JQ_AVAILABLE" = false ]; then
        echo "Error: jq is required for JSON output"
        exit 1
    fi
    
    jq '{
        summary: {
            total: (.entries | length),
            successful: ([.entries[] | select(.success == true)] | length),
            failed: ([.entries[] | select(.success == false)] | length),
            success_rate: (([.entries[] | select(.success == true)] | length) * 100 / (.entries | length))
        },
        top_commands: [
            .entries | group_by(.command) | map({command: .[0].command, count: length}) | sort_by(-.count) | .[0:10]
        ][0],
        slowest_commands: [
            .entries | map(select(.execution_time_ms > 5000)) | sort_by(-.execution_time_ms) | .[0:10] | map({command, execution_time_ms})
        ],
        most_failed: [
            [.entries[] | select(.success == false)] | group_by(.command) | map({command: .[0].command, count: length}) | sort_by(-.count) | .[0:10]
        ][0]
    }' "$HISTORY_FILE"
}

analyze_csv() {
    if [ "$JQ_AVAILABLE" = false ]; then
        echo "Error: jq is required for CSV output"
        exit 1
    fi
    
    echo "timestamp,command,success,execution_time_ms"
    jq -r '.entries[] | [.timestamp, .command, .success, .execution_time_ms] | @csv' "$HISTORY_FILE"
}

case "$OUTPUT_FORMAT" in
    text)
        analyze_text
        ;;
    json)
        analyze_json
        ;;
    csv)
        analyze_csv
        ;;
    *)
        echo "Usage: $0 [text|json|csv]"
        echo "  text - Human-readable analysis (default)"
        echo "  json - JSON format output"
        echo "  csv  - CSV format output"
        exit 1
        ;;
esac
