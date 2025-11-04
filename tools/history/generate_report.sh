#!/bin/bash
# JFrog CLI History Report Generator
# Generates comprehensive usage reports

set -e

HISTORY_FILE="${JFROG_CLI_HISTORY_FILE:-$HOME/.jfrog/command-history.json}"
REPORT_FILE="${1:-jfrog_cli_report_$(date +%Y%m%d).md}"
PERIOD="${2:-all}"  # all, week, month, year

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

# Calculate date cutoff based on period
case "$PERIOD" in
    week)
        CUTOFF=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
        PERIOD_LABEL="Last 7 Days"
        ;;
    month)
        CUTOFF=$(date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
        PERIOD_LABEL="Last 30 Days"
        ;;
    year)
        CUTOFF=$(date -u -d '365 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-365d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
        PERIOD_LABEL="Last Year"
        ;;
    *)
        CUTOFF="1970-01-01T00:00:00Z"
        PERIOD_LABEL="All Time"
        ;;
esac

# Filter entries by date if needed
if [ "$PERIOD" != "all" ]; then
    FILTERED_FILE=$(mktemp)
    jq --arg cutoff "$CUTOFF" '.entries = ([.entries[] | select(.timestamp >= $cutoff)])' "$HISTORY_FILE" > "$FILTERED_FILE"
    SOURCE_FILE="$FILTERED_FILE"
else
    SOURCE_FILE="$HISTORY_FILE"
fi

# Calculate statistics
TOTAL=$(jq '.entries | length' "$SOURCE_FILE")
SUCCESS=$(jq '[.entries[] | select(.success == true)] | length' "$SOURCE_FILE")
FAILED=$(jq '[.entries[] | select(.success == false)] | length' "$SOURCE_FILE")

if [ "$TOTAL" -eq 0 ]; then
    echo "No history entries found for period: $PERIOD_LABEL"
    [ -n "$FILTERED_FILE" ] && rm -f "$FILTERED_FILE"
    exit 0
fi

SUCCESS_RATE=$(echo "scale=1; $SUCCESS * 100 / $TOTAL" | bc)
AVG_TIME=$(jq '[.entries[] | select(.execution_time_ms > 0) | .execution_time_ms] | add / length' "$SOURCE_FILE" 2>/dev/null || echo "0")
AVG_TIME_FORMATTED=$(printf "%.2f" "$AVG_TIME")

# Generate report
{
    echo "# JFrog CLI Usage Report"
    echo ""
    echo "**Period:** $PERIOD_LABEL"
    echo "**Generated:** $(date)"
    echo ""
    echo "---"
    echo ""
    echo "## Executive Summary"
    echo ""
    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Total Commands | $TOTAL |"
    echo "| Successful | $SUCCESS ($SUCCESS_RATE%) |"
    echo "| Failed | $FAILED |"
    echo "| Average Execution Time | ${AVG_TIME_FORMATTED}ms |"
    echo ""
    echo "## Top Commands"
    echo ""
    echo "### Most Used Commands"
    echo ""
    echo "| Rank | Command | Count |"
    echo "|------|---------|------|"
    jq -r '.entries | group_by(.command) | map({command: .[0].command, count: length}) | sort_by(-.count) | .[0:10] | to_entries[] | "| \(.key + 1) | `\(.value.command)` | \(.value.count) |"' "$SOURCE_FILE"
    echo ""
    echo "### Most Common Failures"
    echo ""
    echo "| Rank | Command | Failure Count |"
    echo "|------|---------|---------------|"
    jq -r '[.entries[] | select(.success == false)] | group_by(.command) | map({command: .[0].command, count: length}) | sort_by(-.count) | .[0:10] | to_entries[] | "| \(.key + 1) | `\(.value.command)` | \(.value.count) |"' "$SOURCE_FILE"
    echo ""
    echo "### Slowest Commands"
    echo ""
    echo "| Rank | Command | Execution Time |"
    echo "|------|---------|----------------|"
    jq -r '.entries | map(select(.execution_time_ms > 5000)) | sort_by(-.execution_time_ms) | .[0:10] | to_entries[] | "| \(.key + 1) | `\(.value.command)` | \(.value.execution_time_ms)ms |"' "$SOURCE_FILE"
    echo ""
    echo "## Performance Analysis"
    echo ""
    FAST=$(jq '[.entries[] | select(.execution_time_ms > 0 and .execution_time_ms < 1000)] | length' "$SOURCE_FILE" 2>/dev/null || echo "0")
    MEDIUM=$(jq '[.entries[] | select(.execution_time_ms >= 1000 and .execution_time_ms < 5000)] | length' "$SOURCE_FILE" 2>/dev/null || echo "0")
    SLOW=$(jq '[.entries[] | select(.execution_time_ms >= 5000)] | length' "$SOURCE_FILE" 2>/dev/null || echo "0")
    echo "### Execution Time Distribution"
    echo ""
    echo "| Category | Count | Percentage |"
    echo "|----------|-------|------------|"
    FAST_PCT=$(echo "scale=1; $FAST * 100 / $TOTAL" | bc)
    MEDIUM_PCT=$(echo "scale=1; $MEDIUM * 100 / $TOTAL" | bc)
    SLOW_PCT=$(echo "scale=1; $SLOW * 100 / $TOTAL" | bc)
    echo "| Fast (< 1s) | $FAST | ${FAST_PCT}% |"
    echo "| Medium (1-5s) | $MEDIUM | ${MEDIUM_PCT}% |"
    echo "| Slow (> 5s) | $SLOW | ${SLOW_PCT}% |"
    echo ""
    echo "## Recommendations"
    echo ""
    if [ "$FAILED" -gt 0 ]; then
        FAILURE_RATE=$(echo "scale=1; $FAILED * 100 / $TOTAL" | bc)
        echo "- **High Failure Rate**: ${FAILURE_RATE}% of commands failed. Review failed commands above."
    fi
    if [ "$SLOW" -gt 0 ]; then
        echo "- **Slow Commands**: $SLOW commands took > 5 seconds. Consider optimization."
    fi
    echo "- **Most Used Commands**: Focus optimization efforts on frequently used commands."
    echo ""
    echo "---"
    echo ""
    echo "*Report generated by JFrog CLI History Tools*"
} > "$REPORT_FILE"

# Cleanup
[ -n "$FILTERED_FILE" ] && rm -f "$FILTERED_FILE"

echo "Report generated: $REPORT_FILE"
